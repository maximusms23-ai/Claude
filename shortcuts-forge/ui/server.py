#!/usr/bin/env python3
"""
server.py — Forge-UI: lokales Web-Tool fuer die AI→Apple-Shortcuts-Pipeline

Zweck:
    Browser-Oberflaeche fuer tom-shortcut: Anforderung eintippen → Kurzbefehl
    wird gebaut (build) oder ein bestehender Draft geaendert (remix).
    Import/Run direkt aus der Liste. Ein Job zur Zeit, Live-Log per Polling.

Start:
    tom-shortcut ui [port]          # Default 7461, oeffnet Browser
    python3 server.py --port 7461

Sicherheit:
    Bindet NUR an 127.0.0.1 (kein LAN-Zugriff). Import/Run validieren gegen
    die Ablage. Der Build-Subprozess laeuft ohne CLAUDECODE-Env — die UI ist
    ein eigener Kontext, kein Claude-in-Claude (bewusster Guard-Bypass).

Dependencies: Python 3 stdlib only.
"""

import argparse
import json
import os
import signal
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

FORGE_ROOT = Path(__file__).resolve().parent.parent
UI_DIR = Path(__file__).resolve().parent
OUT = Path.home() / "Documents" / "Tom-Shortcuts"
TOM_SHORTCUT = Path("/Users/maxim/Claude/bin/tom-shortcut")

# Modell-Allowlist fuer die UI. "" = CLI-Default (grosses Modell des Logins).
MODELS = {
    "claude-sonnet-5": "Sonnet 5 — Token-sparend (Standard)",
    "claude-opus-4-8": "Opus 4.8 — stark fuer komplexe Aufgaben (weniger Fehlversuche, pro Token teurer)",
    "claude-haiku-4-5-20251001": "Haiku 4.5 — maximal sparsam (einfache Kurzbefehle)",
    "": "CLI-Default — bestes Modell (teuerste Option)",
}


def shutil_which(cmd):
    from shutil import which
    return which(cmd) or which(cmd, path=str(Path.home() / ".local" / "bin"))


def engines_available():
    """Engine-Verfuegbarkeit fuer das UI-Dropdown (siehe 61-02-MULTI-ENGINE-PLAN.md)."""
    codex = bool(shutil_which("codex"))
    ollama = bool(shutil_which("ollama"))
    return {
        "claude": {"label": "Claude (Standard — Modellwahl oben)", "available": True},
        "codex": {"label": "ChatGPT/Codex (Cloud — braucht codex login)", "available": codex},
        "codex-oss": {"label": "Open Source lokal (gpt-oss via Ollama — Stufe 2)", "available": codex and ollama},
    }

# ------------------------------------------------------------------ Job-State
_lock = threading.Lock()
_job = {
    "id": 0, "kind": None, "label": "", "status": "idle",   # idle|running|success|error|cancelled
    "started": None, "finished": None, "log": "",
    "args": [],           # Original-Argumente -> ermoeglicht Neu-Starten
    "resume_draft": None, # seit Job-Start entstandener Draft -> ermoeglicht Fortsetzen
}
_proc = None  # laufender Subprozess (nicht JSON-serialisierbar, daher getrennt)
JOB_STATE_FILE = OUT / ".last-job.json"


def _persist_job():
    """Job-Metadaten auf Platte — ueberlebt Server-Neustarts (Maxim: 'Restart, damit
    die Kompilierung wieder da anfaengt, wo sie aufgehoert hatte')."""
    try:
        JOB_STATE_FILE.write_text(json.dumps(
            {k: _job[k] for k in ("kind", "label", "status", "started", "finished", "args", "resume_draft")},
            ensure_ascii=False), encoding="utf-8")
    except OSError:
        pass


def _find_resume_draft(started):
    """Neuester Draft, der seit Job-Start entstand (= unterbrochene Kompilierung)."""
    if not started:
        return None
    d = OUT / "drafts"
    cand = [f for f in d.glob("*.xml") if f.stat().st_mtime >= started - 1] if d.is_dir() else []
    if not cand:
        return None
    return max(cand, key=lambda f: f.stat().st_mtime).name


