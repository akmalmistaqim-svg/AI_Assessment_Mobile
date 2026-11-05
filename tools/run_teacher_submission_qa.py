import ast, os, subprocess
from pathlib import Path
source=Path(r"D:\Dexa_Assessment_Backend\DeXa_Assessment_Backend\seed_e2e_fixtures.py")
module=ast.parse(source.read_text(encoding='utf-8'))
password=next(ast.literal_eval(n.value) for n in module.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='FIXTURE_PASSWORD' for t in n.targets))
env=os.environ.copy();env['DEXA_QA_TEACHER_PASSWORD']=password
raise SystemExit(subprocess.call(['node','tools/check_teacher_submission.cjs'],env=env,cwd=Path(__file__).resolve().parents[1]))
