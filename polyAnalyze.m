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

% --- Analyze the data when a polygon is traced on the image
function handles = polyAnalyze(pos, hObject)
handles = guidata(hObject);

% If there is a template polygon, move it
if isfield(handles, 'tmpl')
    handles.drawing.polyTmpl.setPosition(handles.drawing.poly.getPosition());
end

% Prepare cell array for excel export
handles.toExcel = struct();
handles.toExcel.sheet = struct([]);
handles.toExcel.sheet(1).name = 'PolyAvg-vs-Tim';



% Preallocate, label columns and add time coordinates
data = cell(3, handles.stackNum);
tmplData = zeros(1, handles.stackNum);
label = strcat('t-', string(linspace(1, handles.stackNum, handles.stackNum)));
data(2, :) = cellstr(label);

% Extract the 2D mask identified by the polygon
mask = handles.drawing.poly.createMask();

% Extract data (will be used for both plots and export)
for stk = 1 : handles.stackNum
    img = handles.stackImg(:, :, handles.sliceIdx, stk);
    data{3, stk} = mean(img(mask));
    
    % If there is a template, extract data
    if isfield(handles, 'tmpl')
        tmpl = handles.stackTmpl(:, :, handles.sliceIdx, stk);
        tmplData(stk) = mean(tmpl(mask));
    end
end

% Store in handle for export (no template data)
data(1, 1) = cellstr('Evolution over time of poly-region average');
handles.toExcel.sheet(1).data = data;

% Convert to arrays for easier handling
val = cell2mat(data(3, :));

% Plot the evolution over time of the polygon region average
fig = figure(handles.figs.polyAnalyze);
handles.figPoly = fig;
pltRows = 1;
pltCols = 1;
if isfield(handles, 'tmpl')
    pltRows = 2;
    pltCols = 2;
end
subplot(pltRows, pltCols, 1, 'parent', fig);
plot(val);
txt = {'Evolution over time of poly-region average', ...
       ['Slice: ', mat2str(handles.sliceIdx)]};
title(txt);
ylabel('Average amplitude');
xlabel('Time [frames]');

% If there is a template, show the result and the comparison plot
if isfield(handles, 'tmpl')
    % Template results
    subplot(pltRows, pltCols, 2, 'parent', fig);
    plot(tmplData);
    txt = {'Evolution over time of poly-region average', ...
           ['Slice: ', mat2str(handles.sliceIdx)]};
    title(txt);
    ylabel('Average amplitude (Template)');
    xlabel('Time [frames]');
    
    % Plot comparison
    subplot(pltRows, pltCols, [3, 4], 'parent', fig);
    plot([val', tmplData']);
    txt = {'Comparison of evolution over time of poly-region averages', ...
           ['Slice: ', mat2str(handles.sliceIdx)]};
    title(txt);
    ylabel('Average amplitude');
    xlabel('Time [frames]');
    legend('Current', 'Template', 'Location', 'northwest');
end

% Prepare export file name
name = 'PolyAnalysis';
if isfield(handles, 'expInfo')
    name = strcat('Poly_', handles.expInfo.expNameExp);
end

% Check if there is a last dir and prepare a default location
dir = handles.storePath;
if isfield(handles, 'lastSaveDir')
    dir = handles.lastSaveDir;
end
handles.toExcel.fileName = fullfile(dir, char(strcat(handles.machineId, name, '.xlsx')));

% Add button with callback to export to excell
uicontrol('parent', fig, ...
         'style', 'pushbutton', ...
         'string', [char(8594) 'XLSX'], ...
         'units', 'normalized', ...
         'position', [0.0, 0.0, 0.1, 0.05], ...
         'callback', @(hObject, eventdata)exportToExcel(hObject, eventdata, handles));

guidata(hObject, handles);
