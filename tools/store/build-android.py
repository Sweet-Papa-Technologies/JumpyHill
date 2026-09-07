#!/usr/bin/env python3
"""Export AAB/APK with official Gradle template, then sign using local SPT keys."""
import hashlib, json, os, re, subprocess, zipfile
from pathlib import Path
root = Path(__file__).resolve().parents[2]
os.chdir(root)
env = os.environ.copy()
version = env.get('TREADFALL_VERSION', '0.5.0')
number = env.get('TREADFALL_BUILD_NUMBER', '15')
assert re.fullmatch(r'\d+\.\d+\.\d+', version) and re.fullmatch(r'[1-9]\d*', number)
store = Path(env.get('TREADFALL_KEYSTORE', str(Path.home() / 'code/SPT')))
alias = env.get('TREADFALL_KEY_ALIAS', 'spt')
def password(variable, account):
    return env.get(variable) or subprocess.check_output(['security', 'find-generic-password', '-a', account, '-w'], text=True).strip()
env['TREADFALL_STORE_PASSWORD'] = password('TREADFALL_STORE_PASSWORD', f'KEY_STORE_PASSWORD__{store}')
env['TREADFALL_KEY_PASSWORD'] = password('TREADFALL_KEY_PASSWORD', f'KEY_PASSWORD__{store}__{alias}')
java = Path(env.get('JAVA_HOME', str(Path.home() / 'Library/Java/JavaVirtualMachines/corretto-17.0.7/Contents/Home')))
env['JAVA_HOME'] = str(java)
sdk = Path.home() / 'Library/Android/sdk'
android_tools = sdk / 'build-tools/36.1.0'
source = Path('.tools/templates/android_source.zip')
if not source.exists():
    with zipfile.ZipFile('.tools/templates.tpz') as z: source.write_bytes(z.read('templates/android_source.zip'))
build_dir = Path('build/android-gradle/build')
if not (build_dir / 'build.gradle').exists():
    with zipfile.ZipFile(source) as z: z.extractall(build_dir)
    (build_dir / 'gradlew').chmod(0o755)
    (build_dir / '.gdignore').touch()
    (build_dir.parent / '.build_version').write_text('res://.tools/templates/android_source.zip [' + hashlib.md5(source.read_bytes()).hexdigest() + ']')
preset = Path('export_presets.cfg'); original = preset.read_text()
try:
    for suffix, fmt in [('aab', 1), ('apk', 0)]:
        section = original[original.index('[preset.3]'):].replace('preset.3', 'preset.4').replace('name="Android"', 'name="AndroidStore"')
        section = section.replace('gradle_build/use_gradle_build=false', f'''gradle_build/use_gradle_build=true
gradle_build/android_source_template="res://.tools/templates/android_source.zip"
gradle_build/gradle_build_directory="res://build/android-gradle"
gradle_build/export_format={fmt}
gradle_build/target_sdk="36"
launcher_icons/main_192x192="res://assets/ui/icon.svg"''')
        section = section.replace('version/code=1', f'version/code={number}').replace('version/name="0.1.0"', f'version/name="{version}"')
        preset.write_text(original + '\n' + section)
        dest = Path(f'build/android/TREADFALL-store.{suffix}')
        subprocess.run(['tools/godot', '--headless', '--export-release', 'AndroidStore', str(dest)], env=env, check=True)
        if suffix == 'aab':
            subprocess.run([str(java / 'bin/jarsigner'), '-keystore', str(store), '-storepass:env', 'TREADFALL_STORE_PASSWORD', '-keypass:env', 'TREADFALL_KEY_PASSWORD', str(dest), alias], env=env, check=True)
            subprocess.run([str(java / 'bin/jarsigner'), '-verify', str(dest)], check=True)
        else:
            aligned = dest.with_name('TREADFALL-store-aligned.apk')
            subprocess.run([str(android_tools / 'zipalign'), '-f', '-P', '16', '4', str(dest), str(aligned)], check=True)
            aligned.replace(dest)
            subprocess.run([str(android_tools / 'apksigner'), 'sign', '--ks', str(store), '--ks-key-alias', alias, '--ks-pass', 'env:TREADFALL_STORE_PASSWORD', '--key-pass', 'env:TREADFALL_KEY_PASSWORD', str(dest)], env=env, check=True)
            subprocess.run([str(android_tools / 'apksigner'), 'verify', '--verbose', '--print-certs', str(dest)], env=env, check=True)
        manifest = {'version': version, 'build': int(number), 'package': 'com.sweetpapa.treadfall', 'sha256': hashlib.sha256(dest.read_bytes()).hexdigest(), 'commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()}
        dest.with_suffix('.'+suffix+'.manifest.json').write_text(json.dumps(manifest, indent=2))
finally:
    preset.write_text(original)
