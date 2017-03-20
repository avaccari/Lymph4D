% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

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

% If there is a template pad both to the max size
if isfield(handles, 'tmpl')
    padSize = max(size(img), size(handles.stackTmpl));
    handles.sliceNum = padSize(3);
    handles.stackNum = padSize(4);
    img = padarray(img, padSize - size(img), 'post');
    handles.stackTmpl = padarray(handles.stackTmpl, padSize - size(handles.stackTmpl), 'post');
    axes(handles.tmplAx);
    handles.tmpl = imagesc(handles.stackTmpl(:, :, handles.sliceIdx, handles.stackIdx), clims);
end
    
% Assign to array
handles.stackImg = img;

% Display image
axes(handles.mainAx);
handles.img = imagesc(img(:, :, 1, 1), clims);
handles.stackIdx = 1;
handles.sliceIdx = 1;

% Zero the sliders
set(handles.stackSlider, 'Value', 0);
set(handles.sliceSlider, 'Value', 0);
