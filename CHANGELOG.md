# Changelog

## Unreleased

- Initial repo: scheduled end-to-end tests of "mip in the wild". Installs the
  published mip via `eval(webread('https://mip.sh/install.txt'))` under the
  latest MATLAB, on a runner with the build toolchain stripped, on
  `linux_x86_64` / `macos_arm64` / `windows_x86_64`. Test scripts (`tests/*.m`)
  run sequentially, each in its own fresh MATLAB process:
  - `t01_install_and_info` — mip installs and its no-package commands work.
  - `t02_package_lifecycle` — install/load/test/unload/uninstall path effects.
  - `t03_dependencies` — dependency auto-install and prune-on-uninstall.
  - `t04_all_core_packages` — install/load/test every `mip-org/core` package for
    the current architecture, one by one, reporting all failures at the end.
