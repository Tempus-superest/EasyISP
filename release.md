# EasyISP Release Process

## Overview
- Changes are first merged into `main`, and the release automation described below runs automatically.
- The Git tag (`vX.Y.Z`), GitHub release, and EasyISP metadata must all carry the same version number, which is the single source of truth for downstream consumers.

## Contribution and Review Requirements
- All work happens through pull requests targeting `main`; no direct pushes to `main` are permitted.
- Every PR needs:
  - Repository owner approval before merging.
  - Codex Code Review and Copilot reviews to be executed and any findings resolved.
- Contributors should verify status checks pass and that workflows reference the most recent automations before requesting merge.

## Release Lifecycle
1. **Version detection**: The workflow runs `.github/scripts/get-version.sh` to determine the next `vX.Y.Z` tag and `EasyISP.version` entries.
2. **Tag fetch**: The repo fetches tags to ensure retries can detect existing releases.
3. **Validation**: The workflow asserts that `EasyISP.version`’s `DOWNLOAD` field equals `https://github.com/Tempus-superest/EasyISP/releases/tag/vX.Y.Z`.
4. **Packaging**: The manifest-driven ZIP archive `EasyISP-vX.Y.Z.zip` is built to guarantee the canonical `GameData/EasyISP` layout along with `README.md`.
5. **Tag creation**: If `vX.Y.Z` does not already exist, a lightweight Git tag is created locally and pushed to GitHub *before* the release creation step. This preserves the requirement that the release URL resolves immediately.
6. **Release creation**: The workflow always runs `gh release create "$tag" --generate-notes --draft`, so the release starts in draft state regardless of the `RELEASE_MODE` variable.
7. **Asset upload**: The zip is uploaded to the draft release via `gh release upload`.
8. **Optional publication**: When `RELEASE_MODE=publish`, the workflow runs `gh release edit "$tag" --draft=false` after the ZIP upload completes; this guarantees that downstream consumers (SpaceDock, CKAN) only see fully populated releases.

## Draft vs. Published Releases
- Draft releases are intentional: they provide a controlled point where assets exist but distribution has not yet begun.
- Publishing the release—manually or via `RELEASE_MODE=publish`—is the moment downstream systems are allowed to consume the release.
- Asset upload happens before publication so that any downstream workflow triggered by the published release (SpaceDock, CKAN) can safely download the artifact.
- Release drafts can be published from the GitHub UI once you verify the notes and assets.

## Distribution Targets

### GitHub Releases
- The GitHub release holds the authoritative ZIP artifact and the changelog (release body).
- `README.md` is included in this ZIP and remains the user-facing documentation source.
- Release notes become the changelog that SpaceDock and CKAN rely on.

### SpaceDock
- The SpaceDock workflow (`.github/workflows/spacedock.yml`) only runs when GitHub emits a `release: published` event; it does **not** run on draft creation or PR merges.
- It:
  1. Downloads `EasyISP-vX.Y.Z.zip` from the published release.
  2. Uses the Git tag (`vX.Y.Z`) exactly as the SpaceDock version.
  3. Supplies the GitHub release body as the changelog.
- SpaceDock long description is curated via the SpaceDock web UI and links back to `README.md` for full documentation.

### CKAN
- CKAN relies on the release tag/metadata. There is no CKAN upload automation in this repository.
- Publishing a GitHub release is the observable event CKAN crawlers watch; they pull the ZIP + release notes directly from GitHub.

## Trigger Mapping
- **Merge to `main`** → release workflow runs (tag creation → draft release → asset upload → optional publish).
- **Publishing a release** (draft → published or `RELEASE_MODE=publish` finish) → SpaceDock workflow runs and CKAN sees the new release.

## Common Notes / Pitfalls
- Always ensure the tag is created and pushed before the release exists; otherwise the GitHub release URL will point to a missing tag and the EasyISP validation will fail.
- Keep `EasyISP.version`’s `DOWNLOAD` field tied to the `vX.Y.Z` tag URL; the workflow enforces this.
- Do not attempt to short-circuit the flow by publishing before uploading assets—the automated publish step waits for the ZIP to be in place.
- Any automation changes must keep these guarantees in mind: release artifacts upload before publication, and SpaceDock only runs once the release is published.
