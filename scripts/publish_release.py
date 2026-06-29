#!/usr/bin/env python3
"""
publish_release.py — Script all-in-one rilis aplikasi SESPIMMA.

Alur (interaktif):
  1. Tentukan versi baru (bump major/minor/patch atau manual) + naikkan build.
  2. Isi judul, deskripsi, dan changelog dinamis: Improvements / Fixes / Patches
     (boleh kosong salah satunya).
  3. (Opsional) tulis versi baru ke pubspec.yaml.
  4. Build APK rilis: `flutter build apk --release`.
  5. Unggah APK + metadata ke VPS via endpoint ber-token POST /app/release.

Hasil: di web halaman Unduh Aplikasi, VERSI, "pembaruan terakhir", ukuran berkas,
dan changelog otomatis berubah.

Penggunaan:
  python3 scripts/publish_release.py
  python3 scripts/publish_release.py --skip-build --apk path/ke/app-release.apk
  python3 scripts/publish_release.py --token <JWT_DEVELOPER>
  python3 scripts/publish_release.py --api https://sespima.web.id/api/v1
"""

import argparse
import datetime
import getpass
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
import uuid

# ── tampilan ──────────────────────────────────────────────────────────────────
G, R, Y, C, B, X = "\033[92m", "\033[91m", "\033[93m", "\033[96m", "\033[1m", "\033[0m"


def color(t, c):
    return t if not sys.stdout.isatty() else f"{c}{t}{X}"


def info(t):
    print(color("• ", C) + t)


def ok(t):
    print(color("✓ ", G) + t)


def warn(t):
    print(color("! ", Y) + t)


def err(t):
    print(color("✗ ", R) + t)


def header(t):
    print("\n" + color(B + t + X, B))


# ── path & konfigurasi ──────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MOBILE_DIR = os.path.dirname(SCRIPT_DIR)
PUBSPEC = os.path.join(MOBILE_DIR, "pubspec.yaml")
DEFAULT_APK = os.path.join(MOBILE_DIR, "build", "app", "outputs", "flutter-apk", "app-release.apk")


def read_env_api():
    """Baca API_BASE_URL dari mobile/.env bila ada."""
    env_path = os.path.join(MOBILE_DIR, ".env")
    if os.path.isfile(env_path):
        for line in open(env_path, encoding="utf-8"):
            line = line.strip()
            if line.startswith("API_BASE_URL="):
                return line.split("=", 1)[1].strip()
    return "https://sespima.web.id/api/v1"


def read_pubspec_version():
    """Mengembalikan (version, build) dari pubspec.yaml, mis. ('1.5.0', 14)."""
    if not os.path.isfile(PUBSPEC):
        return "1.0.0", 0
    for line in open(PUBSPEC, encoding="utf-8"):
        m = re.match(r"^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+?([0-9]+)?", line.strip())
        if m:
            return m.group(1), int(m.group(2) or 0)
    return "1.0.0", 0


def write_pubspec_version(version, build):
    lines = open(PUBSPEC, encoding="utf-8").read().splitlines()
    for i, line in enumerate(lines):
        if line.strip().startswith("version:"):
            lines[i] = f"version: {version}+{build}"
            break
    open(PUBSPEC, "w", encoding="utf-8").write("\n".join(lines) + "\n")


def bump(cur, kind):
    a, b, c = (int(x) for x in cur.split("."))
    if kind == "major":
        return f"{a + 1}.0.0"
    if kind == "minor":
        return f"{a}.{b + 1}.0"
    return f"{a}.{b}.{c + 1}"


# ── input interaktif ────────────────────────────────────────────────────────
def ask(prompt, default=""):
    s = input(color("  " + prompt + (f" [{default}]" if default else "") + ": ", C)).strip()
    return s or default


def ask_list(label):
    """Kumpulkan daftar item; baris kosong untuk selesai."""
    print(color(f"  {label} (Enter kosong untuk selesai):", Y))
    items = []
    while True:
        s = input(color(f"    {len(items) + 1}. ", C)).strip()
        if not s:
            break
        items.append(s)
    return items


def choose_version(cur, build):
    header("1. Versi Rilis")
    info(f"Versi saat ini: {color(cur + '+' + str(build), B)}")
    print("  Pilih jenis kenaikan:")
    print(f"    {color('1', B)}) patch  -> {bump(cur, 'patch')}   (perbaikan kecil)")
    print(f"    {color('2', B)}) minor  -> {bump(cur, 'minor')}   (fitur baru)")
    print(f"    {color('3', B)}) major  -> {bump(cur, 'major')}   (perubahan besar)")
    print(f"    {color('4', B)}) manual (ketik sendiri)")
    c = ask("Pilihan", "1")
    if c == "2":
        return bump(cur, "minor")
    if c == "3":
        return bump(cur, "major")
    if c == "4":
        while True:
            v = ask("Versi (x.y.z)")
            if re.match(r"^\d+\.\d+\.\d+$", v):
                return v
            err("Format tidak valid. Contoh: 1.6.0")
    return bump(cur, "patch")


