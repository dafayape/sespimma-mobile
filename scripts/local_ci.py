import os
import sys
import subprocess
import argparse
import time
import re
import logging
import shutil
from typing import List, Optional


ANSI_GREEN  = "\033[92m"
ANSI_RED    = "\033[91m"
ANSI_YELLOW = "\033[93m"
ANSI_CYAN   = "\033[96m"
ANSI_BOLD   = "\033[1m"
ANSI_RESET  = "\033[0m"

SUBPROCESS_TIMEOUT_SECONDS = 600


def supports_color() -> bool:
    return sys.stdout.isatty() and sys.platform != "win32"


def colorize(text: str, color: str) -> str:
    if not supports_color():
        return text
    return f"{color}{text}{ANSI_RESET}"


def setup_logger(log_file: str) -> logging.Logger:
    logger = logging.getLogger("local_ci")
    logger.setLevel(logging.DEBUG)

    file_handler = logging.FileHandler(log_file, encoding="utf-8")
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(
        logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
    )

    logger.addHandler(file_handler)
    return logger


class StepResult:
    def __init__(self, name: str, passed: bool, duration: float, note: str = "") -> None:
        self.name     = name
        self.passed   = passed
        self.duration = duration
        self.note     = note


class LocalCI:
    def __init__(self, logger: logging.Logger, fail_fast: bool = False) -> None:
        self.start_time  = time.time()
        self.results: List[StepResult] = []
        self.logger      = logger
        self.fail_fast   = fail_fast

    def _record(self, name: str, passed: bool, duration: float, note: str = "") -> bool:
        self.results.append(StepResult(name, passed, duration, note))
        status_text = colorize("SUCCESS", ANSI_GREEN) if passed else colorize("FAILED", ANSI_RED)
        print(f"  {status_text} [{name}] ({duration:.1f}s){f'  — {note}' if note else ''}")
        self.logger.info("Step '%s' %s in %.1fs. %s", name, "passed" if passed else "failed", duration, note)
        return passed

    def run_command(
        self,
        name: str,
        command: List[str],
        note: str = "",
        timeout: int = SUBPROCESS_TIMEOUT_SECONDS,
    ) -> bool:
        print(colorize(f"\n  Running: {name}", ANSI_CYAN))
        self.logger.info("Starting step '%s': %s", name, " ".join(command))
        step_start = time.time()

        try:
            safe_command = ["cmd", "/c"] + command if sys.platform.startswith("win") else command

            result = subprocess.run(
                safe_command,
                stdout=sys.stdout,
                stderr=sys.stderr,
                text=True,
                check=False,
                shell=False,
                timeout=timeout,
            )

            duration = time.time() - step_start
            passed   = result.returncode == 0

            if not passed:
                self.logger.error("Step '%s' exited with code %d", name, result.returncode)

            return self._record(name, passed, duration, note)

        except subprocess.TimeoutExpired:
            duration = time.time() - step_start
            msg = f"Timeout after {timeout}s"
            print(colorize(f"  TIMEOUT [{name}] — {msg}", ANSI_YELLOW))
            self.logger.warning("Step '%s' timed out after %ds", name, timeout)
            return self._record(name, False, duration, msg)

        except FileNotFoundError:
            duration = time.time() - step_start
            msg = f"Command not found: '{command[0]}'. Is it installed and on PATH?"
            print(colorize(f"  ERROR [{name}] — {msg}", ANSI_RED))
            self.logger.error(msg)
            return self._record(name, False, duration, msg)

        except Exception as exc:
            duration = time.time() - step_start
            msg = str(exc)
            print(colorize(f"  ERROR [{name}] — {msg}", ANSI_RED))
            self.logger.exception("Unexpected error in step '%s'", name)
            return self._record(name, False, duration, msg)

    def ensure_dummy_env(self) -> None:
        if not os.path.exists(".env"):
            with open(".env", "w", encoding="utf-8") as env_file:
                env_file.write("")
            self.logger.info("Created empty .env file.")

    def run_clean_comments(self) -> bool:
        name = "Clean Comments"
        print(colorize(f"\n  Running: {name}", ANSI_CYAN))
        self.logger.info("Starting step '%s'", name)
        step_start = time.time()

        try:
            project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            target_dirs  = [
                os.path.join(project_root, "lib"),
                os.path.join(project_root, "test"),
            ]

            pattern = re.compile(
                r"(\'\'\'(?:.|\n)*?\'\'\'|\"\"\"(?:.|\n)*?\"\"\")"
                r"|(\'(?:\\.|[^\\\'])*\')"
                r"|(\"(?:\\.|[^\\\"])*\")"
                r"|(/\*(?:.|\n)*?\*/)"
                r"|(//[^\n]*)"
            )

            def _replacer(match: re.Match) -> str:
                if match.group(1) or match.group(2) or match.group(3):
                    return match.group(0)
                return ""

            def _clean_file(filepath: str) -> bool:
                with open(filepath, "r", encoding="utf-8") as dart_file:
                    original = dart_file.read()

                cleaned = pattern.sub(_replacer, original)
                cleaned = re.sub(r"\n\s*\n\s*\n", "\n\n", cleaned)

                if original == cleaned:
                    return False

                backup = filepath + ".ci_bak"
                shutil.copy2(filepath, backup)
                try:
                    with open(filepath, "w", encoding="utf-8") as dart_file:
                        dart_file.write(cleaned)
                    os.remove(backup)
                    self.logger.debug("Cleaned comments: %s", filepath)
                    return True
                except Exception:
                    shutil.copy2(backup, filepath)
                    os.remove(backup)
                    self.logger.error("Failed to write cleaned file, restored: %s", filepath)
                    raise

            total_cleaned = 0
            for target_dir in target_dirs:
                if not os.path.exists(target_dir):
                    continue
                for root, _, files in os.walk(target_dir):
                    for filename in files:
                        if filename.endswith(".dart"):
                            filepath = os.path.join(root, filename)
                            if _clean_file(filepath):
                                total_cleaned += 1
                                rel = os.path.relpath(filepath)
                                print(f"    Cleaned: {rel}")
                                self.logger.debug("Cleaned comments: %s", rel)

            note = f"Cleaned {total_cleaned} Dart file(s)"
            print(f"  {note}")
            duration = time.time() - step_start
            return self._record(name, True, duration, note)

        except Exception as exc:
            duration = time.time() - step_start
            msg = str(exc)
            print(colorize(f"  ERROR [{name}] — {msg}", ANSI_RED))
            self.logger.exception("Unexpected error in step '%s'", name)
            return self._record(name, False, duration, msg)

    def check_outdated(self) -> bool:
        name = "Outdated Check"
        print(colorize(f"\n  Running: {name}", ANSI_CYAN))
        self.logger.info("Starting step '%s'", name)
        step_start = time.time()

        try:
            safe_command = (
                ["cmd", "/c", "flutter", "pub", "outdated", "--json"]
                if sys.platform.startswith("win")
                else ["flutter", "pub", "outdated", "--json"]
            )

            result = subprocess.run(
                safe_command,
                capture_output=True,
                text=True,
                check=False,
                shell=False,
                timeout=120,
            )

            duration = time.time() - step_start

            if result.returncode != 0:
                return self._record(name, False, duration, "flutter pub outdated failed")

            try:
                import json
                data       = json.loads(result.stdout)
                packages   = data.get("packages", [])
                upgradable = [
                    p["package"]
                    for p in packages
                    if p.get("current") and p.get("upgradable")
                    and p["current"]["version"] != p["upgradable"]["version"]
                ]
                count = len(upgradable)
                note  = f"{count} package(s) can be upgraded" if count else "All packages up to date"
                if count:
                    print(colorize(f"  {note}", ANSI_YELLOW))
                    self.logger.warning("Outdated packages: %s", ", ".join(upgradable))
            except Exception:
                note = "Could not parse outdated output"

            return self._record(name, True, duration, note)

        except subprocess.TimeoutExpired:
            duration = time.time() - step_start
            return self._record(name, False, duration, "Timeout")

        except Exception as exc:
            duration = time.time() - step_start
            self.logger.exception("Unexpected error in step '%s'", name)
            return self._record(name, False, duration, str(exc))

    def fail_fast_check(self, passed: bool) -> None:
        if not passed and self.fail_fast:
            print(colorize("\n  Fail-fast enabled — stopping pipeline.", ANSI_RED))
            self.logger.error("Fail-fast triggered. Stopping pipeline.")
            self.print_summary()
            sys.exit(1)

    def print_summary(self) -> None:
        total_duration = time.time() - self.start_time
        passed = [r for r in self.results if r.passed]
        failed = [r for r in self.results if not r.passed]

        print("\n" + colorize("=" * 50, ANSI_BOLD))
        print(colorize("  LOCAL CI SUMMARY", ANSI_BOLD))
        print(colorize("=" * 50, ANSI_BOLD))
        print(f"  Time Taken   : {total_duration:.2f}s")
        print(f"  Steps Passed : {colorize(str(len(passed)), ANSI_GREEN)}")
        print(f"  Steps Failed : {colorize(str(len(failed)), ANSI_RED if failed else ANSI_GREEN)}")

        if failed:
            print(colorize("\n  Failed Steps:", ANSI_RED))
            for step in failed:
                note_text = f" — {step.note}" if step.note else ""
                print(colorize(f"    ✗ {step.name}{note_text}", ANSI_RED))

        overall = colorize("SUCCESS", ANSI_GREEN) if not failed else colorize("FAILED", ANSI_RED)
        print(f"\n  STATUS       : {overall}")
        print(colorize("=" * 50, ANSI_BOLD))

        self.logger.info(
            "CI finished in %.2fs. Passed: %d, Failed: %d. Status: %s",
            total_duration,
            len(passed),
            len(failed),
            "SUCCESS" if not failed else "FAILED",
        )

        if failed:
            sys.exit(1)


