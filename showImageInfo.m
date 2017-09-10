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

% Evaluate directionality domains within the image
function handles = showImageInfo(handles)

% Extract current slice info
info = handles.expInfo.full(handles.sliceIdx, handles.stackIdx);

% Extract info from structure
keys = char(fieldnames(info));
len = size(keys, 1);
txt = cell(len);
for k = 1:len
    val = eval(['info.' keys(k, :)]);
    if ischar(val)
        sval = [' : ' val];
    elseif isnumeric(val)
        sval = [' : ' num2str(val(1:min(3,end))')];
    else
        sval = ' : ...';
    end
    txt{k} = sprintf('%3d %s', k, [keys(k, :) sval]);
end

h = figure('Units', 'normalized', ...
           'OuterPosition', [0, 0, 0.5, 1]);
uicontrol('Parent', h,...
          'Units', 'normalized',...
          'Position', [0, 0, 1, 1],...
          'Style', 'edit',...
          'Enable', 'inactive',...
          'Max', len, ...
          'FontName', 'FixedWidth', ...
          'HorizontalAlignment', 'left', ...
          'String', txt)

end

