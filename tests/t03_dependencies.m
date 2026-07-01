% Integration test: dependency resolution and pruning.
%
% chunkie (mip-org/core) declares dependencies on fmm2d and flam. Installing
% chunkie must pull both in; loading chunkie must put its code on the path;
% uninstalling chunkie must prune the dependencies nothing else needs. fmm2d
% ships a MEX, so this also exercises a pre-built binary loading in the
% stripped (compiler-free) CI environment.

pkg  = 'chunkie';
deps = {'fmm2d', 'flam'};
fprintf('== 03_dependencies (%s) ==\n', pkg);

mip('install', pkg);

% Every declared dependency must now be installed. resolve_to_installed errors
% if a package is not installed, so a clean resolve IS the assertion.
for i = 1:numel(deps)
    r = mip.resolve.resolve_to_installed(deps{i});
    assert(~isempty(r) && isfield(r, 'fqn'), ...
        '03: dependency %s was not installed with %s', deps{i}, pkg);
    fprintf('dependency present: %s -> %s\n', deps{i}, r.fqn);
end

% Loading chunkie (and its MEX dependency) must register as loaded. We check
% mip's own loaded-package state rather than which('chunkie'): the package name
% is not a function name -- chunkie exports @chunker, chunkerfunc, ... -- so a
% which() on the bare package name would be empty even when correctly loaded.
mip('load', pkg);
loaded = mip.state.key_value_get('MIP_LOADED_PACKAGES');
assert(any(contains(loaded, 'chunkie')), '03: chunkie not loaded after mip load');
assert(any(contains(loaded, 'fmm2d')),   '03: fmm2d dependency not loaded with chunkie');

% Uninstalling chunkie prunes dependencies nothing else needs; resolving a
% pruned dependency afterwards must fail.
mip('unload', pkg);
mip('uninstall', pkg);

pruned = false;
try
    mip.resolve.resolve_to_installed('fmm2d');
catch
    pruned = true;
end
assert(pruned, '03: fmm2d was not pruned after uninstalling %s', pkg);

fprintf('== 03 OK ==\n');
