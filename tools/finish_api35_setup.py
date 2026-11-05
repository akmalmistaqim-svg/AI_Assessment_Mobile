"""Finish the authorized API 35 AVD setup once the SDK download is installed.
No downloads, existing AVD changes, or emulator launches are performed here.
"""
import json,os,subprocess,time
from pathlib import Path
root=Path(__file__).resolve().parents[1]
sdk=Path(r'C:\Users\user\AppData\Local\Android\sdk')
image=sdk/'system-images/android-35/google_apis/x86_64'
avdhome=root/'.local/avd';avd=avdhome/'Dexa_API35.avd'
status=root/'docs/evidence/api35-setup-status.json'
def record(state,**extra):
 status.write_text(json.dumps({'state':state,'image':str(image),'avd':str(avd),'updatedAt':time.strftime('%Y-%m-%d %H:%M:%S'),**extra},indent=2),encoding='utf-8')
record('waiting_for_sdk_install')
deadline=time.monotonic()+12*60*60
while not ((image/'package.xml').is_file() and (image/'system.img').is_file()):
 if time.monotonic()>deadline:record('download_not_ready_after_12_hours');raise SystemExit(2)
 time.sleep(30)
if (avd/'config.ini').is_file():record('avd_already_exists_no_changes');raise SystemExit(0)
avdhome.mkdir(parents=True,exist_ok=True)
env=os.environ.copy();env['JAVA_HOME']=r'D:\android studio\jbr';env['ANDROID_AVD_HOME']=str(avdhome)
record('creating_avd')
try:
 result=subprocess.run([str(sdk/'cmdline-tools/latest/bin/avdmanager.bat'),'create','avd','-n','Dexa_API35','-k','system-images;android-35;google_apis;x86_64','-p',str(avd)],input='no\n',capture_output=True,text=True,encoding='utf-8',errors='replace',env=env,timeout=180)
 (root/'docs/evidence/api35-create.log').write_text(result.stdout+'\n'+result.stderr,encoding='utf-8')
 if result.returncode:record('avd_create_failed',exitCode=result.returncode);raise SystemExit(result.returncode)
 config=avd/'config.ini';text=config.read_text(encoding='utf-8');settings={'hw.ramSize':'2048','hw.cpu.ncore':'2','vm.heapSize':'256','hw.lcd.width':'720','hw.lcd.height':'1280','hw.lcd.density':'320','hw.gpu.enabled':'yes','hw.gpu.mode':'host','disk.dataPartition.size':'2G','showDeviceFrame':'no'}
 lines=[line for line in text.splitlines() if line.split('=',1)[0].strip() not in settings]
 lines.extend(f'{key}={value}' for key,value in settings.items());config.write_text('\n'.join(lines)+'\n',encoding='utf-8')
 record('ready_not_booted',api=35,ramMb=2048,cores=2)
except Exception as error:
 record('setup_failed',error=str(error));raise
