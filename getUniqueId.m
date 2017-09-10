% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [ uniqueId ] = getUniqueId()
if ispc
    [~, r] = system('wmic bios get serialnumber /value');
    r = string(regexp(r, '.*=([0-9A-Z]*).*', 'tokens', 'once'));
    uniqueId = strcat(r, '-');
elseif ismac
    [~, r] = system('ioreg -l | grep "IOPlatformSerialNumber" | awk -F''"'' ''{print $4}''');
    uniqueId = strcat(r, '-');
else
    uniqueId = '';
end
