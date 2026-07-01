% Integration test: mip installs from the wild and its core commands work.
%
% run_one has already installed mip via the published website instructions
% (eval(webread('https://mip.sh/install.txt'))) and verified `mip` is on the
% path. Here we exercise the basic, no-package commands and assert they behave.

fprintf('== 01_install_and_info ==\n');

% version() returns a non-empty string.
v = mip.version();
assert(~isempty(v), '01: mip.version() returned empty');
fprintf('mip version: %s\n', v);

% `mip info` (no package) prints the platform arch, root, and version without
% error -- a smoke test that mip can introspect its freshly-installed self.
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
