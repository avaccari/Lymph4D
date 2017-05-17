% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

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
