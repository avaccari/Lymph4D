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

% --- Configure default value pre stack
function handles = configDefaults(handles)

handles.onImage = false;
handles.selection.mode = 'point';
handles.drawing.active = false;

handles.localMean.use = false;
handles.localMean.type = 1;
handles.localMean.size = 3;
set(handles.setFiltSizEd, 'String', num2str(handles.localMean.size));

handles.alignType = 'rigid';
set(handles.setAlignMtdPop, 'Value', 2);

handles.direction.mapType = 1;
handles.direction.hoodSiz = 3;
handles.direction.useHood = false;
handles.direction.useTimeWin = false;
handles.direction.timeWinSiz = 3;
handles.direction.smoothModel = false;

% Default spatial and temporal steps
handles.expInfo.ds = [1, 1, 1];
handles.expInfo.dt = 1;

% Define single-sided percentage to be considered outliers
handles.outliers = 1.;
handles.cOut = [handles.outliers, 100 - handles.outliers];
