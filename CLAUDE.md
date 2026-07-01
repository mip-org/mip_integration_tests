# CLAUDE.md

Guidance for working in this repository.

## What this is

Scheduled end-to-end tests of **mip in the wild**: the *published* `mip` and the
*published* `mip-org/core` packages, installed exactly as the website documents
(`eval(webread('https://mip.sh/install.txt'))`), on the three end-user
platforms. It builds and publishes nothing.

Distinct from the other test layers:
- `mip-org/mip` `tests/` — mip's own unit/integration logic, on every push.
- each channel's `build-package.yml` test — a freshly *built* `.mhl`, pre-publish.
- **here** — what a user actually gets, after publishing, daily.

## Design invariants (don't quietly break these)

- **Latest MATLAB.** `setup-matlab@v3` with no `release:` pin. The channels pin
  an old release for forward-portable *builds*; these tests target what a
  current user runs.
- **Stripped runner.** Each job removes the build toolchain (compilers, linkers,
  `libgfortran`/`libgomp`/`libquadmath`, cmake, ...) before running, mirroring
  the channels' package build test (`mip_channel_tools` build-package.yml,
  test-and-upload job). The point is to catch a shipped binary that is not
  self-contained. If you touch the strip steps, keep them in sync with that
  source and keep the `Verify strip` gates.
- **Licensed via the action.** MATLAB is licensed on public repos by
  `matlab-actions/run-command` (its batch-licensing), NOT by having `matlab` on
  PATH. A bare `matlab -batch` in a shell step runs UNLICENSED and fails. So
  every script runs through a `run-command` step — one step per script — and
  each also reinstalls mip from the wild, so it can't merge into one MATLAB
  process anyway (install.txt aborts if mip is already on the path).
- **Clean slate per script.** Each `tests/*.m` runs in its own MATLAB process
  via `scripts/run_one.m`, which points `userpath` at a fresh temp dir and
  reinstalls mip from the wild. A persistent userpath means each script MUST
  override it (the installer aborts if `<userpath>/mip` already exists from an
  earlier script on the same runner). Fresh processes also sidestep the Windows
  MEX-lock problem (a loaded MEX can't be reliably deleted).
- **Marker-gated pass.** CI checks the per-script `<name>.pass` marker that
  run_one writes on success, NOT MATLAB's exit code, so a cosmetic exit-time
  crash after a passing run (known macOS arm64 shutdown SIGSEGV) is tolerated.
  Keep this; don't switch the gate to the exit code.
- **The sweep never fails fast.** `t04_all_core_packages.m` records per-package
  failures and errors once at the end, listing all of them. Cleanup
  (unload/uninstall/`clear mex`) is best-effort and must never turn a passing
  install/load/test into a failure.

## Conventions

- Test scripts assume `mip` is already installed (run_one does it) and must
  **error on failure**. Name them `tNN_description.m` — starting with a letter,
  since MATLAB runs each script by name and a digit-first name is invalid; they
  run in filename order.
- Skip the `mip` package itself in the sweep — it's the tool under test, and
  uninstalling it removes the running package manager.
- Record notable changes in `CHANGELOG.md`. Keep entries brief.
