% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% Export data to excel workbook
function handles = exportToExcel(hObject, eventdata, handles)

if ~isfield(handles, 'toExcel')
    msgbox('There is no data to export!');
    return
end

name = 'Line';
if isfield(handles, 'expInfo')
    name = strcat('Line_', handles.expInfo.expNameExp);
end

% For each element in the cell array look for sheet name and data and save
for idx = 1 : length(handles.toExcel)
xlswrite(fullfile(handles.storePath, char(strcat(handles.machineId, name, '.xlsx'))), ...
     handles.toExcel(idx).data, ...
     handles.toExcel(idx).sheet);
end
    
