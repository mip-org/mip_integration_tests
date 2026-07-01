# mip_integration_tests

Scheduled end-to-end tests of **mip in the wild** — the published `mip` and the
published `mip-org/core` packages, installed exactly as the
[website](https://mip.sh) instructs and exercised on the three end-user
platforms.

## What this tests (and how it differs)

There are three layers of testing in the mip ecosystem:

| Where | What it tests | When |
| --- | --- | --- |
| `mip-org/mip` (`tests/`) | mip's own logic, in isolation | on every push/PR |
| each channel (build-package) | a freshly **built** `.mhl`, before it is published | on build |
| **this repo** | the **already-published** mip + channel, as a user gets it | daily |

This repo does not build or publish anything. Each run:

1. Installs mip from scratch with the documented one-liner —
   `eval(webread('https://mip.sh/install.txt'))` — into a fresh location.
2. Uses the **latest** MATLAB (not the older, forward-portable release the
   channels pin for building).
3. **Strips the build toolchain** from the runner (compilers, linkers, and
   system runtime libs like `libgfortran`), mirroring the channels' package
   build test. A shipped binary that is not self-contained fails to load here
   instead of leaning on a toolchain the end user won't have.
4. Runs a series of independent `.m` scripts, each in its own fresh MATLAB
   process (a clean slate).

## Layout

- `tests/*.m` — the test scripts, run in filename order. Each assumes `mip` is
  already installed (the runner installs it first) and must **error on
  failure**. Currently:
  - `t01_install_and_info.m` — mip installs from the wild; `version` / `info` /
    `avail` work and the channel index is reachable.
  - `t02_package_lifecycle.m` — install → load → test → unload → uninstall for a
    representative package, asserting the path effects at each step.
  - `t03_dependencies.m` — dependencies auto-install with a package and are
    pruned on uninstall.
  - `t04_all_core_packages.m` — **the sweep**: install/load/test every
    `mip-org/core` package that supports this architecture, one by one,
    collecting failures and reporting them all at the end.

  (Filenames are prefixed `t` and start with a letter because MATLAB executes
  each script by name — a digit-first filename is not a valid script name.)
- `scripts/run_one.m` — the per-script harness CI invokes once per test, in a
  fresh MATLAB process: fresh `userpath`, install mip from the wild, run the
  script, write a success marker.
- `.github/workflows/integration-tests.yml` — one job per architecture
  (`linux_x86_64`, `macos_arm64`, `windows_x86_64`); scripts run sequentially.
  Scheduled daily at 08:00 UTC and on manual dispatch.

## Adding a test

Drop a new `tNN_description.m` in `tests/` (start the name with a letter — it is
run by name). It runs automatically, in filename order.
Assume `mip` is on the path; assert your expectations and let any failure raise
an error. Keep each script self-contained — it gets a clean slate.

## Running one locally

With MATLAB on your `PATH` and from the repo root:

```bash
PASS_MARKER=out.pass matlab -batch "addpath('scripts'); run_one('tests/t01_install_and_info.m')"
```

This installs mip in the wild into a throwaway `userpath` and runs the one
script, exactly as CI does — but **without** the toolchain strip, so it does
not prove self-containment the way the CI job does.
