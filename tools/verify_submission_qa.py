"""Read-only verification of mobile QA versions and stored PDF bytes."""
import json,hashlib
from pathlib import Path
import httpx
root=Path(__file__).resolve().parents[1]
account=json.loads((root/'.local/teskelas.json').read_text(encoding='utf-8'))
qa=json.loads((root/'.local/submission-qa.json').read_text(encoding='utf-8'))
with httpx.Client(base_url='http://127.0.0.1:3001',timeout=40) as c:
 r=c.post('/auth/login',json={'email':account['DEXA_QA_EMAIL'],'password':account['DEXA_QA_PASSWORD']});r.raise_for_status();h={'Authorization':'Bearer '+r.json()['access_token']}
 r=c.get('/auth/me',headers=h);r.raise_for_status();uid=r.json()['id']
 r=c.get(f"/classes/{qa['classId']}/assignments/{qa['assignmentId']}",headers=h);r.raise_for_status()
 subs=[s for s in r.json()['submissions'] if s['userId']==uid];assert len(subs)==1
 s=subs[0];versions=sorted(s['versions'],key=lambda v:v['versionNumber']);recent=versions[-3:]
 assert [v['type'] for v in recent]==['TEXT','DOCX','PDF']
 for v,marker in zip(recent,['TEXT','DOCX','PDF']): assert f'DEXA_MOBILE_QA_{marker}_20261101' in v['content']
 assert s['activeVersionId']==recent[-1]['id']
 r=c.get(f"/submissions/{s['id']}/file",headers=h);r.raise_for_status()
 actual=hashlib.sha256(r.content).hexdigest();expected=hashlib.sha256((root/'.local/upload-fixtures/teskelas-jawaban.pdf').read_bytes()).hexdigest();assert actual==expected
 report={'assignmentId':qa['assignmentId'],'classId':qa['classId'],'submissionId':s['id'],'student':'teskelas','submissionCount':len(subs),'versions':[{'number':v['versionNumber'],'type':v['type'],'fileName':v.get('fileName')} for v in versions],'activeType':'PDF','contentMarkersVerified':True,'downloadMatchesOriginal':True,'sha256':actual}
 (root/'docs/evidence/submission-live-result.json').write_text(json.dumps(report,indent=2),encoding='utf-8');print(json.dumps(report))
