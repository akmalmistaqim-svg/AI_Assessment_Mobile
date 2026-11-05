"""Run the dedicated enrollment integration APK, with redacted credentials."""
import json, subprocess, sys
from pathlib import Path
sys.stdout.reconfigure(encoding="utf-8",errors="replace")
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'.local/teskelas.json').read_text())
cmd=[r"D:\flutter\bin\flutter.bat",'drive','--no-pub','--driver=test_driver/student_driver.dart','--target=integration_test/student_class_live_test.dart','-d','emulator-5554','--dart-define-from-file=.local/teskelas.json','--use-application-binary=.local/artifacts/app-class-test.apk']
with (root/'docs/evidence/student-class-live-android.log').open('w',encoding='utf-8') as log:
 p=subprocess.Popen(cmd,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace')
 for line in p.stdout:
  for key in ['DEXA_QA_PASSWORD','DEXA_QA_CLASS_CODE']: line=line.replace(data[key],'[REDACTED]')
  if any(x in line for x in ['Dart VM service','Observatory','VMServiceFlutterDriver: Connecting']): line='Flutter VM service connection (address omitted)\n'
  log.write(line);log.flush();print(line,end='',flush=True)
 code=p.wait()
sys.exit(code)
