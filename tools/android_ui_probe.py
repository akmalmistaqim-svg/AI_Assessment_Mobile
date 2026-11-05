import subprocess, xml.etree.ElementTree as ET, json
from pathlib import Path
adb=r"C:\Users\user\AppData\Local\Android\sdk\platform-tools\adb.exe"
def run(*args): return subprocess.check_output([adb,'-s','emulator-5554',*args],timeout=40)
if __name__=='__main__':
 run('shell','uiautomator','dump','/sdcard/window-qa.xml')
 xml=run('shell','cat','/sdcard/window-qa.xml')
 for n in ET.fromstring(xml).iter('node'):
  if n.get('text') or n.get('content-desc') or 'EditText' in n.get('class',''):
   item={k:n.get(k) for k in ['text','content-desc','class','bounds','clickable','password']}
   if n.get('password')=='true': item['text']='[REDACTED]';item['content-desc']='[REDACTED]'
   print(json.dumps(item,ensure_ascii=True))
 Path('docs/evidence/class-live-emulator-current.png').write_bytes(run('exec-out','screencap','-p'))
