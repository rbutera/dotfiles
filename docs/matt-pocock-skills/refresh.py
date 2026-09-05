#!/usr/bin/env python3
"""Import an explicit upstream revision as ordinary chezmoi source files."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs/matt-pocock-skills/manifest.json"
REPOSITORY = "https://github.com/mattpocock/skills.git"
RENAMES = {"tdd": "matt-tdd", "teach": "matt-teach"}


def git(checkout, *args):
    return subprocess.check_output(
        ["git", "-C", str(checkout), *args], text=True
    ).strip()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def adapt(data, filename):
    if not filename.endswith((".md", ".yaml", ".yml")):
        return data
    text = data.decode()
    for old, new in RENAMES.items():
        text = re.sub(rf"(?m)^name: {old}$", f"name: {new}", text)
        text = re.sub(rf"([/$]){old}(?![\w-])", rf"\g<1>{new}", text)
    if filename == "agents/openai.yaml":
        text = text.replace('display_name: "TDD"', 'display_name: "Matt TDD"')
        text = text.replace('display_name: "Teach"', 'display_name: "Matt Teach"')
    return text.encode()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("revision", help="Upstream commit, tag, or branch to import")
    parser.add_argument("--checkout", type=Path, help="Use an existing clean clone")
    parser.add_argument("--check", action="store_true", help="Verify without writing")
    args = parser.parse_args()
    previous = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {"files": {}}
    for name, checksum in previous["files"].items():
        path = ROOT / name
        if not path.is_file() or digest(path.read_bytes()) != checksum:
            raise SystemExit(f"Local modification: {path}. Reconcile it before refreshing.")

    with tempfile.TemporaryDirectory(prefix="matt-skills-") as temporary:
        checkout = args.checkout
        if checkout is None:
            checkout = Path(temporary)
            subprocess.run(["git", "clone", "--quiet", REPOSITORY, str(checkout)], check=True)
            git(checkout, "checkout", "--quiet", args.revision)
        if git(checkout, "status", "--porcelain"):
            raise SystemExit("Upstream checkout must be clean.")
        commit = git(checkout, "rev-parse", "HEAD")
        if commit != git(checkout, "rev-parse", f"{args.revision}^{{commit}}"):
            raise SystemExit("Checkout HEAD does not match the requested revision.")

        files = {}
        skills = {}
        for entry in sorted((checkout / "skills").glob("*/*/SKILL.md")):
            source = entry.parent
            name = RENAMES.get(source.name, source.name)
            if name in skills:
                raise SystemExit(f"Duplicate skill: {name}")
            skills[name] = str(source.relative_to(checkout))
            for path in sorted(source.rglob("*")):
                if path.is_symlink():
                    raise SystemExit(f"Review upstream symlink before importing: {path}")
                if not path.is_file():
                    continue
                relative = path.relative_to(source)
                executable = bool(path.stat().st_mode & 0o111)
                target = relative.with_name(("executable_" if executable else "") + relative.name)
                destination = f"dot_agents/skills/{name}/{target.as_posix()}"
                files[destination] = (adapt(path.read_bytes(), relative.as_posix()), executable)
        files["dot_agents/skills/matt-pocock.LICENSE"] = ((checkout / "LICENSE").read_bytes(), False)
        if not skills:
            raise SystemExit("No skills found; review upstream layout.")
        for name in files.keys() - previous["files"].keys():
            if (ROOT / name).exists():
                raise SystemExit(f"Refusing to overwrite an unowned file: {name}")

        manifest = {
            "repository": REPOSITORY,
            "commit": commit,
            "renames": RENAMES,
            "skills": skills,
            "files": {name: digest(data) for name, (data, _) in sorted(files.items())},
        }
        if args.check:
            if previous != manifest:
                raise SystemExit("Imported snapshot differs from the requested upstream revision.")
            for name, (_, executable) in files.items():
                if bool((ROOT / name).stat().st_mode & 0o111) != executable:
                    raise SystemExit(f"Executable mode differs: {name}")
            print(f"Verified {len(skills)} skills, {len(files)} files at {commit}")
            return

        for name in previous["files"].keys() - files.keys():
            (ROOT / name).unlink()
        for name, (data, executable) in files.items():
            path = ROOT / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            path.chmod(0o755 if executable else 0o644)
        MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n")
        print(f"Imported {len(skills)} skills, {len(files)} files at {commit}")


if __name__ == "__main__":
    main()
