# AGENTS Guide for `multidoc`

## Purpose and scope
- This repo builds a single Sphinx site that integrates multiple IVOA standards; it does **not** replace official publishing (see `README.md`).
- Most source standards live in `src/*` as git submodules; this repo mainly controls transformation and presentation.

## Big-picture architecture
- Input layer: LaTeX standards in `src/<Doc>/<Doc>.tex` (plus one HTML source, `src/UWS/UWS.html`).
- Transform layer: root `Makefile` runs `pandoc` with Lua filters from `pandocCustomization/` and metadata from `util.mk`.
- Output layer: generated RST lands in `sphinxSource/idoc/<Doc>/<Doc>.rst`; Sphinx builds HTML into `build/html/`.
- Site shell: `sphinxSource/index.rst` uses `idoc/*/*` glob to include all generated documents.

## Core build workflow
- Primary command: `make` (root `Makefile`) -> target `doSphinx`.
- Clean rebuild: `make clean doSphinx`.
- Recover submodule state after build symlink rewiring: `make restore_ivoatex`.
- Refresh submodule revisions: `git submodule update --recursive --remote`.
- Mac note: GNU Make 4.x is required (documented in `README.md`).

## Transformation pipeline details
- `dolink_ivoatex` rewires each `src/<DOCNAME>/ivoatex` to `src/ivoatex` and symlinks `ivoa.cls`; this is intentional.
- `util.mk` derives `docMeta.yaml` from each standard Makefile vars (`DOCNAME`, `DOCVERSION`, `DOCTYPE`, `DOCDATE`).
- `latest_versions.py` generates `pandocCustomization/latest_versions_map.yaml` from `src/ivoatex/docrepo.bib` + `src/*/Makefile` DOCNAMEs.
- Pandoc filters used in order (`Makefile`):
  - `relink-ivoa-citations.lua`: maps `\\cite...` to internal `:doc:` links when bibkey maps to another standard.
  - `fix_internal_refs.lua`: prefixes IDs/refs with `DOCNAME:` for global uniqueness across all docs.
  - `number-sections.lua`: applies hierarchical numbering and appendix A/B/C mode.

## Sphinx-specific conventions
- Main config is `sphinxSource/conf.py`; theme is `sphinx_wagtail_theme`.
- Bibliography is centralized with `sphinxcontrib-bibtex` and `../src/ivoatex/docrepo.bib`.
- Custom pybtex style `IvoaStyle` labels entries as `<ivoa_docname><version>` (see `conf.py`).

## Editing boundaries for agents
- Treat `src/*` as upstream-owned standards; content cannot be edited directly.
- Prefer edits in root `Makefile`, `util.mk`, `pandocCustomization/*`, and `sphinxSource/*` for integration behavior.
- Treat `build/` outputs and generated `sphinxSource/idoc/*/*.rst` as derived artifacts; regenerate instead of hand-editing.
- If adding a new standard, follow `README.md`: add submodule, ensure transform target exists, and ensure it is included by site toctree.

## Known repo-specific quirks
- `Makefile` currently comments that HTML-source conversion path is "not working"; `htmlsource := UWS` exists but is not in `ALLSP`.
- Build mutates submodule working trees via symlinks; `git` operations can fail until `make restore_ivoatex` is run.
- Internal link correctness depends on DOCNAME matching standard names used in mapping and directory layout.