def main() -> None:
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(project_root)

    parser = argparse.ArgumentParser(description="Local CI Pipeline")
    parser.add_argument("--skip-build",    action="store_true", help="Skip APK build step")
    parser.add_argument("--skip-tests",    action="store_true", help="Skip test step")
    parser.add_argument("--skip-outdated", action="store_true", help="Skip outdated packages check")
    parser.add_argument("--fail-fast",     action="store_true", help="Stop pipeline on first failure")
    parser.add_argument("--log-file",      default="ci_run.log", help="Path to log file")
    args = parser.parse_args()

    if not os.path.exists("pubspec.yaml"):
        print(colorize(f"  Error: pubspec.yaml not found in {project_root}", ANSI_RED))
        sys.exit(1)

    logger = setup_logger(args.log_file)
    logger.info("CI pipeline started. project_root=%s", project_root)

    ci = LocalCI(logger=logger, fail_fast=args.fail_fast)
    ci.ensure_dummy_env()

    print(colorize("\n  LOCAL CI PIPELINE", ANSI_BOLD))
    print(colorize(f"  Project : {project_root}", ANSI_CYAN))
    print(colorize(f"  Log     : {args.log_file}\n", ANSI_CYAN))

    result = ci.run_command("Pub Get", ["flutter", "pub", "get"])
    ci.fail_fast_check(result)

    if not args.skip_outdated:
        ci.check_outdated()

    result = ci.run_clean_comments()
    ci.fail_fast_check(result)

    result = ci.run_command(
        "Format",
        ["dart", "format", "lib/", "test/"],
        note="Auto-formatted all Dart files",
    )
    ci.fail_fast_check(result)

    result = ci.run_command("Analyze", ["flutter", "analyze", "--no-fatal-infos"])
    ci.fail_fast_check(result)

    if not args.skip_tests:
        result = ci.run_command("Test", ["flutter", "test", "--coverage"])
        ci.fail_fast_check(result)

    if not args.skip_build:
        build_cmd = [
            "flutter", "build", "apk", "--release",
            "--split-per-abi",
            "--obfuscate",
            "--split-debug-info=build/debug-info/",
        ]
        result = ci.run_command(
            "Build APK",
            build_cmd,
            note="APKs at build/app/outputs/flutter-apk/",
            timeout=900,
        )
        ci.fail_fast_check(result)

    ci.print_summary()


if __name__ == "__main__":
    main()