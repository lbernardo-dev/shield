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

## Capturas para creatividades

- Toda captura de pantalla destinada a creatividades (App Store, ASO, marketing, redes sociales, previews o vídeos de capturas) debe realizarse con el tema base de MaskID activo.
- Antes de iniciar una captura o un pipeline de capturas, comprobar en la app que está seleccionado el tema base. Desactivar cualquier tema de evento o estacional y verificar el resultado visual antes de conservar o exportar la captura.
- Nunca usar un tema de evento en capturas para creatividades. Si no se puede confirmar que el tema base está activo, detener la captura hasta poder verificarlo.
