% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

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
warning('off','MATLAB:xlswrite:AddSheet');
for idx = 1 : length(handles.toExcel.sheet)
xlswrite(fullfile(dir, file), ...
         handles.toExcel.sheet(idx).data, ...
         handles.toExcel.sheet(idx).name);
end

% Remove notification
try
    delete(h);
catch ME
end
