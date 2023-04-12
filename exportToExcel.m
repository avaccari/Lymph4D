% Copyright 2023 Andrea Vaccari (avaccari@middlebury.edu)

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

% Export data to excel workbook
function exportToExcel(hObject, eventdata, handles)

if ~isfield(handles, 'toExcel')
    msgbox('There is no data to export!');
    return
end



% Suggest user and ask where to save
file = handles.toExcel.fileName;
[file, dir] = uiputfile('*.xlsx', ...
                        'Save file name', ...
                        file);

% Check if the user cancelled
if isequal(file, 0) || isequal(dir, 0)
    return
end

% Notify user that saving is ongoing
h = msgbox('Saving to excel...');

% If the file exists, delete it
if exist(fullfile(dir, file), 'file') == 2
    delete(fullfile(dir, file));
end

% For each element in the cell array look for sheet name and data and save
handles.lastSaveDir = dir;
% warning('off','MATLAB:xlswrite:AddSheet');
for idx = 1 : length(handles.toExcel.sheet)
    % Using 3rd party code based on java libraries
    xlwrite(fullfile(dir, file), ...
            handles.toExcel.sheet(idx).data, ...
            handles.toExcel.sheet(idx).name);
end

% Remove notification
try
    delete(h);
catch ME
end
