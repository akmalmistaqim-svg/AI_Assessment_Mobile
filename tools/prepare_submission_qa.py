"""Create an explicitly labelled QA assignment; never alter existing assignments."""
import ast,json
from pathlib import Path
from datetime import datetime,timedelta
import httpx
from docx import Document
root=Path(__file__).resolve().parents[1]
private=root/'.local';fixtures=private/'upload-fixtures';fixtures.mkdir(exist_ok=True)
source=Path(r"D:\Dexa_Assessment_Backend\DeXa_Assessment_Backend\seed_e2e_fixtures.py")
module=ast.parse(source.read_text(encoding='utf-8'))
password=next(ast.literal_eval(n.value) for n in module.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='FIXTURE_PASSWORD' for t in n.targets))
student=json.loads((private/'teskelas.json').read_text())
client=httpx.Client(base_url='http://127.0.0.1:3001',timeout=40)
r=client.post('/auth/login',json={'email':'dosen_a@test.local','password':password});r.raise_for_status();headers={'Authorization':'Bearer '+r.json()['access_token']}
class_id=student['DEXA_QA_CLASS_ID'];title='[UJI MOBILE] Pengumpulan jawaban teskelas 2026-11-01'
r=client.get('/classes/'+class_id+'/assignments',headers=headers);r.raise_for_status()
existing=[a for a in r.json() if a['title']==title]
assert len(existing)<=1
if existing:assignment_id=existing[0]['id']
else:
 r=client.post('/classes/'+class_id+'/assignments',headers=headers,json={'title':title,'instructions':'Tugas khusus QA aplikasi mobile. Kiriman bertanda DEXA_MOBILE_QA digunakan untuk memverifikasi teks, PDF, DOCX, dan riwayat versi. Bukan tugas akademik mahasiswa.','submissionType':'ANY','dueDate':(datetime.now()+timedelta(days=7)).isoformat(),'allowLateSubmission':False,'maxScore':100,'status':'PUBLISHED'})
 r.raise_for_status();assignment_id=r.json()['id']
doc=Document();doc.add_heading('DEXA MOBILE QA — DOCX',0);doc.add_paragraph('DEXA_MOBILE_QA_DOCX_20261101. Jawaban teskelas untuk pengujian upload dokumen dari aplikasi mobile.');doc.save(fixtures/'teskelas-jawaban.docx')
stream=b'BT /F1 12 Tf 50 750 Td (DEXA_MOBILE_QA_PDF_20261101) Tj 0 -20 Td (Jawaban teskelas untuk uji upload mobile.) Tj ET'
objects=[b'<< /Type /Catalog /Pages 2 0 R >>',b'<< /Type /Pages /Kids [3 0 R] /Count 1 >>',b'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',b'<< /Length '+str(len(stream)).encode()+b' >>\nstream\n'+stream+b'\nendstream']
pdf=bytearray(b'%PDF-1.4\n');offsets=[0]
for i,o in enumerate(objects,1):offsets.append(len(pdf));pdf+=f'{i} 0 obj\n'.encode()+o+b'\nendobj\n'
xref=len(pdf);pdf+=f'xref\n0 {len(objects)+1}\n0000000000 65535 f \n'.encode()
for offset in offsets[1:]:pdf+=f'{offset:010d} 00000 n \n'.encode()
pdf+=f'trailer\n<< /Size {len(objects)+1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n'.encode()
(fixtures/'teskelas-jawaban.pdf').write_bytes(pdf)
r=client.post('/auth/login',json={'email':student['DEXA_QA_EMAIL'],'password':student['DEXA_QA_PASSWORD']});r.raise_for_status();student_headers={'Authorization':'Bearer '+r.json()['access_token']}
r=client.get(f'/classes/{class_id}/assignments/{assignment_id}',headers=student_headers);r.raise_for_status();task=r.json()
# Count via authenticated student's own user id, never assume ordering of members.
me=client.get('/auth/me',headers=student_headers);me.raise_for_status()
subs=[s for s in task['submissions'] if s['userId']==me.json()['id']]
base=max((v['versionNumber'] for s in subs for v in s['versions']),default=0)
config={'classId':class_id,'assignmentId':assignment_id,'title':title,'baseVersion':base,'text':'DEXA_MOBILE_QA_TEXT_20261101. Jawaban teks teskelas dikirim dari formulir aplikasi mobile.'}
(private/'submission-qa.json').write_text(json.dumps(config,indent=2),encoding='utf-8')
(root/'docs/evidence/submission-qa-before.json').write_text(json.dumps(config,indent=2),encoding='utf-8')
print(json.dumps(config))
