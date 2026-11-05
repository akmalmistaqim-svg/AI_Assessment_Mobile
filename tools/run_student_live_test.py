"""Runs Android integration tests with existing public QA fixture credentials.
Credentials are read from the fixture source, never saved in mobile files or logs.
This script does not seed, migrate, or modify backend data.
"""
import ast
import os
import subprocess
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = Path(r"D:\Dexa_Assessment_Backend\DeXa_Assessment_Backend\seed_e2e_fixtures.py")
module = ast.parse(source.read_text(encoding="utf-8"))
password = next(ast.literal_eval(n.value) for n in module.body
    if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name)
    and t.id == "FIXTURE_PASSWORD" for t in n.targets))
command = [r"D:\flutter\bin\flutter.bat", "drive", "--no-pub",
    "--driver=test_driver/student_driver.dart", "--target=integration_test/student_live_test.dart",
    "-d", "emulator-5554", "--dart-define=DEXA_QA_EMAIL=mhs_a@test.local",
    "--dart-define=DEXA_QA_PASSWORD=" + password]
if "--existing-apk" in sys.argv:
    apk = root / "build/app/outputs/flutter-apk/app-debug.apk"
    if not apk.is_file():
        raise SystemExit("No existing test APK. Run once without --existing-apk first.")
    command.append("--use-application-binary=" + str(apk))
log = root / "docs/evidence/student-live-android.log"
with log.open("w", encoding="utf-8") as output:
    process = subprocess.Popen(command, cwd=root, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace")
    for line in process.stdout:
        safe = line.replace(password, "[REDACTED]")
        # VM service tokens are not useful in a saved QA report.
        if "Dart VM service" in safe or "Observatory" in safe or "VMServiceFlutterDriver: Connecting" in safe:
            safe = "Flutter VM service connected (address omitted).\n"
        print(safe, end="", flush=True)
        output.write(safe)
        output.flush()
    code = process.wait()
raise SystemExit(code)
