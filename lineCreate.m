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

