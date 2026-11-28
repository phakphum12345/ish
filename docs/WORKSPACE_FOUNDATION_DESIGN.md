# Workspace Foundation — Design & Safety Plan

**Status:** Design proposal; no runtime behavior changed  
**Baseline:** `master` at the Phase 0 audit baseline  
**Scope:** Phase 1 workspace metadata and lifecycle, built around existing iSH roots and File Provider integration

## 1. Executive decision

Implement workspace support incrementally as a metadata layer around the existing iSH filesystem roots. A workspace must not become a second filesystem manager, copy user files by default, or replace the existing terminal-first launch and session model.

The first implementation should support workspace metadata only (create, list, rename, open/select, and remove metadata). It should reference an existing root or a user-authorized external location. It must not delete or move root contents when workspace metadata is removed.

## 2. Verified current architecture

The current app already has a filesystem-root lifecycle:

- `Roots` discovers root names by listing the shared App Group `roots` directory.
- Each root is stored below `ContainerURL()/roots/<name>`.
- `Roots.defaultRoot` is persisted in `NSUserDefaults` under `Default Root`.
- `Roots` imports, exports, renames, and destroys root filesystems.
- Root changes synchronize corresponding `NSFileProviderDomain` objects. The domain identifier and storage-relative path currently use the root name.
- The File Provider extension mounts the selected root's `data` directory and its `meta.db`.
- The Roots UI already exposes import/export, browsing, booting, rename, and delete operations.
- Terminal startup uses `UserPreferences.launchCommand`; terminal sessions are identified separately by UUID.

These are established behaviors and must remain compatible. Workspace metadata should not alter the on-disk root layout or the File Provider item identifiers.

## 3. Workspace model proposal

Use a small versioned metadata record, independent of filesystem contents:

| Field | Purpose | Rule |
|---|---|---|
| `id` | Stable workspace identity | UUID; never derive from display name |
| `name` | User-facing label | Non-empty, trimmed, unique within workspace list |
| `kind` | Location type | Initially `root`; external locations only after security-scoped access is designed |
| `rootName` | Existing iSH root reference | Required for `kind=root`; must resolve to an existing root |
| `createdAt` | Audit metadata | ISO-8601 date |
| `updatedAt` | Audit metadata | ISO-8601 date |
| `schemaVersion` | Migration control | Explicit integer, initially 1 |

Do not persist absolute paths for external provider URLs. If external locations are added later, store security-scoped bookmarks and validate access on every open.

The workspace list should be stored in a dedicated versioned file in the existing App Group container, not mixed into `NSUserDefaults` and not placed inside a root filesystem. Writes should be atomic (write temporary file, then replace), with corruption recovery that preserves the last known-good copy.

## 4. Lifecycle and data-safety rules

### Create

1. Validate and normalize the workspace name.
2. Confirm the referenced root exists.
3. Generate a UUID independent of the root name.
4. Persist metadata atomically.
5. Do not create, copy, or mutate files inside the root.

### Open / select

1. Resolve the workspace UUID from metadata.
2. Verify its referenced root still exists.
3. Route to the existing root/terminal flow; do not silently start a new shell or change the default root.
4. If the root is missing, show a recoverable error and preserve the metadata for relinking.

### Rename

1. Change only the workspace display name.
2. Keep the workspace UUID and root reference unchanged.
3. Do not call `Roots.renameRoot:toName:error:` as a side effect.

### Remove

1. Remove only the workspace metadata record.
2. Never call `destroyRootNamed:error:`.
3. If the root is referenced by another workspace or is the default root, its filesystem remains untouched.
4. Provide a separate, explicit root-management action for destructive filesystem operations.

## 5. Compatibility and migration

- Existing installations with no workspace metadata must continue to boot exactly as before.
- No automatic workspace creation should change the default root or terminal launch command.
- A future opt-in migration may offer one workspace per existing root, but it must be previewed and reversible.
- Unknown schema versions must fail closed for writes and leave the source file intact.
- Invalid or stale root references must be reported, not silently repaired by deleting records.
- Metadata removal, corruption, or migration failure must never remove root directories, File Provider domains, or user data.

## 6. Risks discovered during source inspection

- Root names currently double as File Provider domain identifiers and storage-relative paths. Reusing a root name as a workspace ID would couple display changes to File Provider lifecycle.
- The current root rename implementation validates the existing `name` argument in places where validation of `newName` is required. Workspace rename must not reuse that method; a separate targeted root-rename fix should be considered and tested independently.
- File Provider access depends on the App Group container and security-scoped URL behavior. External workspace support must not assume arbitrary provider paths remain mounted or accessible.
- The current UI test target is minimal. Metadata parsing, migration, atomic writes, missing-root behavior, and destructive-operation isolation need unit-level coverage before adding UI.

## 7. Proposed implementation sequence

1. Add a pure workspace metadata model and validation helpers, with no UI integration.
2. Add a versioned repository/store using atomic writes and explicit error results.
3. Add tests for round-trip persistence, duplicate/invalid names, unknown schema versions, corrupt files, interrupted writes, missing roots, and metadata-only removal.
4. Add a small workspace list/create/rename/select UI after the model and store are proven.
5. Integrate selection with existing root/terminal navigation without changing startup defaults.
6. Add opt-in migration only after compatibility tests cover existing installations.

Each implementation step should be a separate reviewable commit or PR. Keep the existing root lifecycle and File Provider behavior as regression boundaries.

## 8. Acceptance criteria for the first implementation PR

- Existing users with no workspace metadata retain the same startup behavior.
- Workspace IDs remain stable when labels are renamed.
- Workspace removal cannot delete, rename, or export root contents.
- A missing root is surfaced as a recoverable state.
- Metadata writes are atomic and schema-versioned.
- Automated tests cover all validation, migration, and failure cases.
- Linux CI remains green; iOS-facing code also requires an Xcode build and simulator/device smoke test on macOS before merge.

## 9. Out of scope

- Replacing or redesigning `Roots` or File Provider.
- Moving/copying user files automatically.
- Arbitrary external-folder support before security-scoped bookmark handling is implemented.
- AI, SSH, cloud execution, package-manager changes, or terminal-session redesign.
- Destructive root operations from workspace UI.
