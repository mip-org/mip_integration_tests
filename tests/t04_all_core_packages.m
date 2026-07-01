% Integration test: install, load, and test EVERY mip-org/core package that
% supports this architecture, one by one, in the stripped (compiler-free) CI
% environment.
%
% This is the core "mip in the wild" sweep: it proves the currently-published
% channel is installable and that its shipped binaries load and run for an end
% user who has no build toolchain present.
%
% Each package is tested independently through its full lifecycle --
% install -> load -> test -> unload -> uninstall. Uninstall is asserted, not
% best-effort: mip clears any loaded MEX itself, so a package that will not
% cleanly uninstall is a real defect and counts as a failure (and uninstalling
% reclaims disk before the next package). A failure in one package is recorded
% but does NOT stop the sweep; the script errors at the end if any package
% failed, listing them all.
%
% The `mip` package itself is skipped: it is the tool under test (its own unit
% tests live in mip-org/mip), and uninstalling it would remove the running
% package manager.

fprintf('== 04_all_core_packages ==\n');

channel = 'mip-org/core';
currentArch = mip.build.arch();
fprintf('Architecture: %s\n', currentArch);

index = mip.channel.fetch_index(channel, true);
packages = index.packages;

% Unique package names compatible with this architecture, mirroring the arch
% filter in `mip avail`: an exact-arch build or the portable `any` build.
names = {};
for i = 1:numel(packages)
    if iscell(packages)
        pkg = packages{i};
    else
        pkg = packages(i);
    end
    if ~isstruct(pkg) || ~isfield(pkg, 'architecture') || ~isfield(pkg, 'name')
        continue
    end
    if strcmp(pkg.architecture, currentArch) || strcmp(pkg.architecture, 'any')
        if ~strcmp(pkg.name, 'mip') && ~ismember(pkg.name, names)
            names{end+1} = pkg.name;
        end
    end
end
names = sort(names);
fprintf('Testing %d packages on %s for %s\n', numel(names), channel, currentArch);

failures = cell(0, 2);   % {name, message}
for i = 1:numel(names)
    name = names{i};
    fqn = sprintf('%s/%s', channel, name);
    fprintf('\n----- [%d/%d] %s -----\n', i, numel(names), fqn);
    % Full lifecycle as one assertion. The collect-and-continue catch is only
    % so the sweep attempts every package and reports them all at the end; it
    % does not hide cleanup errors -- unload/uninstall failures count too.
    try
        mip('install', fqn);
        mip('load', fqn);
        mip('test', fqn);
        mip('unload', fqn);
        mip('uninstall', fqn);
        fprintf('PASS: %s\n', fqn);
    catch err
        fprintf(2, 'FAIL: %s -- %s\n', fqn, err.message);
        failures(end+1, :) = {name, err.message};
    end
end

nFail = size(failures, 1);
fprintf('\n===== Sweep summary: %d/%d passed =====\n', numel(names) - nFail, numel(names));
if nFail > 0
    for i = 1:nFail
        fprintf(2, '  FAILED: %s -- %s\n', failures{i, 1}, failures{i, 2});
    end
    error('mip:integration:sweepFailed', ...
        '%d of %d mip-org/core packages failed on %s', nFail, numel(names), currentArch);
end

fprintf('== 04 OK ==\n');
