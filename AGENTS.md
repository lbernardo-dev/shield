# Agent workflow rules

- Use `scripts/task.sh` as the single task entrypoint.
- Use `AGENT_NAME` when claiming and completing work.
- Keep committed task backlog in `tasks/TASKS.md`.
- Put deeper task notes in `tasks/details/<id>.md`.

## Zero temporary files policy

- **Mandatory User Confirmation**: At the end of every work session, after all builds, tests, archives and tasks finish, the agent **MUST ALWAYS ask the user for confirmation** before running any cleanup of temporary files, logs, AppleDouble (`._*`) sidecars, and build caches.
- Once confirmed by the user:
  - Run `./scripts/clean.sh --all` to purge AppleDouble (`._*`) files, `.DS_Store`, and build/intermediate caches (`build/`, `Shield.xcodeproj/build`, `.asc/video-derived-data`).
  - Or run `scripts/cleanup_temporaries.sh --dry-run`, review candidate IDs, and move approved candidates to Trash with `scripts/cleanup_temporaries.sh --apply ...`.
- Preserve `.asc/artifacts/` release artifacts, source, metadata, documentation, credentials and global Xcode data. Never empty the Trash automatically.

Task workflow commands:
- `scripts/task.sh plan <slug> --scope "..." --files "..." --note "..."`
- `AGENT_NAME=CODEX scripts/task.sh claim <number|id> --note "Starting work"`
- `AGENT_NAME=CODEX scripts/task.sh done <number|id> --note "Finished + build/test status"`
- `scripts/task.sh summary --last-24h`
