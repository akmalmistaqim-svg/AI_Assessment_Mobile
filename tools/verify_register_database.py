"""Read-only comparison of the mobile-created account across web, API, PostgreSQL."""
import json
from pathlib import Path
import httpx
from dotenv import dotenv_values
from sqlalchemy import create_engine,text
from sqlalchemy.engine import make_url
root=Path(__file__).resolve().parents[1];qa=json.loads((root/'.local/register-qa.json').read_text(encoding='utf-8'))
config=dotenv_values(r'D:\DeXa_Assessment_fik\ai-assessment-copilot\apps\frontend\.env')
db_url=config['DATABASE_URL'];db_url=db_url.replace('postgres://','postgresql://',1) if db_url.startswith('postgres://') else db_url
parsed=make_url(db_url);assert parsed.get_backend_name()=='postgresql'
engine=create_engine(db_url,echo=False)
with engine.connect() as conn:
 info=conn.execute(text('SELECT current_database() AS database, version() AS version')).mappings().one()
 rows=conn.execute(text('SELECT id, name, email, role FROM users WHERE email=:email'),{'email':qa['email']}).mappings().all();assert len(rows)==1
 row=dict(rows[0])
engine.dispose()
users={}
with httpx.Client(timeout=60) as client:
 for label,endpoint in [('mobile_wifi','http://192.168.1.66:3001/auth/login'),('backend_loopback','http://127.0.0.1:3001/auth/login'),('website','http://127.0.0.1:3000/api/auth/login')]:
  client.cookies.clear();r=client.post(endpoint,json={'email':qa['email'],'password':qa['password']});r.raise_for_status();users[label]=r.json()['user'];assert users[label]['id']==row['id'];assert users[label]['role']=='MAHASISWA'
 client.cookies.clear();r=client.post('http://192.168.1.66:3001/auth/register',json={**qa,'role':'MAHASISWA'});assert r.status_code==400
report={'database':info['database'],'engine':'PostgreSQL','serverVersion':info['version'].split(',')[0],'table':'users','account':row,'webBackendUrl':config.get('BACKEND_URL','http://127.0.0.1:3001'),'sameUserIdAcrossMobileWebDatabase':True,'logins':{k:{'id':v['id'],'role':v['role']} for k,v in users.items()},'duplicateRegistrationHttp':r.status_code,'databaseMutationsByThisVerifier':False,'scope':'Running QA backend uses the frontend DATABASE_URL explicitly. This does not claim every alternate runner/configuration uses that DB.'}
(root/'docs/evidence/register-database-parity-2026-11-04.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
