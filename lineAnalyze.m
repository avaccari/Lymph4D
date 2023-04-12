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

% --- Analyze the data when a line is traced on the image
function handles = lineAnalyze(pos, hObject)
handles = guidata(hObject);

% Move text to new position
% TODO: make move fancy so that the letters are always opposed to the line
% direction
set(handles.drawing.textS, 'position', pos(1, :) - [5, 5]);
set(handles.drawing.textE, 'position', pos(2, :) + [3, 3]);

% If there is a template line, move it
if isfield(handles, 'tmpl')
    handles.drawing.lineTmpl.setPosition(handles.drawing.line.getPosition());
end

% Prepare cell array for excel export
handles.toExcel = struct();
handles.toExcel.sheet = struct([]);
handles.toExcel.sheet(1).name = 'Val-vs-Pxl';

% Extract coordinates of points in the cross section
dummy = handles.stackImg(:, :, 1, 1);
[cx, cy, ~] = improfile(dummy, pos(:, 1), pos(:, 2));
handles.linePts = [cx, cy];
lcx = length(cx);
c = round(cx);
r = round(cy);

% If we are averaging locally
note = '';
if handles.localMean.use
    % Create BW image indicating profile location
    BW = zeros(size(dummy));
    BW(sub2ind(size(dummy), r, c)) = 1;

    % Create an averaging filter
    % Choices (defined in guide):
    % 1 - 'Disk (radius)'
    % 2 - 'Gaussian (sigma)'
    switch handles.localMean.type
        case 1
            flt = fspecial('disk', handles.localMean.size);
        case 2
            flt = fspecial('gaussian', 8 * handles.localMean.size, handles.localMean.size);
        otherwise  % Should never get here
            flt = fspecial('disk', fltSize);
    end

    % Create and exel sheet to hold values of filter
    handles.toExcel.sheet(3).name = 'Filter';
    data = cell(size(flt) + [1, 0]);
    data(1, 1) = cellstr('Neighborhood used to evaluate average values');
    data(2:end, :) = num2cell(flt);
    handles.toExcel.sheet(3).data = data;
   
    % Add note to plots
    note = ' (Avrgd)';
end

