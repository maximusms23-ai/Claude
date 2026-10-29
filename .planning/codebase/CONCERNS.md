# Codebase Concerns

**Analysis Date:** 2026-04-08

## Scope: öffentliches Wiki vs. Alt-Vault (`Obsidian/`)

Viele Punkte unten (MkDocs, Personen-Index, `Obsidian/wiki/`-Pfade) betreffen den **im Repo liegenden Alt-Vault** und dessen Research-Wiki. **Toms aktives öffentliches Wiki** liegt unter **`$TOM_VAULT/90_Wiki/`** (MkDocs `docs_dir` im iCloud-Vault) — gleiche Kategorien-Konvention, aber **getrennte Dateibaum** und eigener Pflege-Workflow ([`CLAUDE.md`](../../CLAUDE.md)). Issues zu GitHub Pages / `Obsidian/.github/workflows/` sind nur relevant, wenn ihr **dieses** Repo-Wiki weiter publiziert; für rein privaten Tom-Betrieb über `$TOM_VAULT` sind sie **nice-to-have**, kein Blocker.

## Wiki Content Gaps and Incomplete References

**Stub Index Pages:**
- Issue: Multiple index pages are placeholders with minimal content or no entries
- Files:
  - `Obsidian/wiki/personen/Personen-Index.md` (9 lines) — Empty "Relevante Personen, Autoren und Akteure" section
  - `Obsidian/wiki/konzepte/Konzepte-Index.md` (11 lines) — No concept links listed, only instruction text
- Impact: Users navigating wiki encounter dead-end pages; index discoverability is broken. The 0 count in `wiki/index.md` statistics for Personen contradicts the instruction that indexes auto-populate.
- Fix approach: Populate Konzepte-Index with links to `Ollama`, `GGUF-Quantisierung`, `TurboQuant`. Extract mentioned people from Mannheim article (Christian Specht, Andreas Mix, Andreas Schenk) and populate Personen-Index.

**Unresolved Wikilink Targets:**
- Issue: 36+ wikilinks in `Mannheim.md` reference pages that do not exist (not created yet)
- Files: `Obsidian/wiki/themen/Mannheim.md`
- Examples: `[[Stadtkreis]]`, `[[Baden-Wuerttemberg]]`, `[[Stuttgart]]`, `[[Kunsthalle Mannheim]]`, `[[Nationaltheater Mannheim]]`, `[[Popakademie Baden-Wuerttemberg]]`, etc.
- Impact: Wiki graph is incomplete. Wikilink preview and navigation fail for 36+ references. Reader cannot jump to related concepts. MkDocs roamlinks plugin may generate broken link warnings in builds.
- Fix approach: Either (1) create stub pages for all referenced entities, or (2) replace wikilinks with plain text until pages exist, then relink incrementally. Current approach violates "no unresolved references" principle.

**Source-to-Wiki Inconsistency:**
- Issue: `wiki/quellen/` entries reference `raw/gemma4.md` and `Clippings/Mannheim-Wikipedia.md` but these raw files are in `.gitignore` and not included in the repo
- Files:
  - `Obsidian/wiki/quellen/gemma4-ollama.md` — References `raw/gemma4.md`
  - `Obsidian/wiki/quellen/Mannheim-Wikipedia.md` — Extracted content from clipping
- Impact: Source registry cannot be verified. Readers cannot trace claims back to original `raw/` material. The knowledge is synthesized but source lineage is lost.
- Fix approach: Either commit `raw/` files (remove from `.gitignore`), or store raw links/metadata only without internal file references. Consider using `source_url` field in frontmatter instead.

## Missing Content Sections

**Unlinked Clippings:**
- Issue: Only 1 source is referenced in wiki (`Mannheim-Wikipedia.md`), but `.gitignore` excludes `raw/` folder suggesting more sources may exist
- Files: `Obsidian/.gitignore` excludes `raw/`
- Impact: Web Clipper articles are captured but not ingested into wiki. Work from `Clippings/` is not flowing into the knowledge base.
- Fix approach: Add process to periodically check `Clippings/` for new articles and ingest them via `wiki/quellen/` → `wiki/konzepte/` → `wiki/themen/` workflow.

**Personen Page Missing:**
- Issue: `Personen-Index.md` is empty but Mannheim article references specific people (Christian Specht, Andreas Mix, Andreas Schenk)
- Files: `Obsidian/wiki/personen/Personen-Index.md`
- Impact: Cannot discover people mentioned in wiki. No way to track author/contributor influence. Semantic linking is broken.
- Fix approach: Create person stub pages and populate index with backlinks from thematic articles.

