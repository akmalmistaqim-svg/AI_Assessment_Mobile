"""Non-destructive live rejection checks: no new tasks, grades, or users."""
import ast,json
from pathlib import Path
from datetime import datetime
import httpx
root=Path(__file__).resolve().parents[1]
qa=json.loads((root/'.local/submission-qa.json').read_text(encoding='utf-8'))
account=json.loads((root/'.local/teskelas.json').read_text(encoding='utf-8'))
module=ast.parse(Path(r'D:\Dexa_Assessment_Backend\DeXa_Assessment_Backend\seed_e2e_fixtures.py').read_text(encoding='utf-8'))
fixture_password=next(ast.literal_eval(n.value) for n in module.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='FIXTURE_PASSWORD' for t in n.targets))
c=httpx.Client(base_url='http://127.0.0.1:3001',timeout=40)
def login(email,password):
 r=c.post('/auth/login',json={'email':email,'password':password});r.raise_for_status();return {'Authorization':'Bearer '+r.json()['access_token']}
h=login(account['DEXA_QA_EMAIL'],account['DEXA_QA_PASSWORD']);teacher=login('dosen_a@test.local',fixture_password);other=login('mhs_a@test.local',fixture_password)
c.cookies.clear() # Each request must authenticate only through its explicit header.
url=f"/classes/{qa['classId']}/assignments/{qa['assignmentId']}"
def versions():
 r=c.get(url,headers=h);r.raise_for_status();return [(s['id'],s['activeVersionId'],len(s['versions'])) for s in r.json()['submissions']]
before=versions();checks=[]
def check(name,response,expected):
 checks.append({'name':name,'http':response.status_code,'expected':expected,'passed':response.status_code in expected})
def send(**kwargs):return c.post(url+'/submissions',**kwargs)
check('missing authorization',send(json={'content':'QA unauthorized request'}),[401])
check('invalid token',send(headers={'Authorization':'Bearer invalid-qa-token'},json={'content':'QA invalid token'}),[401])
check('teacher cannot submit',send(headers=teacher,json={'content':'QA wrong role'}),[403])
check('empty answer',send(headers=h,json={'content':'   '}),[400,422])
check('wrong extension',send(headers=h,files={'file':('answer.exe',b'MZ QA','application/octet-stream')}),[400])
check('fake PDF content',send(headers=h,files={'file':('answer.pdf',b'This is plain text, not a PDF','application/pdf')}),[400])
check('corrupt PDF content',send(headers=h,files={'file':('answer.pdf',b'%PDF-1.4\nbroken','application/pdf')}),[400])
check('fake DOCX content',send(headers=h,files={'file':('answer.docx',b'not a ZIP document','application/vnd.openxmlformats-officedocument.wordprocessingml.document')}),[400])
check('corrupt DOCX content',send(headers=h,files={'file':('answer.docx',b'PK\x03\x04broken','application/vnd.openxmlformats-officedocument.wordprocessingml.document')}),[400])
check('PDF over 10 MiB',send(headers=h,files={'file':('large.pdf',b'%PDF-'+b'0'*(10*1024*1024-4),'application/pdf')}),[400,413])
if before:
 check('other student cannot read submission',c.get('/submissions/'+before[0][0],headers=other),[403,404])
 check('other student cannot download file',c.get('/submissions/'+before[0][0]+'/file',headers=other),[403,404])
r=c.get(f"/classes/{qa['classId']}/assignments",headers=h);r.raise_for_status()
expired=next((a for a in r.json() if a['status']=='PUBLISHED' and not a.get('allowLateSubmission') and datetime.fromisoformat(a['dueDate'])<datetime.now()),None)
if expired:check('actual expired task',c.post(f"/classes/{qa['classId']}/assignments/{expired['id']}/submissions",headers=h,json={'content':'QA rejected overdue answer'}),[400,403])
me_other=c.get('/auth/me',headers=other);me_other.raise_for_status();other_id=me_other.json()['id']
for label,headers,expected_id in [('second account',other,other_id),('first account again',h,None)]:
 r=c.get('/auth/me',headers=headers);r.raise_for_status();uid=r.json()['id'];r=c.get(url,headers=headers);r.raise_for_status();checks.append({'name':'HTTP session isolation: '+label,'passed':all(s['userId']==uid for s in r.json()['submissions']) and (expected_id is None or uid==expected_id)})
after=versions();checks.append({'name':'rejections leave submission versions unchanged','passed':before==after})
report={'date':'2026-11-04','transport':'live FastAPI HTTP, not native Android','checks':checks,'passed':sum(x['passed'] for x in checks),'failed':sum(not x['passed'] for x in checks),'before':before,'after':after,'notCovered':['closed assignment','released grade upload policy','ASSISTANT class role','native device disconnection','Android session switching'],'dataCreated':False,'earlierTestIssue':'Initial run retained a valid fixture login cookie; see initial report and QA inventory.'}
(root/'docs/evidence/submission-negative-live-2026-11-04.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report));
r=c.get(url,headers=teacher);r.raise_for_status();inventory={'taskId':qa['assignmentId'],'classId':qa['classId'],'submissions':[{'id':s['id'],'userId':s['userId'],'versions':[{'id':v['id'],'number':v['versionNumber'],'type':v['type'],'fileUrl':v.get('fileUrl')} for v in s['versions']]} for s in r.json()['submissions']]};(root/'docs/evidence/submission-qa-inventory-2026-11-04.json').write_text(json.dumps(inventory,indent=2),encoding='utf-8')
c.close()
raise SystemExit(1 if report['failed'] else 0)
