# iSH Development Platform — Architecture & Roadmap

**Status:** Foundation plan  
**Audit date:** 2026-11-28  
**Repository:** `phakphum12345/ish`  
**Base branch:** `master`  
**Baseline commit:** `de5ab2c4b1039551203c1106e75f715cd917544b`

## 1. Product direction

Evolve this fork into an iOS development environment built on the existing iSH Linux shell. The project should add useful developer workflows without replacing or destabilizing the upstream terminal, Linux syscall translation, filesystem, or package ecosystem.

The intended product is an **iSH Development Platform** with these capabilities:

- Native iOS terminal and session experience (retain existing iSH implementation).
- Project workspaces and file workflows integrated with iOS Files.
- Git-based source control and developer tooling available inside the Alpine environment.
- Optional AI assistance for explanations, command drafting, code review, and project scaffolding.
- Optional remote development through SSH or explicitly configured cloud services.

This is an incremental roadmap, not a promise that every Linux application or server can run locally on iOS.

## 2. Repository baseline observed

The repository is a public fork of `ish-app/ish`, with `master` as its default branch. At the audit point:

- `master` points to `de5ab2c4b1039551203c1106e75f715cd917544b`.
- The fork has one open pull request (#1), which updates Alpine repository indexes.
- Only `master` was returned by the branch search.
- The repository is not archived. Branch protection is not enabled on `master`.
- GitHub Actions CI defines Linux builds for both Clang and GCC and both iSH and Linux kernel configurations; it also defines macOS Xcode builds for iOS and the simulator.
- The command-line build uses Meson/Ninja and includes a floating-point test plus an end-to-end test script.
- The Xcode project uses Objective-C/UIKit and has a WebKit-backed terminal renderer.

### Existing components to preserve

| Area | Existing implementation / evidence | Direction |
|---|---|---|
| Terminal | `TerminalViewController`, `Terminal`, WebKit terminal assets | Extend carefully; do not replace |
| Sessions | Terminal UUID/session handling and iOS scene support | Preserve session restoration |
| Linux runtime | C kernel/syscall layer, x86 user-mode emulation and architecture-specific assembly | Keep isolated from product UI changes |
| Root filesystems | `Roots`, fakefs tooling and root import/upgrade flows | Reuse existing root lifecycle |
| iOS Files | File Provider extension and shared App Group storage | Integrate workspaces through supported iOS file APIs |
| Preferences | `UserPreferences` backed by `NSUserDefaults` | Add validated, migration-safe preferences |
| Package ecosystem | Alpine APK support and generated repository metadata | Reuse APK; do not invent a parallel package manager |
| Tests | Meson unit/E2E tests and Xcode UI screenshot tests | Add regression coverage before feature expansion |

## 3. Platform and engineering constraints

1. **iOS is not a general-purpose Linux server host.** iSH translates Linux system calls in user space. Kernel features, CPU architectures, privileged operations, long-running daemons, and applications requiring unsupported interfaces may not work.
2. **No assumption of Docker or nested virtualization.** Container engines that require kernel namespaces, cgroups, privileged mounts, or a Linux VM must be treated as remote/cloud workloads unless proven otherwise on-device.
3. **Xcode builds require macOS.** Linux CI can validate the command-line runtime, but it cannot replace an iOS device/simulator build and UI test.
4. **iOS background execution is restricted.** Do not promise persistent background servers or continuous AI jobs. Use foreground work, supported background task APIs where appropriate, or remote execution.
5. **File access must respect iOS security-scoped URLs and File Provider semantics.** Avoid direct assumptions about paths outside the app container.
6. **Network and credentials need explicit user control.** Use TLS, Keychain for secrets, clear provider configuration, and no API keys in source, logs, preferences, or generated diagnostics.
7. **License obligations apply to all derived work.** Preserve GPL notices and comply with `LICENSE.md` and the additional `LICENSE.IOS` terms. Review dependencies and distribution implications before adding third-party code.

## 4. Target architecture

Keep the existing iSH runtime as the stable foundation. New product capabilities should be layered around it:

- **Presentation layer:** native UIKit screens for workspace selection, settings, AI assistance, and connection setup; terminal remains an existing first-class screen.
- **Workspace layer:** metadata and project organization that reference files stored in the app container or user-selected File Provider locations. Never silently relocate user files.
- **Tooling layer:** invoke existing shell tools (for example Git and language toolchains installed through APK) rather than duplicating their functionality in native code.
- **AI adapter layer:** provider-neutral request/response interface. AI suggestions must be previewable; commands and file modifications require explicit user confirmation.
- **Remote adapter layer:** SSH/remote development integration with explicit host trust, authentication, and connection lifecycle.
- **Runtime boundary:** no new AI, cloud, or workspace dependency inside the syscall emulator/kernel unless a separately justified runtime change is reviewed.

## 5. Phased delivery plan

### Phase 0 — Foundation audit (current)

- Record repository baseline, build matrix, architecture, existing user-facing features, and license constraints.
- Identify the correct macOS build/test route and the Linux CI route.
- Establish branch/PR discipline and a regression checklist.
- Do not change runtime behavior in this phase.

**Exit criteria:** architecture and test plan reviewed; feature work can be scoped to existing extension points.

### Phase 1 — Developer workspace foundation

- Design a lightweight workspace model (name, display metadata, selected root/location, and recent activity).
- Reuse iOS Files/File Provider for import/export and user-authorized file access.
- Add a small native workspace entry point without replacing the existing terminal-first experience.
- Add tests for workspace metadata, missing/moved files, permission denial, and persistence/migration.

**Exit criteria:** users can create/open/rename/remove workspace metadata without data loss; existing terminal and root behavior remains unchanged.

### Phase 2 — Source-control workflow

- Verify Git availability and compatibility through the existing Alpine package ecosystem.
- Add documented clone/status/commit/push/pull workflows first.
- Consider a native Git status/diff view only after shell-based workflows and file access are stable.
- Never store Git credentials in plain preferences or logs.

**Exit criteria:** repeatable Git workflow on a supported remote with credential handling documented and tested.

### Phase 3 — AI assistant

- Start with read-only assistance: explain terminal output, explain errors, and draft commands.
- Add provider configuration behind an adapter so local and cloud providers can be selected independently.
- Require a preview and explicit confirmation before executing commands or applying file changes.
- Add cancellation, timeout, network-loss handling, redaction, and usage/privacy controls.
- Do not send workspace files or terminal history to a provider without clear user consent.

**Exit criteria:** AI can provide useful suggestions without autonomous destructive execution or unintended data disclosure.

### Phase 4 — Remote development

- Add SSH connection profiles and safe host-key verification.
- Support remote shell workflows before attempting richer remote IDE features.
- Treat cloud compute as an optional external capability, not as a replacement for local iSH.
- Document cost, data location, provider credentials, and disconnect behavior.

**Exit criteria:** a user can connect, work, disconnect, and reconnect without exposing secrets or losing local state.

### Phase 5 — Quality, release, and maintenance

- Expand automated tests and add simulator/device smoke tests.
- Verify accessibility, keyboard behavior, iPhone/iPad layouts, and VoiceOver.
- Add upgrade/migration and recovery tests for workspace metadata.
- Keep the fork synchronized with upstream using small, reviewable changes.
- Publish release notes and source/license notices for derived distributions.

## 6. Required validation protocol

For each implementation PR:

1. **READ:** inspect affected code, call sites, existing tests, and upstream history.
2. **ANALYZE:** document behavior, compatibility risks, data migration, and failure modes.
3. **MODIFY:** make the smallest isolated change on a feature branch.
4. **TEST:** run relevant Meson/Ninja tests and CI; run Xcode build/UI tests on macOS for iOS-facing changes.
5. **AUDIT:** inspect the complete diff, security/privacy implications, license notices, and regression risks.
6. **MERGE:** only after required checks pass and review is complete.
7. **VERIFY:** confirm the merged commit and post-merge CI.
8. **FOLLOW-UP:** record remaining work and update this roadmap.

A green Linux build alone is not sufficient evidence for an iOS UI change. Do not merge while required checks are failing or missing.

## 7. First implementation candidates (not yet authorized by this plan)

Prioritize in this order after Phase 0 review:

1. Workspace metadata and lifecycle design, reusing the existing roots and File Provider boundaries.
2. Git workflow documentation and compatibility tests using APK-installed tools.
3. AI read-only assistant prototype with consent-first context sharing.
4. SSH connection profile and remote shell experience.

Do not begin with a custom package manager, custom terminal renderer, Docker-on-iOS, or an autonomous AI agent. These either duplicate existing functionality or carry disproportionate platform/security risk.

## 8. Audit limitations

This document is based on repository metadata and source files inspected through GitHub at the recorded baseline. No macOS/Xcode build, iOS simulator run, physical-device test, or local Meson/Ninja execution has been performed as part of this documentation-only foundation change. Those checks must be run in an appropriate environment before implementation PRs are considered validated.
