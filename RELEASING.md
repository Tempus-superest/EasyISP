# Releasing EasyISP

## Summary

EasyISP release automation uses two workflows:

- `.github/workflows/release.yml`: primary workflow for version sync, package, tag, and GitHub Release.
- `.github/workflows/spacedock.yml`: SpaceDock upload workflow triggered only on `release: published`.

`VERSION` is authoritative. All release metadata is derived from it.

## Source of Truth

- `VERSION` contains exactly `vX.Y.Z`.
- `scripts/sync-version.sh` derives `X.Y.Z` and syncs:
  - `EasyISP.version` `VERSION` fields (`MAJOR`, `MINOR`, `PATCH`)
  - `EasyISP.version` `DOWNLOAD` URL
  - `README.md` `Current Version` line/link

## Release Mode

`vars.RELEASE_MODE` controls draft vs publish behavior:

- `draft` (default): create/update a draft GitHub Release for `vX.Y.Z`.
- `publish`: create/update the same `vX.Y.Z` release, upload assets, then publish it.

Tag naming is the same in both modes: `vX.Y.Z`.

## Workflow Behavior (`release.yml`)

Triggers:

- Push to `main`
- Manual `workflow_dispatch`

Process:

1. Parse and validate `VERSION` (`^v[0-9]+\.[0-9]+\.[0-9]+$`).
2. Validate `RELEASE_MODE` (`draft` or `publish`).
3. Gate on version change:
   - Push: continue only if `VERSION` changed in the push range.
   - Manual dispatch: allowed without a version diff.
4. If no version change on push: exit success with a skip message.
5. Check for overlap:
   - If tag exists: exit success and skip release work.
   - If release exists: exit success and skip release work.
6. Run `scripts/sync-version.sh`.
7. Commit/push `EasyISP.version` and `README.md` only when sync changed them.
8. Re-check overlap (race guard). If detected, skip remaining release steps cleanly.
9. Package with `.github/scripts/package.sh --version X.Y.Z`.
10. Create and push tag `vX.Y.Z`.
11. Create draft GitHub Release for `vX.Y.Z`.
12. Upload `EasyISP-vX.Y.Z.zip`.
13. If `RELEASE_MODE=publish`, publish the release; otherwise keep draft.

## SpaceDock Upload (`spacedock.yml`)

Trigger:

- `release` event type `published`

Result:

- Draft releases do not trigger SpaceDock upload.
- Published releases trigger SpaceDock upload once the release is actually published.

The workflow uses the vendored action at `.github/actions/spacedock-upload`.

## Credential Handling (Do Not Regress)

SpaceDock login must use literal multipart fields:

- `curl --form-string "username=$USERNAME"`
- `curl --form-string "password=$PASSWORD"`

Do not URI-encode username/password. Encoding breaks login for some credential values.

## How to Cut a Release

1. Edit `VERSION` to the new tag version (for example `v1.3.1`).
2. Commit and merge to `main`.
3. Ensure `vars.RELEASE_MODE` is set as intended:
   - `draft` to create a draft release.
   - `publish` to publish immediately (and trigger SpaceDock).
4. Let `release.yml` perform sync, package, tag, and release steps.
5. Confirm the release state and asset on GitHub.
6. If published, confirm SpaceDock upload workflow succeeded.

## Clean Skip Rules

These are expected success paths, not failures:

- `VERSION` unchanged on push -> skip release.
- Tag already exists -> skip release.
- Release already exists -> skip release.

These guards prevent duplicate tags, duplicate assets, and duplicate SpaceDock uploads.
