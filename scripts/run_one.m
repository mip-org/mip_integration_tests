function run_one(scriptPath)
%RUN_ONE  Fresh-slate integration test runner for "mip in the wild".
%
% Usage (CI invokes this once per test script, each in its own MATLAB process):
%   matlab -batch "addpath('scripts'); run_one('tests/01_install_and_info.m')"
%
% From a clean MATLAB session it:
%   1. Points userpath at a fresh, empty directory so the website installer's
%      default install location (<userpath>/mip) is unique and does not
%      pre-exist -- the installer aborts if it does. Every script therefore
%      installs mip from scratch, exactly as a brand-new user would.
%   2. Installs mip using the published website instructions, verbatim:
%          eval(webread('https://mip.sh/install.txt'))
%   3. Runs the given test script, which uses `mip` and must error on failure.
%   4. On full success, writes the marker file named by $PASS_MARKER (in the
%      launch directory). CI gates on that marker's existence, NOT MATLAB's
%      exit code, so a cosmetic exit-time crash after a passing run (e.g. the
%      known macOS arm64 shutdown SIGSEGV) is not counted as a failure.
%
% Any real failure raises an error before the marker is written, so the CI
% step fails.

startDir = pwd;

% Non-interactive mip: never block on an install/uninstall confirmation prompt.
setenv('MIP_CONFIRM', 'y');

fprintf('=== run_one: %s ===\n', scriptPath);

% (1) Fresh, unique userpath so the wild installer's default location is clean
%     and cannot collide with a previous script's install on the same runner.
freshUserpath = tempname;
mkdir(freshUserpath);
userpath(freshUserpath);
fprintf('userpath set to fresh directory: %s\n', freshUserpath);

% (2) Install mip exactly as the website instructs. The installer prompts once
%     for the install location and takes the default (<userpath>/mip) on an
%     empty answer. MATLAB's builtin input() cannot run under -batch, so shadow
%     it with a stub returning '' -- the documented "press Enter for the
%     default" answer -- for the duration of the install only.
stubDir = fullfile(fileparts(mfilename('fullpath')), 'prompt_stub');
warnState = warning('off', 'MATLAB:dispatcher:nameConflict');  % shadowing input() is intentional
addpath(stubDir);
rehash;
install_mip_from_wild();
rmpath(stubDir);
rehash;
warning(warnState);
if isempty(which('/mip'))
    error('mip:integration:notInstalled', ...
        'The website installer did not put mip on the path.');
end
fprintf('mip installed in the wild: version %s\n', mip.version());

% (3) Run the requested test script (errors propagate and fail the step).
fprintf('--- running %s ---\n', scriptPath);
run(scriptPath);
fprintf('--- %s completed without error ---\n', scriptPath);

% (4) Success marker, written in the launch directory (CI reads it there).
marker = getenv('PASS_MARKER');
if ~isempty(marker)
    fid = fopen(fullfile(startDir, marker), 'w');
    if fid ~= -1
        fclose(fid);
    end
end

fprintf('=== PASS: %s ===\n', scriptPath);

end


function install_mip_from_wild()
% Run the published installer verbatim. Kept in its own function so that any
% bare `return` inside install.txt (its early-exit paths) returns only from
% here, not from run_one -- letting the caller verify mip actually installed.
eval(webread('https://mip.sh/install.txt'));
end
