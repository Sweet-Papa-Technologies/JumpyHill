#!/usr/bin/env python3
"""Exercise the exported game in an iPhone simulator and retain its assertions."""
import json, os, shutil, subprocess, sys, time
from pathlib import Path

def run(*args, **kw):
    return subprocess.check_output(args, text=True, **kw).strip()

available = json.loads(run('xcrun', 'simctl', 'list', 'devices', 'available', '-j'))['devices']
candidates = [(runtime, d) for runtime, devices in available.items() for d in devices
              if 'iOS-26' in runtime and 'iPhone' in d['name']]
if not candidates:
    raise SystemExit('An iOS 26 iPhone simulator is required.')
runtime, device = max(candidates, key=lambda pair: (pair[0], 'Pro Max' in pair[1]['name'], pair[1]['name']))
udid = device['udid']
output = Path('build/ios-playtest'); output.mkdir(parents=True, exist_ok=True)
started = device['state'] != 'Booted'
try:
    if started: run('xcrun', 'simctl', 'boot', udid)
    run('xcrun', 'simctl', 'bootstatus', udid, '-b')
    run('xcrun', 'simctl', 'install', udid, str(Path(sys.argv[1]).resolve()))
    container = Path(run('xcrun', 'simctl', 'get_app_container', udid, 'com.sweetpapa.treadfall', 'data'))
    report = container / 'Documents/playtest/report.json'
    if report.exists(): report.unlink()
    env = os.environ.copy(); env['SIMCTL_CHILD_TREADFALL_PLAYTEST'] = '1'
    print(run('xcrun', 'simctl', 'launch', udid, 'com.sweetpapa.treadfall', env=env), flush=True)
    for _ in range(600):
        if report.exists(): break
        time.sleep(1)
    if not report.exists(): raise SystemExit('Exported iOS playtest did not finish within 10 minutes.')
    data = json.loads(report.read_text())
    shutil.copytree(report.parent, output, dirs_exist_ok=True)
    assert all(data.get(key) == 'pass' for key in ['retry', 'pause_resume', 'daily']), data
    assert data['result']['outcome'] == 'GOAL', data
    (output / 'device.json').write_text(json.dumps({'runtime':runtime, 'name':device['name']}, indent=2))
    print('EXPORTED IOS PLAYTEST PASS', json.dumps(data))
finally:
    if started: subprocess.run(['xcrun', 'simctl', 'shutdown', udid], check=False)
