#!/usr/bin/env python3
"""Sanitize n8n workflow exports before publishing.

Usage:
    python tools/sanitize_workflows.py INPUT.json [more.json ...] --out workflows/ [--redact-file terms.txt]

--renumber "1=1A,7=6,8=7,9=8": renames "Workflow N" references in names, notes and logs in ONE pass
(old=new, no chaining), for when workflows were renumbered after the export.

--redact-file: private text file (keep it OUT of the repo) with one "real term=>replacement" per line,
e.g. company, client and brand names that must not appear. Matching is case-insensitive; longer terms first.

Single export (one workflow object), a list of workflows, or {"data": [...]} are supported.
It removes/replaces: credential IDs, Google Drive/Sheets IDs, webhook IDs, instance IDs, pinData,
emails, domains/IPs and NIF-like strings, and writes one JSON per workflow.
ALWAYS review the result (see the report at the end) and grep for real names before committing.
"""
import argparse, json, re, sys, unicodedata
from pathlib import Path

EMAIL = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
IP = re.compile(r"\b\d{1,3}(?:\.\d{1,3}){3}\b")
NIF = re.compile(r"\b[XYZ]?\d{7,8}[A-Z]\b")
GOOGLE_ID = re.compile(r"^=?[A-Za-z0-9_-]{25,}$")
UUID = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
DOMAIN = re.compile(r"https?://[A-Za-z0-9.-]+\.(?:es|com|net|org|io)[^\s\"']*")
ID_KEYS = {"documentId", "folderId", "fileId", "sheetId", "spreadsheetId", "driveId"}
DROP_KEYS = {"pinData", "webhookId", "instanceId", "versionId", "triggerCount", "shared", "homeProject", "createdAt", "updatedAt"}
leftovers = []
REDACT = []  # (compiled regex, replacement)
RENUM = {}
RENUM_RX = re.compile(r"Workflow (\d+)(?![0-9A-Za-z])")


def scrub_str(s: str) -> str:
    for rx, rep in REDACT:
        s = rx.sub(rep, s)
    if RENUM:
        s = RENUM_RX.sub(lambda m: "Workflow " + RENUM.get(m.group(1), m.group(1)), s)
    if GOOGLE_ID.match(s) and not UUID.match(s) and re.search(r"\d", s) and re.search(r"[A-Za-z]", s):
        return "REPLACE_WITH_YOUR_ID"  # Drive/Sheets/folder ID in any field (also "=<id>")
    s = EMAIL.sub("user@example.com", s)
    s = IP.sub("203.0.113.1", s) if not re.fullmatch(r"\d+\.\d+\.\d+", s) else s
    s = NIF.sub("X0000000X", s)
    s = DOMAIN.sub("https://example.com/path", s)
    return s


def walk(o, key=None):
    if isinstance(o, dict):
        out = {}
        for k, v in o.items():
            if key == "connections":
                k = scrub_str(k)  # node names are the keys here: must stay in sync with node["name"]
            if k in DROP_KEYS:
                continue
            if k == "credentials" and isinstance(v, dict):
                out[k] = {t: {"id": "REPLACE_ME", "name": f"{t} (replace)"} for t in v}
                continue
            if k == "tags" and isinstance(v, list):
                out[k] = [{"name": scrub_str(t.get("name", ""))} for t in v if isinstance(t, dict)]
                continue
            if k in ID_KEYS:
                out[k] = placeholder_for(v, k)
                continue
            out[k] = walk(v, k)
        return out
    if isinstance(o, list):
        return [walk(x, key) for x in o]
    if isinstance(o, str):
        return scrub_str(o)
    return o


def placeholder_for(v, k):
    tag = f"REPLACE_WITH_YOUR_{k.upper()}"
    if isinstance(v, dict):  # resource locator
        nv = dict(v)
        for f in ("value", "cachedResultName", "cachedResultUrl"):
            if f in nv:
                nv[f] = tag if f == "value" else "(replace)"
        return nv
    return tag


def report(o, path=""):
    if isinstance(o, dict):
        for k, v in o.items():
            report(v, f"{path}.{k}")
    elif isinstance(o, list):
        for i, v in enumerate(o):
            report(v, f"{path}[{i}]")
    elif isinstance(o, str):
        if GOOGLE_ID.match(o) and not UUID.match(o) and not o.startswith("REPLACE"):
            leftovers.append((path, "long id-like string", o[:30]))
        if EMAIL.search(o) and "example.com" not in o:
            leftovers.append((path, "email", o[:40]))


def load(p):
    d = json.loads(Path(p).read_text(encoding="utf-8"))
    if isinstance(d, dict) and "data" in d and isinstance(d["data"], list):
        d = d["data"]
    return d if isinstance(d, list) else [d]


def slug(name):
    name = unicodedata.normalize("NFKD", name).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_") or "workflow"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("inputs", nargs="+")
    ap.add_argument("--out", default="workflows")
    ap.add_argument("--redact-file")
    ap.add_argument("--renumber", default="")
    a = ap.parse_args()
    for pair in filter(None, a.renumber.split(",")):
        o, n = pair.split("=")
        RENUM[o.strip()] = n.strip()
    if a.redact_file:
        pairs = []
        for line in Path(a.redact_file).read_text(encoding="utf-8").splitlines():
            if "=>" in line and not line.startswith("#"):
                t, r = line.split("=>", 1)
                pairs.append((t.strip(), r.strip()))
        for t, r in sorted(pairs, key=lambda x: -len(x[0])):
            REDACT.append((re.compile(re.escape(t), re.I), r))
    out = Path(a.out); out.mkdir(parents=True, exist_ok=True)
    n = 0
    for f in a.inputs:
        for wf in load(f):
            clean = walk(wf)
            clean["active"] = False
            report(clean)
            (out / f"{slug(clean.get('name', 'workflow'))}.json").write_text(
                json.dumps(clean, indent=2, ensure_ascii=False), encoding="utf-8")
            n += 1
    print(f"{n} workflow(s) written to {out}/")
    if leftovers:
        print("\nREVIEW MANUALLY:")
        for p, why, s in leftovers:
            print(f"  {why}: {p} -> {s}")
    print("\nNext: grep the output for real owner names, street names and company names.")


if __name__ == "__main__":
    sys.exit(main())
