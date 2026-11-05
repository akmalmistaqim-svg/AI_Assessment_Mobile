"""Validate existing FastAPI class contracts against PostgreSQL without mutations."""
import ast
import json
import os
import secrets
import sys
from pathlib import Path

sys.dont_write_bytecode = True
root = Path(__file__).resolve().parents[1]
backend = Path(r"D:\Dexa_Assessment_Backend\DeXa_Assessment_Backend")
sys.path.insert(0, str(backend))
os.environ['INTERNAL_API_SECRET'] = secrets.token_urlsafe(48)
os.environ['PGOPTIONS'] = '-c default_transaction_read_only=on'
os.environ['NODE_ENV'] = 'production'
os.environ['STORAGE_DIR'] = str(root / 'docs/evidence/readonly-api-storage')
from fastapi.testclient import TestClient
from sqlalchemy import text
from app.main import app
from app.database import SessionLocal

module = ast.parse((backend / 'seed_e2e_fixtures.py').read_text(encoding='utf-8'))
password = next(ast.literal_eval(n.value) for n in module.body if isinstance(n, ast.Assign)
    and any(isinstance(t, ast.Name) and t.id == 'FIXTURE_PASSWORD' for t in n.targets))
with SessionLocal() as db:
    assert db.execute(text('SHOW transaction_read_only')).scalar() == 'on'
    course = db.execute(text('''SELECT c.id,c."enrollmentKey" FROM classes c
        JOIN enrollments e ON e."classId"=c.id JOIN users u ON u.id=e."mahasiswaId"
        JOIN users d ON d.id=c."dosenId" WHERE u.email='mhs_a@test.local'
        AND d.email='dosen_a@test.local' AND c.subject='RPL-2026' LIMIT 1''')).one()
    before = db.execute(text('SELECT count(*) FROM enrollments')).scalar()
    invalid = secrets.token_hex(10).upper()
    assert db.execute(text('SELECT count(*) FROM classes WHERE "enrollmentKey"=:code'), {'code': invalid}).scalar() == 0

client = TestClient(app)
auth = client.post('/auth/login', json={'email':'mhs_a@test.local', 'password':password})
assert auth.status_code == 200, f'Fixture login returned {auth.status_code}'
headers = {'Authorization': 'Bearer ' + auth.json()['access_token']}
classes = client.get('/classes', headers=headers)
assert classes.status_code == 200
assert any(c['id'] == course[0] for c in classes.json())
tasks = client.get('/classes/' + course[0] + '/assignments', headers=headers)
assert tasks.status_code == 200
wrong = client.post('/classes/join', headers=headers, json={'enrollmentKey':invalid})
assert wrong.status_code == 404
again = client.post('/classes/join', headers=headers, json={'enrollmentKey':course[1]})
assert again.status_code == 400 and 'sudah terdaftar' in again.json()['detail']
with SessionLocal() as db:
    after = db.execute(text('SELECT count(*) FROM enrollments')).scalar()
    ihsan = db.execute(text('SELECT count(*) FROM enrollments e JOIN users u ON u.id=e."mahasiswaId" WHERE u.email=:email'), {'email':'ihsan@gmail.com'}).scalar()
assert before == after
summary = {'transport':'FastAPI TestClient using actual application and read-only PostgreSQL',
    'fixture_login':'passed', 'class_list':'passed', 'task_list':'passed',
    'unknown_code_status':wrong.status_code, 'already_enrolled_status':again.status_code,
    'transaction_read_only':True, 'enrollment_counts_unchanged':before==after,
    'ihsan_enrollments':ihsan,
    'limitations':'Not an Android runtime test; no Ihsan login; no successful enrollment write attempted.'}
(root / 'docs/evidence/student-classes-backend-contract.json').write_text(json.dumps(summary, indent=2)+'\n', encoding='utf-8')
print(json.dumps(summary, indent=2))
client.close()
