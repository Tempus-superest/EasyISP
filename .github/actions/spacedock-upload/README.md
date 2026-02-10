# spacedock-upload
A GitHub action for uploading to spacedock

## EasyISP Vendored Copy

- Source upstream: https://github.com/KSP2Community/spacedock-upload
- Upstream issue motivating vendoring: https://github.com/KSP2Community/spacedock-upload/issues/2
- Provenance: EasyISP previously pinned upstream action to `v1.0.1`.
- Local patch date: 2026-02-10.

Why vendored:

- Upstream shell interpolation can mishandle passwords containing shell metacharacters (for example `*`) unless treated literally.
- EasyISP vendors this action to keep SpaceDock auth reliable.

Local patch summary:

- Quote password interpolation used for URI encoding in login.
- Preserve literal-safe handling through the login curl path.
- Accept changelog as direct string content (not a filename path) so workflow can pass `github.event.release.body` directly.

Maintenance note:

- Do not replace this with upstream `uses: KSP2Community/spacedock-upload@...` until upstream fix is released and validated in this repo with special-character secrets.
- If syncing upstream changes, re-run a published-release test and confirm SpaceDock auth/upload succeeds.
