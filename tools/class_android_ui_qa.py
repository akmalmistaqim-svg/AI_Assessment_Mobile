"""Interact only with the Dexa app on the dedicated Android emulator."""
import subprocess, xml.etree.ElementTree as ET, json, re, sys, time
from pathlib import Path
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'.local/teskelas.json').read_text())
adb=r"C:\Users\user\AppData\Local\Android\sdk\platform-tools\adb.exe"
def run(*args): return subprocess.check_output([adb,'-s','emulator-5554',*args],timeout=45)
def nodes():
 for attempt in range(4):
  try:
   output=run('shell','uiautomator','dump','/sdcard/window-qa.xml')
   if b'dumped to' in output:
    return list(ET.fromstring(run('shell','cat','/sdcard/window-qa.xml')).iter('node'))
  except subprocess.SubprocessError: pass
  time.sleep(2)
 raise RuntimeError('Android UI hierarchy unavailable; stale XML will not be used')
def desc(n):return n.get('content-desc','') or n.get('text','')
def find(predicate):
 candidates=[n for n in nodes() if predicate(n)]
 if len(candidates)!=1: raise RuntimeError('Expected one matching UI element; found '+str(len(candidates)))
 return candidates[0]
def tap(n):
 b=list(map(int,re.findall(r'\d+',n.get('bounds',''))));assert len(b)==4
 run('shell','input','tap',str((b[0]+b[2])//2),str((b[1]+b[3])//2))
def exact(value):return find(lambda n:desc(n)==value)
def wait_text(value,timeout=100):
 end=time.monotonic()+timeout
 while time.monotonic()<end:
  ns=nodes()
  if any(value in desc(n) for n in ns):return ns
  time.sleep(1)
 raise RuntimeError('UI did not show expected label: '+value)
def capture(name):
 (root/'docs/evidence'/('class-ui-'+name+'.png')).write_bytes(run('exec-out','screencap','-p'))
def report(ns):
 for n in ns:
  if desc(n) or 'EditText' in n.get('class',''):
   text='[REDACTED]' if n.get('password')=='true' else desc(n).replace(data['DEXA_QA_PASSWORD'],'[REDACTED]')
   print(json.dumps({'label':text,'class':n.get('class'),'bounds':n.get('bounds'),'clickable':n.get('clickable')},ensure_ascii=True))
stage=sys.argv[1]
if stage=='login':
 run('shell','am','force-stop','com.example.dexa_assessment_mobile')
 run('shell','am','start','-W','-n','com.example.dexa_assessment_mobile/.MainActivity');time.sleep(5)
 wait_text('Masuk ke akun Anda')
 def slow_type(value):
  for char in value:
   run('shell','input','text',char);time.sleep(0.25)
 tap(find(lambda n:n.get('class')=='android.widget.EditText' and n.get('password')=='false'))
 time.sleep(3);slow_type(data['DEXA_QA_EMAIL']);time.sleep(3);run('shell','input','keyevent','4');time.sleep(2)
 assert find(lambda n:n.get('class')=='android.widget.EditText' and n.get('password')=='false').get('text')==data['DEXA_QA_EMAIL'], 'Input automation did not enter exact email'
 print('Exact email verified',flush=True)
 tap(find(lambda n:n.get('class')=='android.widget.EditText' and n.get('password')=='true'))
 time.sleep(3);slow_type(data['DEXA_QA_PASSWORD']);time.sleep(3);run('shell','input','keyevent','4');time.sleep(2)
 tap(exact('Masuk'));ns=wait_text('Selamat datang,');capture('dashboard');report(ns)
elif stage=='classes':
 tap(find(lambda n:'Kelas Saya' in desc(n) and 'Tab' in desc(n)))
 ns=wait_text('Gabung kelas');capture('classes-before');report(ns)
elif stage=='join':
 ns=nodes()
 if any(data['DEXA_QA_CLASS_NAME'] in desc(n) for n in ns):raise RuntimeError('Already enrolled; positive join must not be repeated')
 tap(find(lambda n:n.get('class')=='android.widget.EditText'))
 time.sleep(2);run('shell','input','text',data['DEXA_QA_CLASS_CODE'].lower());time.sleep(1);run('shell','input','keyevent','4')
 tap(find(lambda n:desc(n)=='Gabung kelas' and n.get('class')=='android.widget.Button'))
 ns=wait_text(data['DEXA_QA_CLASS_NAME']);capture('joined');report(ns)
elif stage=='inspect':report(nodes());capture('current')
else: raise SystemExit('Unknown stage')
print('UI stage completed: '+stage)
