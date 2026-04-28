#!/usr/bin/env python3
"""
Merge BibTeX sources under src/ into a single derived bibliography.

Input:
  - src/*/*.bib

Output:
  - sphinxSource/_generated/docrepo-expanded.bib
"""

from __future__ import annotations

from pathlib import Path
import bibtexparser
from bibtexparser import Library
from bibtexparser.model import Entry


def write_conflict_report(report_path: Path, conflicts: list[tuple[str, str, str]]) -> None:
    lines: list[str] = []
    lines.append("# Bib merge conflict report")
    lines.append("")
    lines.append(f"Total conflicting keys: {len(conflicts)}")
    lines.append("")

    if not conflicts:
        lines.append("No conflicting duplicate keys found.")
    else:
        lines.append("| Key | First source kept | Conflicting source |")
        lines.append("| --- | --- | --- |")
        for key, first_source, conflict_source in sorted(conflicts):
            lines.append(f"| `{key}` | `{first_source}` | `{conflict_source}` |")

    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def discover_bib_files(src_root: Path) -> list[Path]:
    def order_key(path: Path) -> tuple[int, str]:
        #keep these as the main ones
        rel = path.relative_to(src_root).as_posix()
        if rel == "ivoatex/docrepo.bib":
            return (0, rel)
        if rel == "ivoatex/ivoabib.bib":
            return (1, rel)
        return (2, rel)
    #note that the ** in the glob will not follow symbolic links, so this will not pick up .bib files in linked ivoatex directories (which is what we want)
    files = [p for p in src_root.glob("**/*.bib") if p.is_file() ]
    return sorted(files, key=order_key)


def fingerprint(entry: Entry) -> tuple[str, tuple[tuple[str, str], ...]]:
    # Normalize by entry type and sorted (field, value) pairs for equality checks.
    fields = tuple(sorted((field.key.lower(), field.value.strip()) for field in entry.fields))
    return (entry.entry_type.lower(), fields)


def main() -> int:
    repo_root = Path(__file__).resolve().parents[2]
    src_root = repo_root / "src"
    out_dir = repo_root / "sphinxSource" / "_generated"
    out_bib = out_dir / "docrepo-expanded.bib"
    conflict_report = out_dir / "bib-merge-conflicts.md"

    out_dir.mkdir(parents=True, exist_ok=True)

    bib_files = discover_bib_files(src_root)
    if not bib_files:
        raise RuntimeError(f"No .bib files found under {src_root}")

    merged = Library()
    seen_by_key: dict[str, tuple[tuple[str, tuple[tuple[str, str], ...]], str]] = {}
    conflicts: list[tuple[str, str, str]] = []

    for bib_path in bib_files:
        print(f"processing {bib_path}...")
        library = bibtexparser.parse_file(str(bib_path))
        rel = bib_path.relative_to(repo_root).as_posix()
        for entry in library.entries:
            key = entry.key
            this_fingerprint = fingerprint(entry)
            existing = seen_by_key.get(key)
            if existing is None:
                merged.add(entry)
                seen_by_key[key] = (this_fingerprint, rel)
                continue

            existing_fingerprint, first_source = existing
            if existing_fingerprint != this_fingerprint:
                conflicts.append((key, first_source, rel))
                print(f"warning: conflicting duplicate bib key '{key}' in {rel}; keeping first occurrence")

    bibtexparser.write_file(str(out_bib), merged)
    write_conflict_report(conflict_report, conflicts)
    print(f"merged {len(bib_files)} bib files into {out_bib} ({len(merged.entries)} entries)")
    print(f"wrote conflict report to {conflict_report} ({len(conflicts)} conflicts)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())