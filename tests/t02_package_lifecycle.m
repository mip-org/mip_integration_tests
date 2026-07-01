% Integration test: full install -> load -> test -> unload -> uninstall
% lifecycle for a representative package, asserting the observable path effects
% at each step.
%
% chebfun is a good subject: it is on mip-org/core, is pure MATLAB (`any` arch,
% no MEX), and ships its own test_script that `mip test` runs.

pkg = 'chebfun';
fprintf('== 02_package_lifecycle (%s) ==\n', pkg);

% Install downloads the package but does NOT add it to the path.
mip('install', pkg);
assert(isempty(which(pkg)), ...
    '02: %s resolves on the path after install but before load', pkg);

% Load adds it (and any dependencies) to the path.
mip('load', pkg);
assert(~isempty(which(pkg)), ...
    '02: %s is not on the path after load', pkg);
fprintf('%s loaded from: %s\n', pkg, which(pkg));

% Run the package's own test_script via mip.
mip('test', pkg);

% Unload removes it from the path again.
mip('unload', pkg);
assert(isempty(which(pkg)), ...
    '02: %s still resolves on the path after unload', pkg);

% Uninstall removes the package from the store.
mip('uninstall', pkg);

fprintf('== 02 OK ==\n');