def _load_persisted_job():
    """Beim Server-Start: unterbrochenen Job wiederherstellen (Status war 'running'
    -> Server/Rechner starb mittendrin) und als fortsetzbar anbieten."""
    try:
        data = json.loads(JOB_STATE_FILE.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return
    if data.get("status") == "running":
        data["status"] = "error"
        data["finished"] = time.time()
        data["resume_draft"] = _find_resume_draft(data.get("started"))
        data["log"] = "[Server wurde beendet, waehrend dieser Job lief — unten Fortsetzen oder Neu starten]\n"
    if data.get("status") in ("error", "cancelled"):
        with _lock:
            _job.update({k: data.get(k) for k in
                         ("kind", "label", "status", "started", "finished", "args", "resume_draft")})
            _job["log"] = data.get("log", "")
        _persist_job()


def _run_job(kind: str, args: list, label: str, job_id: int):
    global _proc
    env = dict(os.environ)
    env.pop("CLAUDECODE", None)  # UI = eigener Kontext, siehe Docstring
    env["TOM_SHORTCUT_FORCE"] = "1"
    proc = subprocess.Popen(
        [str(TOM_SHORTCUT), kind] + args,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env,
        start_new_session=True,  # eigene Prozessgruppe -> Cancel killt auch claude-Kind
    )
    with _lock:
        _proc = proc
    log_lines = []
    for line in proc.stdout:
        log_lines.append(line)
        with _lock:
            if _job["id"] == job_id:
                _job["log"] = "".join(log_lines[-80:])
    proc.wait()
    with _lock:
        _proc = None
        if _job["id"] == job_id and _job["status"] == "running":
            _job["status"] = "success" if proc.returncode == 0 else "error"
            _job["finished"] = time.time()
        if _job["id"] == job_id and _job["status"] in ("error", "cancelled"):
            _job["resume_draft"] = _find_resume_draft(_job["started"])
        if _job["id"] == job_id and _job["status"] == "success" and kind != "advise":
            # Ergebnis-Draft merken -> UI kann Optimierungsvorschlaege dazu anbieten
            _job["resume_draft"] = _find_resume_draft(_job["started"])
        _persist_job()


def cancel_job() -> bool:
    global _proc
    with _lock:
        if _job["status"] != "running" or _proc is None:
            return False
        try:
            os.killpg(os.getpgid(_proc.pid), signal.SIGTERM)
        except (ProcessLookupError, PermissionError):
            pass
        _job["status"] = "cancelled"
        _job["finished"] = time.time()
        _job["log"] += "\n[abgebrochen durch Nutzer]\n"
    return True


def start_job(kind: str, args: list, label: str) -> bool:
    with _lock:
        if _job["status"] == "running":
            return False
        _job.update({
            "id": _job["id"] + 1, "kind": kind, "label": label,
            "status": "running", "started": time.time(), "finished": None, "log": "",
            "args": list(args), "resume_draft": None,
        })
        job_id = _job["id"]
        _persist_job()
    threading.Thread(target=_run_job, args=(kind, args, label, job_id), daemon=True).start()
    return True


# ------------------------------------------------------------------ Ablage
def list_dir(sub: str, suffix: str):
    d = OUT / sub
    if not d.is_dir():
        return []
    items = []
    for f in sorted(d.iterdir(), key=lambda p: p.stat().st_mtime, reverse=True):
        if f.is_file() and f.name.endswith(suffix):
            items.append({
                "name": f.name, "stem": f.name[: -len(suffix)],
                "mtime": time.strftime("%d.%m. %H:%M", time.localtime(f.stat().st_mtime)),
                "size_kb": round(f.stat().st_size / 1024),
            })
    return items


_installed_cache = {"t": 0.0, "v": set()}


def installed_shortcuts(force=False):
    """`shortcuts list` mit 15s-Cache — der Poll fragt alle 2s, ein Subprozess
    pro Poll waere Verschwendung. force=True fuer Validierungen vor Job-Start."""
    now = time.time()
    if not force and now - _installed_cache["t"] < 15 and _installed_cache["v"]:
        return _installed_cache["v"]
    try:
        out = subprocess.run(["/usr/bin/shortcuts", "list"], capture_output=True,
                             text=True, timeout=15).stdout
        _installed_cache["v"] = set(l.strip() for l in out.splitlines() if l.strip())
        _installed_cache["t"] = now
    except Exception:
        pass
    return _installed_cache["v"]


def state_payload():
    installed = installed_shortcuts()
    signed = list_dir("signed", ".shortcut")
    for s in signed:
        s["installed"] = s["stem"] in installed
    with _lock:
        job = dict(_job)
    return {"job": job, "signed": signed, "drafts": list_dir("drafts", ".xml"),
            "models": MODELS, "engines": engines_available(),
            "installed": sorted(installed), "now": time.strftime("%H:%M:%S")}


# ------------------------------------------------------------------ HTTP
class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="application/json; charset=utf-8"):
        data = body if isinstance(body, bytes) else json.dumps(body, ensure_ascii=False).encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _body(self):
        length = int(self.headers.get("Content-Length", 0) or 0)
        try:
            return json.loads(self.rfile.read(length).decode() or "{}")
        except Exception:
            return {}

    def log_message(self, fmt, *args):  # ruhiges Terminal
        pass

    def do_GET(self):
        if self.path in ("/", "/index.html"):
            html = (UI_DIR / "index.html").read_bytes()
            self._send(200, html, "text/html; charset=utf-8")
        elif self.path == "/api/state":
            self._send(200, state_payload())
        elif self.path == "/api/advice":
            adv = OUT / "advice"
            files = sorted(adv.glob("*.md"), key=lambda f: f.stat().st_mtime, reverse=True) if adv.is_dir() else []
            if not files:
                return self._send(200, {"file": None, "text": ""})
            self._send(200, {"file": files[0].name,
                             "text": files[0].read_text(encoding="utf-8", errors="replace")[:20000]})
        else:
            self._send(404, {"error": "not found"})

    def do_POST(self):
        p = self._body()
        model = (p.get("model") or "claude-sonnet-5").strip()
        if model not in MODELS:
            model = "claude-sonnet-5"
        model_args = ["--model", model] if model else []
        engine = (p.get("engine") or "claude").strip()
        if engine not in engines_available():
            engine = "claude"
        if engine != "claude":
            model_args = ["--engine", engine]  # Modellwahl gilt nur fuer Claude-Engine
        if self.path == "/api/build":
            brief = (p.get("brief") or "").strip()
            youtube = (p.get("youtube") or "").strip()
            if youtube and not youtube.startswith(("https://www.youtube.com/", "https://youtu.be/", "https://youtube.com/")):
                return self._send(400, {"error": "Nur YouTube-URLs erlaubt"})
            if not brief and not youtube:
                return self._send(400, {"error": "Beschreibung oder YouTube-Link fehlt"})
            args = [brief] + model_args
            if youtube:
                args += ["--youtube", youtube]
            name = (p.get("name") or "").strip()
            if name:
                args += ["--name", name]
            label = name or brief[:60] or ("Video-Build: " + youtube[-20:])
            ok = start_job("build", args, label)
            return self._send(200 if ok else 409,
                              {"ok": ok} if ok else {"error": "Es laeuft bereits ein Job"})
        if self.path == "/api/remix":
            draft = (p.get("draft") or "").strip()
            change = (p.get("change") or "").strip()
            if not draft or not change:
                return self._send(400, {"error": "Draft und Aenderungswunsch noetig"})
            src = OUT / "drafts" / draft
            if not src.is_file() or src.suffix != ".xml":
                return self._send(400, {"error": "Draft nicht gefunden"})
            args = [str(src), change] + model_args
            name = (p.get("name") or "").strip()
            if name:
                args += ["--name", name]
            ok = start_job("remix", args, f"Remix: {src.stem}")
            return self._send(200 if ok else 409,
                              {"ok": ok} if ok else {"error": "Es laeuft bereits ein Job"})
        if self.path == "/api/fix":
            name = (p.get("installed") or "").strip()
            change = (p.get("change") or "").strip()
            mode = (p.get("mode") or "fix").strip()
            if mode not in ("fix", "optimize", "extend"):
                mode = "fix"
            if not name:
                return self._send(400, {"error": "Kurzbefehl noetig"})
            # optimize: Vorgabe optional (Hinweis); fix/extend: Pflicht
            if mode != "optimize" and not change:
                return self._send(400, {"error": "Vorgabe/Erweiterung noetig"})
            if name not in installed_shortcuts():
                return self._send(400, {"error": "Nicht installiert: " + name})
            args = [name] + ([change] if change else []) + model_args
            new_name = (p.get("name") or "").strip()
            if new_name:
                args += ["--name", new_name]
            labels = {"fix": "Korrektur", "optimize": "Optimierung", "extend": "Erweiterung"}
            ok = start_job(mode, args, f"{labels[mode]}: {name}")
            return self._send(200 if ok else 409,
                              {"ok": ok} if ok else {"error": "Es laeuft bereits ein Job"})
        if self.path == "/api/import":
            f = OUT / "signed" / (p.get("file") or "")
            if not f.is_file() or f.suffix != ".shortcut" or f.parent != OUT / "signed":
                return self._send(400, {"error": "Datei nicht gefunden"})
            subprocess.Popen(["open", "-a", "Shortcuts", str(f)])
            return self._send(200, {"ok": True})
        if self.path == "/api/run":
            name = (p.get("name") or "").strip()
            if not name or name not in installed_shortcuts():
                return self._send(400, {"error": "Nicht installiert — erst importieren"})
            r = subprocess.run(["/usr/bin/shortcuts", "run", name],
                               capture_output=True, text=True, timeout=120)
            return self._send(200, {"ok": r.returncode == 0,
                                    "stderr": r.stderr.strip()[:300]})
        if self.path == "/api/advise":
            brief = (p.get("brief") or "").strip()
            youtube = (p.get("youtube") or "").strip()
            ctx_installed = (p.get("installed") or "").strip()
            ctx_draft = (p.get("draft") or "").strip()
            if not brief and not youtube and not ctx_installed and not ctx_draft:
                return self._send(400, {"error": "Angabe, Kontext oder YouTube-Link noetig"})
            if youtube and not youtube.startswith(("https://www.youtube.com/", "https://youtu.be/", "https://youtube.com/")):
                return self._send(400, {"error": "Nur YouTube-URLs erlaubt"})
            if ctx_installed and ctx_installed not in installed_shortcuts():
                return self._send(400, {"error": "Nicht installiert: " + ctx_installed})
            if ctx_draft and not (OUT / "drafts" / ctx_draft).is_file():
                return self._send(400, {"error": "Draft nicht gefunden: " + ctx_draft})
            args = [brief] if brief else [""]
            if ctx_installed:
                args += ["--shortcut", ctx_installed]
            elif ctx_draft:
                args += ["--draft", ctx_draft]
            if youtube:
                args += ["--youtube", youtube]
            if model:
                args += ["--model", model]
            label = "Analyse: " + (ctx_installed or ctx_draft or brief[:50] or youtube)
            ok = start_job("advise", args, label)
            return self._send(200 if ok else 409,
                              {"ok": ok} if ok else {"error": "Es laeuft bereits ein Job"})
        if self.path == "/api/export":
            name = (p.get("installed") or "").strip()
            if not name or name not in installed_shortcuts():
                return self._send(400, {"error": "Nicht installiert: " + name})
            env = dict(os.environ)
            env.pop("CLAUDECODE", None)
            r = subprocess.run([str(TOM_SHORTCUT), "export", name],
                               capture_output=True, text=True, timeout=60, env=env)
            if r.returncode != 0:
                return self._send(500, {"error": (r.stderr or r.stdout).strip()[:300]})
            return self._send(200, {"ok": True, "draft": name + ".xml"})
        if self.path == "/api/retry":
            with _lock:
                kind, args, label, status = _job["kind"], list(_job["args"] or []), _job["label"], _job["status"]
            if status not in ("error", "cancelled") or not kind:
                return self._send(409, {"error": "Kein unterbrochener Job zum Neustarten"})
            ok = start_job(kind, args, "Neustart: " + (label or kind))
            return self._send(200 if ok else 409,
                              {"ok": ok} if ok else {"error": "Es laeuft bereits ein Job"})
        if self.path == "/api/resume":
            with _lock:
                draft, status = _job["resume_draft"], _job["status"]
            if status not in ("error", "cancelled") or not draft:
                return self._send(409, {"error": "Kein fortsetzbarer Draft vorhanden"})
            if not (OUT / "drafts" / draft).is_file():
                return self._send(409, {"error": "Draft nicht mehr da: " + draft})
            args = [str(OUT / "drafts" / draft)] + model_args
            ok = start_job("resume", args, "Fortsetzen: " + draft)
            return self._send(200 if ok else 409,
                              {"ok": ok} if ok else {"error": "Es laeuft bereits ein Job"})
        if self.path == "/api/cancel":
            ok = cancel_job()
            return self._send(200 if ok else 409,
                              {"ok": ok} if ok else {"error": "Kein laufender Job"})
        if self.path == "/api/reveal":
            subprocess.Popen(["open", str(OUT)])
            return self._send(200, {"ok": True})
        self._send(404, {"error": "not found"})


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=7461)
    ap.add_argument("--host", default="127.0.0.1",
                    help="0.0.0.0 = LAN-Modus fuer iPhone/iPad (nur im vertrauten Heimnetz! Keine Auth.)")
    args = ap.parse_args()
    _load_persisted_job()
    srv = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"Forge-UI: http://127.0.0.1:{args.port}  (Ablage: {OUT})")
    if args.host != "127.0.0.1":
        try:
            host = subprocess.run(["scutil", "--get", "LocalHostName"], capture_output=True,
                                  text=True, timeout=5).stdout.strip()
            print(f"LAN-Modus AKTIV: http://{host}.local:{args.port}  (iPhone/iPad im selben WLAN)")
            print("ACHTUNG: keine Authentifizierung — nur im vertrauten Heimnetz nutzen.")
        except Exception:
            pass
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nForge-UI beendet.")


if __name__ == "__main__":
    main()
