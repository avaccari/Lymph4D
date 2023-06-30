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

% TODO: update also the different controls with the current values

% --- Update GUI
function handles = updateGui(handles)
handles = updateTxtSliceIdx(handles);
handles = updateTxtStackIdx(handles);
handles = updateTxtPosIdx(handles);
handles = updateTxtExpName(handles);
handles = updateTxtTemplExpName(handles);


% --- Update index indicator
function handles = updateTxtSliceIdx(handles)
try
    txt = strcat('sl:', ...
                 num2str(handles.sliceIdx, '%03u'), ...
                 '/', ...
                 num2str(handles.sliceNum, '%03u'));
catch ME
    txt = 'sl:000/000';
end
set(handles.txtSliceIdx, 'String', txt);


% --- Update time indicator
function handles = updateTxtStackIdx(handles)
try
    txt = strcat('st:', ...
                 num2str(handles.stackIdx, '%03u'), ...
                 '/', ...
                 num2str(handles.stackNum, '%03u'));
catch ME
    txt = 'st:000/000';
end
set(handles.txtStackIdx, 'String', txt);


% --- Update experiment name
function handles = updateTxtExpName(handles)
try
    txt = strcat('Experiment:', ...
                 handles.expInfo.expName);
catch ME
    txt = 'Experiment:';
end
set(handles.txtExpName, 'String', txt);


% --- Update template experiment name
function handles = updateTxtTemplExpName(handles)
try
    txt = strcat('Experiment:', ...
                 handles.tmplInfo.expName);
catch ME
    txt = 'Experiment:';
end
set(handles.txtTemplExpName, 'String', txt);


% --- Update position indicator
function handles = updateTxtPosIdx(handles)
try
    txt = strcat('(', ...
                 num2str(handles.posIdx(1), '%03u'), ...
                 ',', ...
                 num2str(handles.posIdx(2), '%03u'), ...
                 ',', ...
                 num2str(handles.sliceIdx, '%03u'), ...
                 ',', ...
                 num2str(handles.stackIdx, '%03u'), ...
                 ')-(', ...
                 num2str(min(handles.stackOrig(handles.arrayIdx{1:3}, :)), '%04u'), ...
                 '<', ...
                 num2str(handles.stackOrig(handles.arrayIdx{:}), '%04u'), ...
                 '<', ...
                 num2str(max(handles.stackOrig(handles.arrayIdx{1:3}, :)), '%04u'), ...
                 ')');
catch ME
    txt = '(000,000,000,000)-(0000<0000<0000)';
end
set(handles.txtPosIdx, 'String', txt);