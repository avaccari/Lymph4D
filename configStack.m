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

% --- Configure the data from an experiment for visualization
function handles = configStack(handles)

% Bail if the stack is not available
if ~isfield(handles, 'stackOrig')
    msgbox('The stack is not available!');
return
end

% Set default values
handles = configDefaults(handles);

% Extract stack size
img = handles.stackOrig;
[~, ~, handles.sliceNum, handles.stackNum] = size(img);

% Upload temporal slice limits
handles.dirTempStart = 1;
handles.dirTempEnd = handles.stackNum;
set(handles.setDirTempStart, 'String', num2str(handles.dirTempStart));
set(handles.setDirTempEnd, 'String', num2str(handles.dirTempEnd));

% Define mask
handles.stackMask = ones(size(img), 'logical');

% Evaluate stack range (remove 1% outliers)
q = prctile(img(:), handles.cOut);
handles.stackCLims = [q(1), q(2)];

% Normalize stack to [0, 1]
% img = (img - imgMin) / (imgMax - imgMin);

% If there is a template pad both to the max size (should probably cut to
% minimum size to improve comparison)
if isfield(handles, 'tmpl')
    padSize = max(size(img), size(handles.stackTmpl));
    handles.sliceNum = padSize(3);
    handles.stackNum = padSize(4);
    img = padarray(img, padSize - size(img), 'post');
    handles.stackTmpl = padarray(handles.stackTmpl, padSize - size(handles.stackTmpl), 'post');
    axes(handles.tmplAx);
    handles.tmpl = imagesc(handles.stackTmpl(:, :, handles.sliceIdx, handles.stackIdx), handles.tmplCLims);
    pos = get(handles.tmplAx, 'Position');
    handles.tmplCBar = colorbar('location', 'south', ...
                                'FontSize', 8, ...
                                'AxisLocation', 'in', ...
                                'Color', [0.5, 0.5, 0.5], ...
                                'Position', [pos(1), pos(2), pos(3), pos(4) * 0.02]);
end
    
% Assign to array
handles.stackImg = img;

% Reset sliders
handles.stackIdx = 1;
handles.sliceIdx = 1;
set(handles.stackSlider, 'Value', 0);
set(handles.sliceSlider, 'Value', 0);

% Display image
axes(handles.mainAx);

pos = get(handles.mainAx, 'Position');
handles.img = imagesc(img(:, :, handles.sliceIdx, handles.stackIdx), handles.stackCLims);
handles.imgCBar = colorbar('location', 'south', ...
                           'FontSize', 8, ...
                           'AxisLocation', 'in', ...
                           'Color', [0.5, 0.5, 0.5], ...
                           'Position', [pos(1), pos(2), pos(3), pos(4) * 0.02]);

% If template reset to origin
if isfield(handles, 'tmpl')
    handles.stackTmpl = handles.stackTmplOrig;
    
    % Evaluate stack range (remove 1% outliers)
    q = prctile(handles.stackTmpl(:), handles.cOut);
    handles.tmplCLims = q;
    set(handles.tmplAx, 'CLim', handles.tmplCLims);
    set(handles.tmpl, 'CData', handles.stackTmpl(:, :, handles.sliceIdx, handles.stackIdx));
end
                      