import json
from pathlib import Path
import psycopg2
from dotenv import dotenv_values
root=Path(__file__).resolve().parents[1]
before=json.loads((root/'docs/evidence/class-live-before.json').read_text())
config=dotenv_values(r"D:\DeXa_Assessment_fik\ai-assessment-copilot\apps\frontend\.env")
c=psycopg2.connect(config['DATABASE_URL']);c.set_session(readonly=True)
with c.cursor() as q:
 q.execute('SELECT count(*) FROM enrollments WHERE "mahasiswaId"=%s AND "classId"=%s',(before['accountId'],before['classId']));count=q.fetchone()[0]
 q.execute('SELECT count(*) FROM enrollments WHERE "classId"=%s',(before['classId'],));total=q.fetchone()[0]
 q.execute('SELECT count(*) FROM submissions WHERE "mahasiswaId"=%s',(before['accountId'],));submissions=q.fetchone()[0]
c.close()
report={'account':'teskelas','className':before['className'],'membersBefore':before['enrollmentsBefore'],'membersAfter':total,'teskelasMemberships':count,'teskelasSubmissions':submissions,'verification':'read-only SQL; enrollment created by Flutter widget UI using real FastAPI; Android runtime blocked'}
(root/'docs/evidence/class-live-database.json').write_text(json.dumps(report,indent=2));print(json.dumps(report))
