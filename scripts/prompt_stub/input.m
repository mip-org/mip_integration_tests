function out = input(varargin)
%INPUT  CI stub: answer any prompt with the default, as if the user pressed Enter.
%
% MATLAB's builtin input() cannot run under `matlab -batch` -- it errors with
% "Support for user input is required, which is not available on this platform."
% The mip website installer (https://mip.sh/install.txt) prompts once, for the
% install location, and treats an empty answer as "use the default"
% (<userpath>/mip). run_one places this stub at the front of the path ONLY while
% the installer runs, so the documented interactive install proceeds unattended
% exactly as a user accepting the default would. Returns '' for both plain and
% 's' (string) input calls.
out = '';
end