**Output Directory Not Used:**
- Issue: `Obsidian/output/` exists per CLAUDE.md but no slides, plots, reports, or canvas files have been generated
- Files: `Obsidian/output/` (empty)
- Impact: Promised output delivery mechanism (slides, reports, canvas visualizations) is not being used. Users cannot request Marp presentations or matplotlib plots.
- Fix approach: Clarify if `output/` is in-use or deprecated. If active, define trigger rules for when to generate reports/slides.

## Deployment and CI/CD Issues

**GitHub Pages Not Configured:**
- Issue: Workflow is created but next step per PROJEKTE.md is `gh auth refresh -s workflow` and deploy verification
- Files: `Obsidian/.github/workflows/deploy.yml`, `Obsidian/PROJEKTE.md` (status: "aktiv", pending steps)
- Impact: Wiki is not published to GitHub Pages. Users cannot access it via web URL. Build may fail silently without Pages configuration.
- Fix approach: Verify `Settings > Pages` points to `gh-pages` branch. Run `mkdocs gh-deploy` locally once to verify output, then push workflow. Add workflow status badge to README.

**Missing README:**
- Issue: No `README.md` in `Obsidian/` root explaining repo purpose or how to build/serve locally
- Files: `Obsidian/` — no README present
- Impact: New users/clones don't know to run `mkdocs serve` or understand vault structure. Setup friction is high.
- Fix approach: Create `Obsidian/README.md` with quick start (clone, `pip install -r requirements.txt`, `mkdocs serve`), URL to live site, contribution guidelines.

**Missing Python Requirements:**
- Issue: Deploy workflow runs `pip install mkdocs mkdocs-material mkdocs-roamlinks-plugin` but no `requirements.txt` in repo for local development
- Files: `Obsidian/.github/workflows/deploy.yml` — hard-coded dependencies
- Impact: Local development experience is undocumented. Contributors can't easily replicate build environment. If a dependency version breaks, workflow fails without clear signal.
- Fix approach: Create `Obsidian/requirements.txt` with locked versions; update workflow to use it: `pip install -r requirements.txt`.

## Structural and Convention Issues

**Index Statistics Out of Sync:**
- Issue: `wiki/index.md` shows `Personen: 0` and `Themen: 1` but index files suggest more content should exist
- Files: `Obsidian/wiki/index.md`
- Impact: Statistics are static, not automatically updated. Next index update may overwrite them incorrectly.
- Fix approach: Add note to `wiki/index.md` that stats are manually maintained, or create script to auto-count files in each directory.

**Inconsistent Page Naming:**
- Issue: Mix of hyphenated (`Gemma-4-Modelle`, `Gemma-4-Google-AI-Docs`) and space-based names (`Gemme Training`, `PaperclipAI`). Index files use different conventions.
- Files: `Obsidian/wiki/themen/Gemma-4-Modelle.md`, `Obsidian/wiki/projekte/gemme-training.md`, etc.
- Impact: Wikilink syntax is inconsistent. `[[Gemma-4-Modelle]]` vs `[[Gemme Training]]` requires manual tracking. Typos in links break references.
- Fix approach: Standardize on hyphenated format for all multi-word pages. Create redirect/alias handling or use Obsidian frontmatter `aliases` field.

**Wikilink Format Inconsistency:**
- Issue: Some links use display text syntax `[[Gemma-4-Google-AI-Docs|Gemma 4-Modelle - Google AI Docs (Quellenregister)]]`, others use bare `[[Ollama]]`
- Files: Multiple files in `wiki/`
- Impact: Inconsistent reading experience. No clear convention for when to use display text.
- Fix approach: Document in AGENTS.md: use display text only for source/archive links pointing to static quellen entries; use bare links for navigation.

**TODOS.md and PROJEKTE.md Not Committed:**
- Issue: Files are in `.gitignore` and marked for Claude-only management, but repo has no backup of task state
- Files: `.gitignore` excludes `TODOS.md`, `PROJEKTE.md`
- Impact: Task list is ephemeral. If Obsidian vault is lost, task state is gone. Audit trail is missing.
- Fix approach: Consider committing a read-only `ARCHIVE/task-history.md` with completed tasks, or storing active tasks in `wiki/` with an `internal` tag filtered from site build.

## Content Quality Issues

**Single Thema with No Sub-Topics:**
- Issue: Only 1 top-level thema exists (`Mannheim`) with no sub-articles
- Files: `Obsidian/wiki/themen/Themen-Index.md`
- Impact: Wiki is heavily biased toward AI/ML tools (Gemma, Ollama, TurboQuant) which live in `konzepte/` and `projekte/`. Thematic organization is under-developed.
- Fix approach: Consolidate Gemma/Ollama as a thema `Lokale-LLM-Infrastruktur` or `AI-Tools`. Rebalance content across topics.

