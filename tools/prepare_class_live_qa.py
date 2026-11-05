"""Register only the authorized teskelas account; never seed/reset other accounts."""
import ast, json, secrets
from pathlib import Path
import httpx, psycopg2
from dotenv import dotenv_values
root=Path(__file__).resolve().parents[1]
config=dotenv_values(r"D:\DeXa_Assessment_fik\ai-assessment-copilot\apps\frontend\.env")
source=Path(r"D:\Dexa_Assessment_Backend\DeXa_Assessment_Backend\seed_e2e_fixtures.py")
module=ast.parse(source.read_text(encoding="utf-8"))
fixture=next(ast.literal_eval(n.value) for n in module.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=="FIXTURE_PASSWORD" for t in n.targets))
client=httpx.Client(base_url="http://127.0.0.1:3001",timeout=30)
r=client.post('/auth/login',json={"email":"dosen_a@test.local","password":fixture});r.raise_for_status()
assert r.json()['user']['role']=='DOSEN'
headers={"Authorization":"Bearer "+r.json()['access_token']}
r=client.get('/classes',headers=headers);r.raise_for_status()
courses=[c for c in r.json() if c['subject']=='RPL-2026' and not c['isArchived']]
assert len(courses)==1, 'Ambiguous class; stop'
course=courses[0]
r=client.get('/classes/'+course['id'],headers=headers);r.raise_for_status();detail=r.json()
path=root/'.local/teskelas.json'
conn=psycopg2.connect(config['DATABASE_URL']);conn.set_session(readonly=True)
with conn.cursor() as cur:
 cur.execute('SELECT id,name,email,role FROM users WHERE lower(name)=%s OR lower(email)=%s',('teskelas','teskelas@example.com'));existing=cur.fetchall()
conn.close()
if path.exists():
 data=json.loads(path.read_text())
 assert data['DEXA_QA_EMAIL']=='teskelas@example.com'
elif existing:
 raise SystemExit('Existing teskelas account without local credentials: no account changed')
else:
 data={'DEXA_QA_EMAIL':'teskelas@example.com','DEXA_QA_PASSWORD':secrets.token_urlsafe(24)}
 path.write_text(json.dumps(data,indent=2))
if not existing:
 r=client.post('/auth/register',json={'name':'teskelas','email':data['DEXA_QA_EMAIL'],'password':data['DEXA_QA_PASSWORD'],'role':'MAHASISWA'});r.raise_for_status();print('Authorized test account registered')
r=client.post('/auth/login',json={'email':data['DEXA_QA_EMAIL'],'password':data['DEXA_QA_PASSWORD']});r.raise_for_status()
user=r.json()['user'];assert user['name']=='teskelas' and user['role']=='MAHASISWA'
member=any(e['userId']==user['id'] for e in detail['enrollments'])
data.update(DEXA_QA_CLASS_ID=course['id'],DEXA_QA_CLASS_CODE=detail['enrollmentKey'],DEXA_QA_CLASS_NAME=course['name'],DEXA_API_BASE_URL='http://10.0.2.2:3001')
path.write_text(json.dumps(data,indent=2))
evidence={'account':'teskelas','accountId':user['id'],'classId':course['id'],'className':course['name'],'enrolledBefore':member,'enrollmentsBefore':len(detail['enrollments']),'tasksBefore':len(detail['assignments']),'createdVia':'FastAPI /auth/register; no seeding'}
(root/'docs/evidence/class-live-before.json').write_text(json.dumps(evidence,indent=2))
print(json.dumps(evidence))