% Preallocate, label columns and add coordinates
data = cell(lcx + 2, handles.stackNum + 3);
dataTmpl = zeros(lcx, handles.stackNum);
label = ['col (x)', 'row (y)', '', strcat('t-', string(linspace(1, handles.stackNum, handles.stackNum)))];
data(2, :) = cellstr(label);
data(3:end, 1) = num2cell(c');
data(3:end, 2) = num2cell(r');
data(3:end, 3) = cellstr(strcat('p-', string(linspace(1, lcx, lcx))));

% Extract data (will be used for both plots and export)
for stk = 1 : handles.stackNum
    img = squeeze(handles.stackImg(:, :, handles.sliceIdx, stk));
    if isfield(handles, 'tmpl')
        tmpl = squeeze(handles.stackTmpl(:, :, handles.sliceIdx, stk));
    end
    if handles.localMean.use
        img = roifilt2(flt, img, BW);
    if isfield(handles, 'tmpl')
        tmpl = roifilt2(flt, tmpl, BW);
    end
    end
    prf = improfile(img, pos(:, 1), pos(:, 2), 'nearest');
    
    % If there is a template, extract the data from the template
    if isfield(handles, 'tmpl')
       dataTmpl(:, stk) = improfile(tmpl, pos(:, 1), pos(:, 2), 'nearest');
    end
    data(3:end, stk + 3) = num2cell(prf);
end

% Store extracted values in an easier to handle array
val = data(3:end, 4:end);
handles.lineVal = cell2mat(val);
handles.tmplLineVal = dataTmpl;

% Store in handle for export
data(1, 1) = cellstr(['Evolution over time of cross section', note]);
handles.toExcel.sheet(1).data = data;

% Plot the the cross section evolution over time
fig = figure(handles.figs.lineAnalyze);
handles.figLine = fig;
pltCols = 1;
if isfield(handles, 'tmpl')
    pltCols = 2;
end
subplot(2, pltCols, 1, 'parent', fig);
colrs = jet(handles.stackNum);
h = plot(cell2mat(val));
set(h, {'color'}, num2cell(colrs, 2));
txt = {'Evolution over time of cross section (Blue \rightarrow Red)', ...
       ['Slice: ', mat2str(handles.sliceIdx), note]};
title(txt);
ylabel('Amplitude');
txt = strcat('Pixels along cross section:', ...
              mat2str(round(pos(1, :))), ...
              '\rightarrow', ...
              mat2str(round(pos(2, :))));
xlabel(txt);
if isfield(handles, 'tmpl')
    subplot(2, pltCols, 3, 'parent', fig);
    colrs = jet(handles.stackNum);
    h = plot(dataTmpl);
    set(h, {'color'}, num2cell(colrs, 2));
    txt = {'Evolution over time of cross section (Blue \rightarrow Red)', ...
           ['Slice: ', mat2str(handles.sliceIdx), note]};
    title(txt);
    ylabel('Amplitude (Template)');
    txt = strcat('Pixels along cross section:', ...
                  mat2str(round(pos(1, :))), ...
                  '\rightarrow', ...
                  mat2str(round(pos(2, :))));
    xlabel(txt);
end








% Prepare second sheet for excel export
handles.toExcel.sheet(2).name = 'CSPxl-vs-Tim';

% Plot the time evolution of each point in the cross section
subplot(2, pltCols, 2, 'parent', fig);
h = plot(cell2mat(val'));
colrs = jet(lcx);
set(h, {'color'}, num2cell(colrs, 2));
txt = {'Evolution over time of each pixel in the cross section (Blue \rightarrow Red)', ...
       ['Slice: ', mat2str(handles.sliceIdx), note]};
title(txt);
ylabel('Amplitude');
xlabel('Time [frames]');
if isfield(handles, 'tmpl')
    subplot(2, pltCols, 4, 'parent', fig);
    h = plot(dataTmpl');
    colrs = jet(lcx);
    set(h, {'color'}, num2cell(colrs, 2));
    txt = {'Evolution over time of each pixel in the cross section (Blue \rightarrow Red)', ...
           ['Slice: ', mat2str(handles.sliceIdx), note]};
    title(txt);
    ylabel('Amplitude (Template)');
    xlabel('Time [frames]');
end



% Build export datasheet and store in handle
data = cell(handles.stackNum + 4, lcx + 1);
data(2:3, 1) = {'col (x)'; 'row (y)'};
data(2, 2:end) = num2cell(c);
data(3, 2:end) = num2cell(r);
data(5:end, 2:end) = val';
data(4, 2:end) = cellstr(strcat('p-', string(linspace(1, lcx, lcx))));
data(5:end, 1) = cellstr(strcat('t-', string(linspace(1, handles.stackNum, handles.stackNum))));
data(1, 1) = cellstr(['Evolution over time of each pixel in the cross section', note]);
handles.toExcel.sheet(2).data = data;

% Prepare export file name
name = 'LineAnalysis';
if isfield(handles, 'expInfo')
    name = strcat('Line_', handles.expInfo.expNameExp);
end

% Check if there is a last dir and prepare a default location
dir = handles.storePath;
if isfield(handles, 'lastSaveDir')
    dir = handles.lastSaveDir;
end
handles.toExcel.fileName = fullfile(dir, char(strcat(handles.machineId, name, '.xlsx')));

% Add button with callback to export to excel
uicontrol('parent', fig, ...
          'style', 'pushbutton', ...
          'string', [char(8594) 'XLSX'], ...
          'units', 'normalized', ...
          'position', [0.0, 0.0, 0.1, 0.05], ...
          'callback', @(hObject, eventdata)exportToExcel(hObject, eventdata, handles));

% Add another button with callback to calculate diffusion speed
uicontrol('parent', fig, ...
          'style', 'pushbutton', ...
          'string', 'Velocity', ...
          'units', 'normalized', ...
          'position', [0.0, 0.95, 0.1, 0.05], ...
          'callback', @(hObject, eventdata)evalVelocity(hObject, eventdata, handles));
     
guidata(hObject, handles);
