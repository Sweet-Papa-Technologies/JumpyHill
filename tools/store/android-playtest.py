#!/usr/bin/env python3
"""Playtest identical exported game bytes, then restore the signed normal release."""
import json, os, subprocess, time
from pathlib import Path
root = Path(__file__).resolve().parents[2]; os.chdir(root)
sdk = Path.home() / 'Library/Android/sdk'
adb = [str(sdk/'platform-tools/adb'), '-s', 'emulator-5554']
def run(*args, **kw): return subprocess.check_output([*adb, *args], text=True, **kw).strip()
for _ in range(90):
    try:
        if run('shell', 'getprop', 'sys.boot_completed') == '1': break
    except subprocess.CalledProcessError: pass
    time.sleep(1)
else: raise SystemExit('Android test emulator did not boot')
source=Path('build/android/TREADFALL-store.apk'); clone=Path('build/android/TREADFALL-store-playtest.apk')
subprocess.run(['python3','tools/android_playtest_apk.py',str(source),str(clone)],check=True)
aligned=clone.with_name('playtest-aligned.apk')
subprocess.run([str(sdk/'build-tools/36.1.0/zipalign'),'-f','-P','16','4',str(clone),str(aligned)],check=True);aligned.replace(clone)
env=os.environ.copy();store=Path.home()/'code/SPT';alias='spt'
for variable,account in [('TF_STORE',f'KEY_STORE_PASSWORD__{store}'),('TF_KEY',f'KEY_PASSWORD__{store}__{alias}')]:
    env[variable]=subprocess.check_output(['security','find-generic-password','-a',account,'-w'],text=True).strip()
subprocess.run([str(sdk/'build-tools/36.1.0/apksigner'),'sign','--ks',str(store),'--ks-key-alias',alias,'--ks-pass','env:TF_STORE','--key-pass','env:TF_KEY',str(clone)],env=env,check=True)
installed=subprocess.run([*adb,'install','-r',str(clone)],capture_output=True,text=True)
if installed.returncode:
    if 'INSTALL_FAILED_UPDATE_INCOMPATIBLE' not in installed.stderr+installed.stdout: raise SystemExit(installed.stderr)
    print('Replacing the previous locally test-signed emulator installation.')
    run('uninstall','com.sweetpapa.treadfall');print(run('install',str(clone)))
try:
    run('logcat','-c');run('shell','am','start','-n','com.sweetpapa.treadfall/com.godot.game.GodotAppLauncher')
    for _ in range(180):
        log=run('logcat','-d','-s','godot:I','AndroidRuntime:E')
        if 'PLAYTEST PASS ' in log:
            data=json.loads(next(line.split('PLAYTEST PASS ',1)[1] for line in log.splitlines() if 'PLAYTEST PASS ' in line))
            assert data['result']['outcome']=='GOAL',data
            Path('build/store/android-playtest.json').write_text(json.dumps(data,indent=2))
            print('ANDROID EXPORTED PLAYTEST PASS',json.dumps(data));break
        if 'PLAYTEST FAIL' in log or 'FATAL EXCEPTION' in log: raise SystemExit(log)
        time.sleep(1)
    else: raise SystemExit('Android playtest did not finish')
finally:
    run('shell','am','force-stop','com.sweetpapa.treadfall')
    print(run('install','-r',str(source)))
    run('shell','am','start','-n','com.sweetpapa.treadfall/com.godot.game.GodotAppLauncher')
