% Integration test: mip installs from the wild and its core commands work.
%
% run_one has already installed mip via the published website instructions
% (eval(webread('https://mip.sh/install.txt'))) and verified `mip` is on the
% path. Here we exercise the basic, no-package commands and assert they behave.

fprintf('== 01_install_and_info ==\n');

% The core no-package commands must run without error on a wild install.
% NOTE: mip.version() currently returns empty for a published install (mip's
% source mip.yaml has version: "" and no mip.json sits at the installed source
% dir), so `mip version` prints an empty string. That is a mip-core packaging
% issue -- report it, but don't fail this smoke test on it.
v = mip.version();
fprintf('mip.version() -> "%s"\n', v);
if isempty(v)
    warning('mip:integration:emptyVersion', ...
        ['mip.version() returned empty after a wild install -- ' ...
         'mip cannot report its own version (mip-core packaging issue).']);
end

% `mip version` / `mip info` must not error (info prints the platform arch,
% root, and version -- a smoke test that mip can introspect its fresh install).
mip('version');
mip('info');

% The default channel index (mip-org/core) must be reachable and parseable in
% the wild, and list a non-trivial set of packages for this platform.
index = mip.channel.fetch_index('mip-org/core', true);
assert(isfield(index, 'packages') && ~isempty(index.packages), ...
    '01: mip-org/core index has no packages');
fprintf('mip-org/core index lists %d package entries\n', numel(index.packages));

% `mip avail` renders that index for the current architecture.
mip('avail');

fprintf('== 01 OK ==\n');
