% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% --- Create the analysis lines
function handles = lineCreate(startPos, handles)
handles.drawing.active = true;
handles.drawing.line = imline(handles.mainAx, ...
                              startPos(1, :), ...
                              startPos(2, :));
handles.drawing.line.setColor('black');
handles.drawing.line.addNewPositionCallback(@(pos)lineAnalyze(pos, handles.mainGui));
handles.drawing.textS = text(startPos(1, 1) - 5, startPos(1, 2)- 5, 'S', 'Color', [0.5, 0.5, 0.5]);
handles.drawing.textE = text(startPos(2, 1) + 3, startPos(2, 2)+ 3, 'E', 'Color', [0.5, 0.5, 0.5]);

% If there is a template, create a cloned line for
% comparison
if isfield(handles, 'tmpl')
    handles.drawing.lineTmpl = imline(handles.tmplAx, ...
                                      startPos(1, :), ...
                                      startPos(2, :));
    handles.drawing.lineTmpl.setColor('black');
end

% Push data to gui before calling lineAnalyze
guidata(handles.mainGui, handles);
handles = lineAnalyze(startPos', handles.mainGui);
guidata(handles.mainGui, handles);

