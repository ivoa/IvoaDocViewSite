#!/usr/bin/env python3
"""Generate a Markdown report of top-level src submodule upstream deltas.

This script reports, for each top-level submodule under src/*:
- pinned commit (current submodule HEAD)
- upstream ref and commit
- number of upstream commits available
- short list of upstream commits since the pinned commit
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
import re
import subprocess
from typing import Optional


@dataclass
class CmdResult:
    returncode: int
    stdout: str
    stderr: str


@dataclass
class SubmoduleReport:
    path: str
    source_repo_url: str
    pinned_short: str
    upstream_ref: str
    upstream_short: str
    ahead_count: int
    commits: list[str]
    fetch_error: Optional[str] = None


def run_cmd(args: list[str], cwd: Path) -> CmdResult:
    proc = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    return CmdResult(proc.returncode, proc.stdout.strip(), proc.stderr.strip())


def must_git(args: list[str], cwd: Path) -> str:
    res = run_cmd(["git", *args], cwd)
    if res.returncode != 0:
        raise RuntimeError(f"{cwd}: git {' '.join(args)} failed: {res.stderr}")
    return res.stdout


def discover_top_level_src_submodules(repo_root: Path) -> list[Path]:
    src = repo_root / "src"
    if not src.exists() or not src.is_dir():
        return []

    submodules: list[Path] = []
    for item in sorted(src.iterdir()):
        if not item.is_dir():
            continue
        # In submodules, .git is usually a file; still allow directory too.
        if (item / ".git").exists():
            submodules.append(item)
    return submodules


def detect_upstream_ref(submodule_path: Path) -> str:
    tracking = run_cmd(
        ["git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"],
        submodule_path,
    )
    if tracking.returncode == 0 and tracking.stdout:
        return tracking.stdout

    remote = run_cmd(["git", "remote", "show", "origin"], submodule_path)
    if remote.returncode == 0 and remote.stdout:
        for line in remote.stdout.splitlines():
            line = line.strip()
            if line.startswith("HEAD branch:"):
                branch = line.split(":", 1)[1].strip()
                return f"origin/{branch or 'main'}"

    return "origin/main"


def detect_origin_url(submodule_path: Path) -> str:
    origin_url = run_cmd(["git", "remote", "get-url", "origin"], submodule_path)
    if origin_url.returncode == 0 and origin_url.stdout:
        return normalize_repo_url(origin_url.stdout)
    return "unknown"


def normalize_repo_url(url: str) -> str:
    """Normalize common git remote URL forms to cleaner HTTPS repository URLs."""
    value = url.strip()
    if not value:
        return "unknown"

    # git@github.com:org/repo.git -> https://github.com/org/repo
    scp_like = re.match(r"^git@([^:]+):(.+)$", value)
    if scp_like:
        host, path = scp_like.groups()
        return f"https://{host}/{path.removesuffix('.git')}"

    # ssh://git@github.com/org/repo(.git) -> https://github.com/org/repo
    ssh_like = re.match(r"^ssh://git@([^/]+)/(.+)$", value)
    if ssh_like:
        host, path = ssh_like.groups()
        return f"https://{host}/{path.removesuffix('.git')}"

    # https://host/org/repo.git -> https://host/org/repo
    if value.startswith("http://") or value.startswith("https://"):
        return value.removesuffix(".git")

    return value


def build_report_for_submodule(
    repo_root: Path,
    submodule_path: Path,
    max_commits: int,
    fetch: bool,
) -> SubmoduleReport:
    rel_path = submodule_path.relative_to(repo_root).as_posix()
    source_repo_url = detect_origin_url(submodule_path)

    if fetch:
        fetch_res = run_cmd(["git", "fetch", "--quiet", "origin"], submodule_path)
        if fetch_res.returncode != 0:
            return SubmoduleReport(
                path=rel_path,
                source_repo_url=source_repo_url,
                pinned_short="?",
                upstream_ref="origin/main",
                upstream_short="?",
                ahead_count=0,
                commits=[],
                fetch_error=fetch_res.stderr or "unable to fetch origin",
            )

    pinned = must_git(["rev-parse", "HEAD"], submodule_path)
    pinned_short = must_git(["rev-parse", "--short", pinned], submodule_path)

    upstream_ref = detect_upstream_ref(submodule_path)
    upstream_short_res = run_cmd(["git", "rev-parse", "--short", upstream_ref], submodule_path)
    upstream_short = upstream_short_res.stdout if upstream_short_res.returncode == 0 else "?"

    ahead_res = run_cmd(["git", "rev-list", "--count", f"{pinned}..{upstream_ref}"], submodule_path)
    ahead_count = int(ahead_res.stdout) if ahead_res.returncode == 0 and ahead_res.stdout.isdigit() else 0

    commits: list[str] = []
    if ahead_count > 0:
        log_res = run_cmd(
            [
                "git",
                "--no-pager",
                "log",
                "--no-merges",
                "--pretty=format:  - %h %s (%an, %ad)",
                "--date=short",
                f"{pinned}..{upstream_ref}",
            ],
            submodule_path,
        )
        if log_res.returncode == 0 and log_res.stdout:
            commits = [line for line in log_res.stdout.splitlines() if line][:max_commits]

    return SubmoduleReport(
        path=rel_path,
        source_repo_url=source_repo_url,
        pinned_short=pinned_short,
        upstream_ref=upstream_ref,
        upstream_short=upstream_short,
        ahead_count=ahead_count,
        commits=commits,
    )


def render_markdown(reports: list[SubmoduleReport]) -> str:
    lines: list[str] = []
    lines.append("# Top-level src submodule upstream delta report")
    lines.append("")
    lines.append("Generated: " + datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"))
    lines.append("")

    if not reports:
        lines.append("No top-level submodules found under `src/*`.")
        lines.append("")
        return "\n".join(lines)

    for r in reports:
        lines.append(f"## {r.path}")
        lines.append(f"- source: `{r.source_repo_url}`")
        if r.fetch_error:
            lines.append(f"- status: unable to fetch `origin` ({r.fetch_error})")
            lines.append("")
            continue

        lines.append(f"- pinned: `{r.pinned_short}`")
        lines.append(f"- upstream: `{r.upstream_ref}` (`{r.upstream_short}`)")

        if r.ahead_count == 0:
            lines.append("- status: up to date")
        else:
            lines.append(f"- status: {r.ahead_count} upstream commit(s) available")
            lines.append("- new commits:")
            if r.commits:
                lines.extend(r.commits)
            else:
                lines.append("  - (unable to read commit list)")

        lines.append("")

    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path.cwd(),
        help="Repository root that contains src/ (default: current working directory)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("submodules-gitstatus.md"),
        help="Output Markdown file path (default: submodules-gitstatus.md)",
    )
    parser.add_argument(
        "--max-commits",
        type=int,
        default=40,
        help="Maximum commits to list per submodule (default: 40)",
    )
    parser.add_argument(
        "--no-fetch",
        action="store_true",
        help="Do not fetch origin before comparing",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    repo_root = args.repo_root.resolve()
    out_path = args.output if args.output.is_absolute() else (repo_root / args.output)

    submodules = discover_top_level_src_submodules(repo_root)
    reports = [
        build_report_for_submodule(
            repo_root=repo_root,
            submodule_path=sm,
            max_commits=max(1, args.max_commits),
            fetch=(not args.no_fetch),
        )
        for sm in submodules
    ]

    markdown = render_markdown(reports)
    out_path.write_text(markdown + "\n", encoding="utf-8")
    print(f"Wrote {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

