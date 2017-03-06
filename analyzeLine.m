% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% --- Analyze the data when a line is traced on the image
function handles = analyzeLine(pos, handles)
% Prepare cell array for excel export
handles.toExcel = struct();
handles.toExcel.sheet = struct([]);
handles.toExcel.sheet(1).name = 'Val-vs-Pxl';

% Extract coordinates of points in the cross section
dummy = handles.stackOrig(:, :, 1, 1);
[cx, cy, ~] = improfile(dummy, pos(:, 1), pos(:, 2));
lcx = length(cx);
c = round(cx);
r = round(cy);

%%%%% Only if averaging
% Create BW image indicating profile location
% BW = zeros(size(dummy));
% BW(sub2ind(size(dummy), r, c)) = 1;

% Create an averaging filter
% flt = fspecial('disk', 5);
%%%%% Only if averaging

% Preallocate, label columns and add coordinates
data = cell(lcx + 2, handles.stackNum + 3);
label = ['col (x)', 'row (y)', '', strcat('t-', string(linspace(1, handles.stackNum, handles.stackNum)))];
data(2, :) = cellstr(label);
data(3:end, 1) = num2cell(c');
data(3:end, 2) = num2cell(r');
data(3:end, 3) = cellstr(strcat('p-', string(linspace(1, lcx, lcx))));

% Extract data (will be used for both plots and export)
for stk = 1 : handles.stackNum
    img = squeeze(handles.stackOrig(:, :, handles.sliceIdx, stk));
%     img = roifilt2(flt, img, BW);
    prf = improfile(img, pos(:, 1), pos(:, 2), 'bicubic');
    data(3:end, stk + 3) = num2cell(prf);
end

% Store extracted values in an easier to handle array
val = data(3:end, 4:end);

% Store in handle for export
data(1, 1) = cellstr('Evolution over time of cross section');
handles.toExcel.sheet(1).data = data;

% Plot the the cross section evolution over time
f2 = figure(2);
subplot(2, 1, 1, 'parent', f2);
colrs = jet(handles.stackNum);
h = plot(cell2mat(val));
set(h, {'color'}, num2cell(colrs, 2));
txt = strcat('Evolution over time of cross section (Slice: ', ...
             mat2str(handles.sliceIdx), ...
             ') (Blue \rightarrow Red)');
title(txt);
ylabel('Amplitude');
txt = strcat('Pixels along cross section:', ...
              mat2str(round(pos(1, :))), ...
              '\rightarrow', ...
              mat2str(round(pos(2, :))));
xlabel(txt);








% Prepare second sheet for excel export
handles.toExcel.sheet(2).name = 'CSPxl-vs-Tim';

% Plot the time evolution of each point in the cross section
subplot(2, 1, 2, 'parent', f2);
h = plot(cell2mat(val'));
colrs = jet(lcx);
set(h, {'color'}, num2cell(colrs, 2));
txt = strcat('Evolution over time of each pixel in the cross section: (Slice: ', ...
             mat2str(handles.sliceIdx), ...
             ') (Blue \rightarrow Red)');
title(txt);
ylabel('Amplitude');
xlabel('Time');

% Build export datasheet and store in handle
data = cell(handles.stackNum + 4, lcx + 1);
data(2:3, 1) = {'col (x)'; 'row (y)'};
data(2, 2:end) = num2cell(c);
data(3, 2:end) = num2cell(r);
data(5:end, 2:end) = val';
data(4, 2:end) = cellstr(strcat('p-', string(linspace(1, lcx, lcx))));
data(5:end, 1) = cellstr(strcat('t-', string(linspace(1, handles.stackNum, handles.stackNum))));
data(1, 1) = cellstr('Evolution over time of each pixel in the cross section');
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

% Add button with callback to export to excell
uicontrol('parent', f2, ...
         'style', 'pushbutton', ...
         'string', [char(8594) 'XLSX'], ...
         'units', 'normalized', ...
         'position', [0.0, 0.0, 0.1, 0.05], ...
         'callback', @(hObject, eventdata)exportToExcel(hObject, eventdata, handles));

