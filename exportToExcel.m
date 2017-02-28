% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% Export data to excel workbook
function handles = exportToExcel(hObject, eventdata, handles)

if ~isfield(handles, 'toExcel')
    msgbox('There is no data to export!');
    return
end


% For each element in the cell array look for sheet name and data and save
for idx = 1 : length(handles.toExcel.sheet)
xlswrite(handles.toExcel.fileName, ...
         handles.toExcel.sheet(idx).data, ...
         handles.toExcel.sheet(idx).name);
end
    