**Concept Index Missing Entries:**
- Issue: `Konzepte-Index.md` has no links even though 3+ concepts exist (`Ollama`, `GGUF-Quantisierung`, `TurboQuant`)
- Files: `Obsidian/wiki/konzepte/Konzepte-Index.md`
- Impact: Concept discovery is broken. Users must navigate via theme pages or search.
- Fix approach: Add concept links with descriptions to index.

**TurboQuant Integration Issue Not Tracked:**
- Issue: `TurboQuant.md` mentions issue #15051 in Ollama repo (TurboQuant integration) but no tracking page or status update
- Files: `Obsidian/wiki/konzepte/turboquant.md`
- Impact: Feature request is documented but not tracked. If/when issue is resolved, no automatic update mechanism.
- Fix approach: Create `Obsidian/wiki/projekte/ollama-turboquant-integration.md` to track status and link to upstream issue.

## Maintenance and Automation Gaps

**No Health Check Automation:**
- Issue: CLAUDE.md specifies health checks (duplicate detection, broken wikilinks, orphan pages) but no scripts exist to detect these
- Files: CLAUDE.md lines 66-72 describe checks but no CI rule enforces them
- Impact: As wiki grows, duplicates and broken links will accumulate without detection.
- Fix approach: Create `scripts/wiki-lint.py` to check for:
  - Broken wikilinks (parse `[[X]]` and verify file exists)
  - Duplicate frontmatter titles
  - Orphan pages (no inbound links)
  - Missing index entries

**No Duplicate Detection Process:**
- Issue: AGENTS.md mandates "no doppelten Seiten anlegen" but no mechanism detects duplicates
- Files: `AGENTS.md` line 26 — manual rule only
- Impact: Risk of creating `Gemma 4`, `Gemma-4`, `gemma4` variants accidentally.
- Fix approach: Add pre-commit hook to check for title duplicates across `wiki/` directory.

**Deploy Workflow Not Tested:**
- Issue: Workflow syntax is correct but never run. No validation that `mkdocs gh-deploy --force` will succeed
- Files: `.github/workflows/deploy.yml`
- Impact: First push may fail with unclear error. If build breaks, no rollback mechanism.
- Fix approach: Test workflow locally: `mkdocs build` to verify no errors. Add `mkdocs serve` health check to workflow.

## Obsidian Configuration and Sync Issues

**Obsidian App Config Committed:**
- Issue: `.obsidian/` directory is committed (not gitignored), contains `app.json`, `appearance.json`, `core-plugins.json`, `workspace.json`
- Files: `.obsidian/` directory
- Impact: App settings are project-specific. Each user's Obsidian setup may conflict. Theme/plugin configs are baked into repo.
- Fix approach: Add `.obsidian/` to `.gitignore` except for vault configuration that must be shared (if any). Each user runs Obsidian independently.

**No Plugin/Theme Lockfile:**
- Issue: Obsidian plugins and themes may be installed locally but not tracked in repo
- Files: `.obsidian/` (unversioned state)
- Impact: Contributors cannot replicate exact Obsidian environment. Plugin versions drift.
- Fix approach: If using Obsidian community plugins, document in README which plugins are recommended (web clipper, etc.) and create `obsidian-plugins.md` list.

## Data Quality Issues

**Umlaut Consistency:**
- Issue: Mix of entity names with/without umlauts: `Koeln` vs `Köln`, `Mannheim` vs inconsistent in raw wiki articles
- Files: `wiki/themen/Mannheim.md` uses some umlauts but some content may be stripped in Clippings
- Impact: Search may miss results due to encoding differences. Wikilinks with different umlaut states won't match.
- Fix approach: Standardize on UTF-8 with full umlauts in all wiki files. Ensure Clippings are processed to normalize text.

**Twin Cities Section Incomplete:**
- Issue: Mannheim article lists 10 twin cities in a table but these are stub wikilinks with no target pages
- Files: `wiki/themen/Mannheim.md` (lines with `[[Beyoglu]]`, `[[Bydgoszcz]]`, etc.)
- Impact: 10+ broken wikilinks clutter the page. Readers cannot navigate to twin city info.
- Fix approach: Either (1) remove wikilinks and use plain text for twin cities, or (2) create stub pages for each city, or (3) link to Wikipedia directly.

---

*Concerns audit: 2026-04-08*