# ── upload multipart (stdlib) ────────────────────────────────────────────────
def post_release(api, token, meta, apk_path):
    url = api.rstrip("/") + "/app/release"
    boundary = "----sespimma" + uuid.uuid4().hex
    pre = bytearray()
    pre += f'--{boundary}\r\nContent-Disposition: form-data; name="meta"\r\n\r\n'.encode()
    pre += json.dumps(meta).encode("utf-8")
    pre += f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="apk"; filename="{os.path.basename(apk_path)}"\r\n'.encode()
    pre += b"Content-Type: application/vnd.android.package-archive\r\n\r\n"
    with open(apk_path, "rb") as f:
        file_bytes = f.read()
    post = f"\r\n--{boundary}--\r\n".encode()
    body = bytes(pre) + file_bytes + post

    req = urllib.request.Request(url, data=body, method="POST")
    req.add_header("Content-Type", f"multipart/form-data; boundary={boundary}")
    req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=900) as resp:
        return resp.status, resp.read().decode("utf-8", "ignore")


def login(api):
    header("Autentikasi Developer")
    warn("Login akan mengakhiri sesi aktif Anda yang lain (single-session).")
    nrp = ask("NRP/NIP developer")
    pw = getpass.getpass(color("  Kata sandi: ", C))
    url = api.rstrip("/") + "/auth/login"
    data = json.dumps({"nrp_nip": nrp, "password": pw, "device": "web", "force": True}).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=60) as resp:
        body = json.loads(resp.read().decode())
    token = body.get("access_token") or body.get("token")
    if not token:
        raise RuntimeError("Token tidak ditemukan pada respons login")
    return token


def run_build():
    header("Build APK Rilis")
    info("Menjalankan: flutter build apk --release")
    res = subprocess.run(["flutter", "build", "apk", "--release"], cwd=MOBILE_DIR)
    if res.returncode != 0:
        raise RuntimeError("flutter build apk gagal")
    ok("Build selesai")


def main():
    p = argparse.ArgumentParser(description="Publikasikan rilis aplikasi SESPIMMA ke VPS.")
    p.add_argument("--api", default=os.environ.get("API_BASE_URL", read_env_api()))
    p.add_argument("--token", default=os.environ.get("DEV_TOKEN", ""))
    p.add_argument("--apk", default="", help="Pakai APK yang sudah ada (lewati build)")
    p.add_argument("--skip-build", action="store_true", help="Lewati flutter build")
    p.add_argument("--no-pubspec", action="store_true", help="Jangan ubah pubspec.yaml")
    args = p.parse_args()

    print(color(B + "\n=== Publikasi Rilis SESPIMMA ===" + X, B))
    info(f"Target API: {color(args.api, B)}")

    cur, build = read_pubspec_version()
    new_version = choose_version(cur, build)
    new_build = build + 1

    header("2. Catatan Perubahan")
    title = ""
    while not title:
        title = ask("Judul rilis")
        if not title:
            err("Judul wajib diisi.")
    description = ask("Deskripsi singkat")
    improvements = ask_list("Improvements (Peningkatan)")
    fixes = ask_list("Fixes (Perbaikan)")
    patches = ask_list("Patches (Patch)")
    dev_note = ask("Catatan developer (kosongkan = tidak diubah)")
    date = datetime.date.today().strftime("%Y-%m-%d")

    meta = {
        "version": new_version,
        "date": date,
        "title": title,
        "description": description,
        "improvements": improvements,
        "fixes": fixes,
        "patches": patches,
    }
    if dev_note:
        meta["developer_note"] = dev_note

    # ── ringkasan & konfirmasi ──
    header("Ringkasan")
    print(f"  Versi      : {color(f'{cur}+{build}', Y)}  ->  {color(f'{new_version}+{new_build}', G)}")
    print(f"  Tanggal    : {date}")
    print(f"  Judul      : {title}")
    print(f"  Deskripsi  : {description or '-'}")
    print(f"  Improvements: {len(improvements)} | Fixes: {len(fixes)} | Patches: {len(patches)}")
    if ask("Lanjut publikasikan? (y/N)", "N").lower() != "y":
        err("Dibatalkan.")
        return 1

    # ── versi pubspec ──
    if not args.no_pubspec:
        write_pubspec_version(new_version, new_build)
        ok(f"pubspec.yaml diperbarui ke {new_version}+{new_build}")

    # ── APK ──
    apk_path = args.apk
    if not apk_path and not args.skip_build:
        run_build()
        apk_path = DEFAULT_APK
    elif not apk_path:
        apk_path = DEFAULT_APK
    if not os.path.isfile(apk_path):
        err(f"APK tidak ditemukan: {apk_path}")
        return 1
    size_mb = os.path.getsize(apk_path) / (1024 * 1024)
    ok(f"APK siap: {apk_path} ({size_mb:.1f} MB)")

    # ── token ──
    token = args.token
    if not token:
        try:
            token = login(args.api)
            ok("Login berhasil")
        except Exception as e:  # noqa: BLE001
            err(f"Login gagal: {e}")
            return 1

    # ── unggah ──
    header("Mengunggah ke VPS")
    info("Mengirim APK + metadata ...")
    try:
        status, body = post_release(args.api, token, meta, apk_path)
    except urllib.error.HTTPError as e:  # type: ignore[attr-defined]
        err(f"Gagal ({e.code}): {e.read().decode('utf-8', 'ignore')}")
        return 1
    except Exception as e:  # noqa: BLE001
        err(f"Gagal mengunggah: {e}")
        return 1

    if status == 200:
        ok("Rilis berhasil dipublikasikan!")
        try:
            print("  " + json.dumps(json.loads(body), ensure_ascii=False))
        except Exception:  # noqa: BLE001
            print("  " + body)
        info("Cek halaman Unduh Aplikasi — versi, tanggal, ukuran, & changelog sudah diperbarui.")
        return 0
    err(f"Server menolak ({status}): {body}")
    return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print()
        err("Dihentikan.")
        sys.exit(130)
