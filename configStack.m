% --- Configure the data from an experiment for visualization
function handles = configStack(handles)

% Bail if the stack is not available
if ~isfield(handles, 'stackOrig')
    msgbox('The stack is not available!');
return
end

img = handles.stackOrig;
[~, ~, handles.sliceNum, handles.stackNum] = size(img);

% Evaluate stack range
imgMin = min(img(:));
imgMax = max(img(:));
clims = [imgMin, imgMax];
handles.stackCLims = clims;

% Normalize stack to [0, 1]
% img = (img - imgMin) / (imgMax - imgMin);
handles.stackImg = img;

% Display image
axes(handles.mainAx);
handles.img = imagesc(img(:, :, 1, 1), clims);
handles.stackIdx = 1;
handles.sliceIdx = 1;

% Zero the sliders
set(handles.stackSlider, 'Value', 0);
set(handles.sliceSlider, 'Value', 0);
