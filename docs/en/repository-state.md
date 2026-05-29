# Repository State

Conte CLI treats the repository-local `.conte` directory as an enforcement contract, not just a cache.

Repository-local state must live under:

- `<repo>/.conte/config.json`
- `<repo>/.conte/hooks/` for Conte-managed Git hooks

When hooks are enabled, Git must also use:

```bash
git config --local core.hooksPath .conte/hooks
```

## Valid States

### Not initialized

Required facts:

- `<repo>/.conte/config.json` does not exist

Expected behavior:

- `conte init` creates `.conte/config.json`
- `conte status` reports `Not initialized`
- `conte doctor` reports that Conte is not initialized
- `conte release create` fails because repository-local Conte config is missing
- `conte remove` exits cleanly and reports that the repository is not initialized

### Initialized with hooks enabled

Required facts:

- `<repo>/.conte/config.json` exists
- `hooks.enabled=true`
- `hooks.path=.conte/hooks`
- `<repo>/.conte/hooks/commit-msg` exists
- `<repo>/.conte/hooks/pre-push` exists
- `<repo>/.conte/hooks/prepare-commit-msg` exists
- `<repo>/.conte/hooks/pre-commit` exists
- each configured hook is executable
- each configured hook runtime resolves the Conte installation correctly
- `git config --local core.hooksPath` equals `.conte/hooks`

Expected behavior:

- `conte init` verifies the final hook state after writing config and installing hooks
- `conte hooks install` and `conte hooks reinstall --force` can repair the managed hook state
- `conte status` reports hook path alignment plus commit and branch validation activity
- `conte doctor` validates config, hook files, hook executability, hook runtime, branch mapping, workflow branch validity, and release commit validity
- `conte release create` validates non-merge commits since the last tag before calculating the next version
- `conte remove` removes Conte-managed files under `<repo>/.conte`, preserves unmanaged content, and unsets `core.hooksPath` only when that value matches the configured managed hooks path

### Initialized with hooks disabled

Required facts:

- `<repo>/.conte/config.json` exists
- `hooks.enabled=false`
- `core.hooksPath` is not required to point at `.conte/hooks`

Expected behavior:

- `conte init` prints an explicit warning that local commit and branch validation are inactive
- `conte hooks status` reports hooks as disabled/inactive
- `conte status` reports the repository as initialized with hooks disabled
- `conte doctor` warns about inactive local validation, but this warning alone does not fail the command
- `conte release create` still validates non-merge commits since the last tag
- `conte remove` removes only `<repo>/.conte`

### Broken or inconsistent

Examples:

- `.conte/config.json` exists but `core.hooksPath` is missing while `hooks.enabled=true`
- `hooks.enabled=true` but `core.hooksPath` points somewhere else
- configured hook files are missing
- configured hook files are not executable
- configured hook runtime is broken
- shared hook runtime file (`.conte-hook-runtime`) is missing
- branch mapping points to missing local branches
- the current branch violates the selected workflow
- non-merge commits since the last release contain invalid Conventional Commits

Expected behavior:

- `conte status` reports the broken repository state and the specific failing areas
- `conte doctor` exits non-zero and prints actionable errors
- `conte init` aborts if it cannot verify the final enabled-hook state and suggests:

```bash
conte hooks reinstall --force
```

## Command Expectations

### `conte init`

- writes `<repo>/.conte/config.json`
- installs hooks when enabled
- verifies the final state after writing config
- prints the config path, hooks enabled flag, hooks path, `core.hooksPath`, and whether commit and branch validation are active
- warns explicitly when hooks are disabled

### `conte hooks install`

- writes Conte-managed hooks under `<repo>/.conte/hooks`
- sets `core.hooksPath=.conte/hooks`
- preserves unrelated user-managed hook paths outside the configured Conte path

### `conte hooks uninstall`

- removes Conte-managed files from the configured hooks path
- clears `hooks.enabled`
- preserves unrelated files that are not Conte-managed

### `conte status`

- shows whether the repository is not initialized, initialized with hooks enabled, initialized with hooks disabled, or broken
- shows hook path alignment, hook runtime status, validation activity, branch mapping health, workflow branch health, and release commit health

### `conte doctor`

- validates the repository-local contract in depth
- treats disabled hooks as a warning
- treats broken hook/config/runtime state as failure

### `conte release create`

- reads non-merge commits only
- rejects invalid non-merge Conventional Commits since the last tag
- ignores merge commit subjects because release collection uses `git log --no-merges`

### `conte remove`

- reads the configured `hooks.path` before deleting `<repo>/.conte`
- unsets `core.hooksPath` only when it matches the configured managed path
- preserves unrelated `core.hooksPath` values
- deletes only `<repo>/.conte` after path safety validation
