# Repository Maintenance and File Hygiene Rule

## Scope and Context
This repository is stored on an external storage volume (`/Volumes/SSD Externo`), formatted as exFAT. In this filesystem environment, macOS generates AppleDouble companion files (`._<filename>`) to store extended file attributes and Finder metadata. In addition, builds create derived data, caches, and logs, and macOS creates `.DS_Store` files.

## Strict Rules

1. **Never Commit Temporary / Metadata Files**:
   - `._*` (AppleDouble files)
   - `.DS_Store`
   - `__pycache__/` or `*.pyc`
   - `Thumbs.db`, `Desktop.ini`
   - Editor swap or backup files (`*.swp`, `*~`, `*.bak`, `*.tmp`)
   - Intermediate build outputs (`build/`, `Shield.xcodeproj/build`, `.asc/video-derived-data`)

2. **Mandatory User Confirmation at Session End**:
   - At the end of every work session (after tasks, builds, tests, archives, or reviews are completed), the agent **MUST ALWAYS ask the user for confirmation** before executing the cleanup of temporary files, logs, `._*` sidecars, and build caches.
   - The agent must NEVER perform silent, unconfirmed cleanups at the close of a session.
   - Example prompt to user: *"¿Deseas que proceda ahora con la limpieza de archivos temporales, cachés de compilación y archivos AppleDouble (`._*`) antes de finalizar la sesión?"*

3. **Cleanup Execution Workflow**:
   - Once the user confirms, execute:
     ```bash
     ./scripts/clean.sh --all
     ```
     Or use `scripts/cleanup_temporaries.sh --dry-run` and review/apply candidate IDs.
   - Run `dot_clean -m .` to ensure the exFAT tree is clean.
   - Check `git status` and `git fsck` to ensure the repository tree and index remain completely clean and without errors.

4. **Preservation Policy**:
   - Always preserve `.asc/artifacts/` release artifacts (archives, IPAs, packaging logs).
   - Preserve source code, project files, credentials, metadata, and documentation.
   - Never automatically empty the macOS Trash.

5. **Git Hooks**:
   - Ensure `git config core.hooksPath .githooks` is active.
   - The `.githooks/pre-commit` hook automatically blocks commits containing prohibited temporary files.
