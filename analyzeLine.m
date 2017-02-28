% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% --- Analyze the data when a line is traced on the image
function handles = analyzeLine(pos, handles)
f2 = figure(2);
subplot(2, 1, 1, 'parent', f2);
colrs = jet(handles.stackNum);
hold off;

% Prepare cell array for excel export
handles.toExcel = struct();
handles.toExcel.sheet = struct([]);
handles.toExcel.sheet(1).name = 'Val-vs-Pxl';

% Extract coordinates of points in the cross section
[cx, cy, ~] = improfile(handles.stackOrig(:, :, 1, 1), pos(:, 1), pos(:, 2));
lcx = length(cx);

% Preallocate, label columns and add coordinates
data = cell(lcx + 2, handles.stackNum + 3);
label = ['col (x)', 'row (y)', '', strcat('t-', string(linspace(1, handles.stackNum, handles.stackNum)))];
data(2, :) = cellstr(label);
c = round(cx);
r = round(cy);
data(3:end, 1) = num2cell(c');
data(3:end, 2) = num2cell(r');
data(3:end, 3) = cellstr(strcat('p-', string(linspace(1, lcx, lcx))));

% Plot the the cross section evolution over time
for stk = 1 : handles.stackNum
    img = squeeze(handles.stackOrig(:, :, handles.sliceIdx, stk));
    prf = improfile(img, pos(:, 1), pos(:, 2));
    data(3:end, stk + 3) = num2cell(prf);
    plot(prf, 'color', colrs(stk, :)); 
    hold on;
end
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

% Store in handle for export
data(1, 1) = cellstr('Evolution over time of cross section');
handles.toExcel.sheet(1).data = data;







% Prepare second sheet for excel export
handles.toExcel.sheet(2).name = 'CSPxl-vs-Tim';

% Preallocate, label, and add coordinates
data = cell(handles.stackNum + 4, lcx + 1);
data(2:3, 1) = {'col (x)'; 'row (y)'};
data(2, 2:end) = num2cell(c);
data(3, 2:end) = num2cell(r);
data(4, 2:end) = cellstr(strcat('p-', string(linspace(1, lcx, lcx))));
data(5:end, 1) = cellstr(strcat('t-', string(linspace(1, handles.stackNum, handles.stackNum))));

% Plot the time evolution of each point in the cross section
subplot(2, 1, 2, 'parent', f2);
colrs = jet(lcx);
hold off;
for pnt = 1 : lcx
    ts = squeeze(handles.stackOrig(r(pnt), c(pnt), handles.sliceIdx, :));
    data(5:end, pnt + 1) = num2cell(ts);
    plot(ts, 'color', colrs(pnt, :));
    hold on;
end
txt = strcat('Evolution over time of each pixel in the cross section: (Slice: ', ...
             mat2str(handles.sliceIdx), ...
             ') (Blue \rightarrow Red)');
title(txt);
ylabel('Amplitude');
xlabel('Time');

% Store in handle for export
data(1, 1) = cellstr('Evolution over time of each pixel in the cross section');
handles.toExcel.sheet(2).data = data;

% Prepare export file name
name = 'LineAnalysis';
if isfield(handles, 'expInfo')
    name = strcat('Line_', handles.expInfo.expNameExp);
end
handles.toExcel.fileName = fullfile(handles.storePath, char(strcat(handles.machineId, name, '.xlsx')));



% Add button with callback to export to excell
uicontrol('parent', f2, ...
         'style', 'pushbutton', ...
         'string', [char(8594) 'XLSX'], ...
         'units', 'normalized', ...
         'position', [0.0, 0.0, 0.1, 0.05], ...
         'callback', @(hObject, eventdata)exportToExcel(hObject, eventdata, handles));

