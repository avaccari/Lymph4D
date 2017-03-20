% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

function varargout = viewer(varargin)
% VIEWER MATLAB code for viewer.fig
%      VIEWER, by itself, creates a new VIEWER or raises the existing
%      singleton*.
%
%      H = VIEWER returns the handle to a new VIEWER or the handle to
%      the existing singleton*.
%
%      VIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VIEWER.M with the given input arguments.
%
%      VIEWER('Property','Value',...) creates a new VIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before viewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to viewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help viewer

% Last Modified by GUIDE v2.5 12-Mar-2017 15:24:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @viewer_OpeningFcn, ...
                   'gui_OutputFcn',  @viewer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before viewer is made visible.
function viewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to viewer (see VARARGIN)

% Choose default command line output for viewer
handles.output = hObject;

% Check if data was passed
if nargin > 3
    handles.stackOrig = varargin{1};
    
    % Configure the stack for visualization
    handles = configStack(handles);
end

% Initialize some "globals"
[handles.storePath, ~, ~] = fileparts(mfilename('fullpath'));
handles.onImage = false;
handles.selection.mode = 'point';
handles.drawing.active = false;
handles.localMean.use = false;
handles.localMean.type = 1;
handles.localMean.size = 3;
set(handles.setFiltSizEd, 'String', num2str(handles.localMean.size));
handles.alignType = 'rigid';
set(handles.setAlignMtdPop, 'Value', 2);

% Get unique id
if ispc
    [~, r] = system('wmic bios get serialnumber /value');
    r = string(regexp(r, '.*=([0-9A-Z]*).*', 'tokens', 'once'));
    handles.machineId = strcat(r, '-');
elseif ismac
    [~, r] = system('ioreg -l | grep "IOPlatformSerialNumber" | awk -F''"'' ''{print $4}''');
    handles.machineId = strcat(r, '-');
else
    handles.machineId = '';
end    
handles.lastExpFile = char(strcat(handles.machineId, 'lastExp.mat'));

% Create a list of available colormaps
% Eventually you might want to actually parse the following file
%   fullfile(matlabroot, 'toolbox', 'matlab', 'graph3d', 'Contents.m');
handles.cmaps = {'parula', 'hsv', 'hot', 'gray', 'bone', 'copper', 'pink', ...
                 'white', 'flag', 'lines', 'colorcube', 'vga', 'jet', ...
                 'prism', 'cool', 'autumn', 'spring', 'winter', 'summer'};

             
% Add copyright info
uicontrol('parent', handles.mainGui, ...
         'style', 'text', ...
         'string', ['Lymph4D ', char(169), '2017 - Andrea Vaccari'], ...
         'units', 'normalized', ...
         'position', [0.85, 0.0, 0.15, 0.025]);
             
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes viewer wait for user response (see UIRESUME)
% uiwait(handles.mainGui);


% --- Outputs from this function are returned to the command line.
function varargout = viewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Called when the window is closed
function viewer_ClosingFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(hObject);


% --- Executes on button press in selectExpBtn.
function selectExpBtn_Callback(hObject, eventdata, handles)
% hObject    handle to selectExpBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Let user select the experiment (directory)
path = uigetdir();

% Open and read the stack
handles = openExperiment(handles, path);

% Store path and experiment info for fast access
save(fullfile(handles.storePath, handles.lastExpFile), 'path');

% Configure the stack for visualization
handles = configStack(handles);

% Update display
handles = updateGui(handles);

guidata(hObject, handles);


% --- Executes on button press in loadLatestBtn.
function loadLatestBtn_Callback(hObject, eventdata, handles)
% hObject    handle to loadLatestBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

try
    load(fullfile(handles.storePath, handles.lastExpFile), 'path');
catch ME
    msgbox('Cannot locate file containing latest experiment information');
    return
end

% Open and read the stack
handles = openExperiment(handles, path);

% Configure the stack for visualization
handles = configStack(handles);

% Update display
handles = updateGui(handles);

guidata(hObject, handles);



% --- Executes on button press in loadVarBtn.
function loadVarBtn_Callback(hObject, eventdata, handles)
% hObject    handle to loadVarBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% If expInfo exists, resetBtn it
if isfield(handles, 'expInfo')
    handles = rmfield(handles, 'expInfo');
end

% Load the list of variables in the 'base' workspace
list = evalin('base', 'whos');

% Select only the variable of the right size
list = list(cellfun('length', {list.size}) == 4);

% Check if there is anything left
if isempty(list) == 1
    msgbox('There are no 4D variables in the workspace');
    return
end
    
% Ask user to pick the variable  
[s, v] = listdlg('PromptString', 'Select a variable (x, y, z, t):', ...
                 'SelectionMode', 'single', ...
                 'ListString', {list.name});

% If error, bail
if v == 0
    msgbox('There was an error during the selection process.');
    return
end

% Load the variable and open it
handles.stackOrig = evalin('base', list(s).name);

% Configure the stack for visualization
handles = configStack(handles);

% Update display
handles = updateGui(handles);

guidata(hObject, handles);


% --- Executes on button press in loadFileBtn.
function loadFileBtn_Callback(hObject, eventdata, handles)
% hObject    handle to loadFileBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% If expInfo exists, resetBtn it
if isfield(handles, 'expInfo')
    handles = rmfield(handles, 'expInfo');
end

% Let user select the experiment (directory)
[fName, pName] = uigetfile(fullfile(handles.storePath, '*.mat'), ...
                           'Select a file containing a 4D stack (x, y, z, t)');
                       
% Load stack
data = load(fullfile(pName, fName));
fnames = fieldnames(data);
found = false;

% Load the first suitable variable
for idx = 1 : length(fnames)
    stack = data.(fnames{idx});
    if length(size(stack)) == 4
        handles.stackOrig = stack;
        found = true;
        break
    end
end
   
% If no suitable variable was found, bail
if ~found
    msgbox('There are not 4D variables in the file');
    return
end

% Configure the stack for visualization
handles = configStack(handles);

% Update display
handles = updateGui(handles);

guidata(hObject, handles);





% --- Executes on slider movement.
function sliceSlider_Callback(hObject, eventdata, handles)
% hObject    handle to sliceSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles = guidata(hObject);

% Update image when user use the slider
try
    dx = 1.0 / (handles.sliceNum - 1);
    idx = 1 + floor(get(hObject, 'Value') / dx);
    if idx ~= handles.sliceIdx
        handles.sliceIdx = idx;

        % Update the axes
        set(handles.img, 'CData', handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx));  
        if isfield(handles, 'tmpl')
            try
                set(handles.tmpl, 'CData', handles.stackTmpl(:, :, handles.sliceIdx, handles.stackIdx));
            catch ME
            end
        end

        % Update array indexing
        handles = updateIdx(handles);

        % Update display
        handles = updateGui(handles);

        guidata(hObject, handles);
    end
catch ME
end

% --- Executes during object creation, after setting all properties.
function sliceSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliceSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

handles = guidata(hObject);

% Create listener for real time update with slider
handles.sliceSliderListener = addlistener(hObject, ...
                                          'ContinuousValueChange', ...
                                          @(hObject, eventdata) sliceSlider_Callback(hObject, eventdata));

guidata(hObject, handles);


% --- Executes on slider movement.
function stackSlider_Callback(hObject, eventdata, handles)
% hObject    handle to stackSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles = guidata(hObject);

% Update image when user use the slider
try
    dx = 1.0 / (handles.stackNum - 1);
    idx = 1 + floor(get(hObject, 'Value') / dx);
    if idx ~= handles.stackIdx
        handles.stackIdx = idx;

        % Update the axes
        set(handles.img, 'CData', handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx));  
        if isfield(handles, 'tmpl')
            try
                set(handles.tmpl, 'CData', handles.stackTmpl(:, :, handles.sliceIdx, handles.stackIdx));
            catch ME
            end
        end

        % Update array indexing
        handles = updateIdx(handles);
        
        % Update display
        handles = updateGui(handles);

        guidata(hObject, handles);
    end
catch ME
end

% --- Executes during object creation, after setting all properties.
function stackSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stackSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

handles = guidata(hObject);

% Create listener for real time update with slider
handles.stackSliderListener = addlistener(hObject, ...
                                          'ContinuousValueChange', ...
                                          @(hObject, eventdata) stackSlider_Callback(hObject, eventdata));

guidata(hObject, handles);


% --- Executes on button press in resetBtn.
function resetBtn_Callback(hObject, eventdata, handles)
% hObject    handle to resetBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Update display
handles.stackImg = handles.stackOrig;
set(handles.img, 'CData', handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx));
handles = updateGui(handles);

guidata(hObject, handles);




% --- Executes on button press in selPointRbtn.
function selPointRbtn_Callback(hObject, eventdata, handles)
% hObject    handle to selPointRbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of selPointRbtn
handles = guidata(hObject);
    
handles.selection.mode = 'point';

guidata(hObject, handles);


% --- Executes on button press in selLineRbtn.
function selLineRbtn_Callback(hObject, eventdata, handles)
% hObject    handle to selLineRbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of selLineRbtn
handles = guidata(hObject);
    
handles.selection.mode = 'line';

guidata(hObject, handles);


% --- Executes on button press in selRectRbtn.
function selRectRbtn_Callback(hObject, eventdata, handles)
% hObject    handle to selRectRbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of selRectRbtn
handles = guidata(hObject);
    
handles.selection.mode = 'rectangle';

guidata(hObject, handles);


% --- Executes on button press in selCircleRbtn.
function selCircleRbtn_Callback(hObject, eventdata, handles)
% hObject    handle to selCircleRbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of selCircleRbtn
handles = guidata(hObject);
    
handles.selection.mode = 'circle';

guidata(hObject, handles);


% --- Executes on button press in setFiltOnChk.
function setFiltOnChk_Callback(hObject, eventdata, handles)
% hObject    handle to setFiltOnChk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of setFiltOnChk
handles = guidata(hObject);

handles.localMean.use = get(hObject, 'Value');

% Need to push the data so that it is available in handles.mainGui
guidata(hObject, handles);

% Redraw the graph with the new parameters
if handles.drawing.active
    analyzeLine(handles.drawing.line.getPosition, handles.mainGui);
end





% --- Executes on selection change in setFiltTypPop.
function setFiltTypPop_Callback(hObject, eventdata, handles)
% hObject    handle to setFiltTypPop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns setFiltTypPop contents as cell array
%        contents{get(hObject,'Value')} returns selected item from setFiltTypPop
handles = guidata(hObject);

% Choices (defined in guide):
% 1 - 'Disk (radius)'
% 2 - 'Gaussian (sigma)'
handles.localMean.type = get(hObject, 'Value');

% Need to push the data so that it is available in handles.mainGui
guidata(hObject, handles);

% Redraw the graph with the new parameters
if handles.drawing.active
    analyzeLine(handles.drawing.line.getPosition, handles.mainGui);
end




% --- Executes during object creation, after setting all properties.
function setFiltTypPop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to setFiltTypPop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function setFiltSizEd_Callback(hObject, eventdata, handles)
% hObject    handle to setFiltSizEd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of setFiltSizEd as text
%        str2double(get(hObject,'String')) returns contents of setFiltSizEd as a double
handles = guidata(hObject);

handles.localMean.size = str2double(get(hObject, 'String'));

% Need to push the data so that it is available in handles.mainGui
guidata(hObject, handles);

% Redraw the graph with the new parameters
if handles.drawing.active
    analyzeLine(handles.drawing.line.getPosition, handles.mainGui);
end





% --- Executes during object creation, after setting all properties.
function setFiltSizEd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to setFiltSizEd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in setTempBtn.
function setTempBtn_Callback(hObject, eventdata, handles)
% hObject    handle to setTempBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Copy current stack to template
handles.stackTmpl = handles.stackImg;
try
    handles.templExpName = handles.expInfo.expName;
catch ME
    handles.templExpName = '';
end

% Show current image
axes(handles.tmplAx);
handles.tmpl = imagesc(handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx), handles.stackCLims);
colormap(handles.tmplAx, colormap(handles.mainAx));

% Update display
handles = updateGui(handles);

guidata(hObject, handles);



% --- Executes on button press in clearTemplBtn.
function clearTemplBtn_Callback(hObject, eventdata, handles)
% hObject    handle to clearTemplBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Check if there is a template to clear
if ~isfield(handles, 'tmpl')
    return
end

% Clear axes
cla(handles.tmplAx);

% Remove from handles
handles = rmfield(handles, {'stackTmpl', 'tmpl', 'templExpName'});

% Update display
handles = updateGui(handles);

guidata(hObject, handles);



% --- Executes on button press in align2TemplBtn.
function align2TemplBtn_Callback(hObject, eventdata, handles)
% hObject    handle to align2TemplBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Check if there is a template, if not bail
if ~isfield(handles, 'tmpl')
    return
end

% Use current slice
moving = handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx);
fixed = handles.stackTmpl(:, :, handles.sliceIdx, handles.stackIdx);

% Initialize optimizer
[optimizer, metric] = imregconfig('monomodal');

% Find transform to register to template
method = handles.alignType;
tform = imregtform(moving, fixed, method, optimizer, metric);

% Warp the image according to the transform
movingReg = imwarp(moving, tform, 'OutputView', imref2d(size(moving)), 'Interp', 'cubic');

% Show before and after
f3 = figure(3);
subplot(1, 2, 1);
imshowpair(fixed, moving, 'Scaling', 'joint');
title('Before');
subplot(1, 2, 2);
imshowpair(fixed, movingReg, 'Scaling', 'joint');
title('After');
set(gcf, 'NextPlot', 'add');
axes;
h = title(['Results of alignment using: ', handles.alignType]);
set(gca, 'Visible', 'off');
set(h, 'Visible', 'on');

% Ask user to proceed
if ~strcmp('Yes', questdlg('Proceed with alignment?'))
    close(f3);
    return
end

% Align slices for all times
for idx = 1 : handles.stackNum
    reg = imwarp(handles.stackImg(:, :, handles.sliceIdx, idx), ...
                 tform, ...
                 'OutputView', imref2d(size(moving)), ...
                 'Interp', 'cubic');
    handles.stackImg(:, :, handles.sliceIdx, idx) = reg;
end


% Update axes
% set(handles.tmpl, 'CData', handles.stackTmpl(:, :, handles.sliceIdx, handles.stackIdx));
set(handles.img, 'CData', handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx));

% Close figure
close(f3);

guidata(hObject, handles);



% --- Executes on selection change in setAlignMtdPop.
function setAlignMtdPop_Callback(hObject, eventdata, handles)
% hObject    handle to setAlignMtdPop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns setAlignMtdPop contents as cell array
%        contents{get(hObject,'Value')} returns selected item from setAlignMtdPop
handles = guidata(hObject);

% Choices (defined in guide):
% 1 - 'translation'
% 2 - 'rigid'
% 3 - 'similarity'
% 4 - 'affine'
content = cellstr(get(hObject, 'String'));
handles.alignType = content{get(hObject, 'Value')};

% Need to push the data so that it is available in handles.mainGui
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function setAlignMtdPop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to setAlignMtdPop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





% --- Executes on button press in incImgZBtn.
function incImgZBtn_Callback(hObject, eventdata, handles)
% hObject    handle to incImgZBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles.stackImg = circshift(handles.stackImg, [0, 0, 1, 0]);

% Update axes
set(handles.img, 'CData', handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx));

guidata(hObject, handles);


% --- Executes on button press in decImgZBtn.
function decImgZBtn_Callback(hObject, eventdata, handles)
% hObject    handle to decImgZBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles.stackImg = circshift(handles.stackImg, [0, 0, -1, 0]);

% Update axes
set(handles.img, 'CData', handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx));

guidata(hObject, handles);







% --- Executes on mouse motion over figure - except title and menu.
function mainGui_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to mainGui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Get location of mouse respect to application window
pos = get(hObject, 'currentPoint');  % (0,0) is bottom-left
pX = pos(1);
pY = pos(2);

% Get information about location and size of axes
maLoc = get(handles.mainAx, 'Position');
maL = maLoc(1);
maB = maLoc(2);
maW = maLoc(3);
maH = maLoc(4);

handles.onImage = false;

% Check if within image limits
if pX >= maL && pY >= maB
    maX = pX - maL;
    maY = pY - maB;
    if maX <= maW && maY <= maH
        handles.onImage = true;
        cPos = get(handles.mainAx, 'CurrentPoint');
        handles.posIdx = round(cPos(1, 1:2));
        handles = updateIdx(handles);  % Update array indexing
        handles = updateGui(handles);  % Update display
    end
end

guidata(hObject, handles);


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function mainGui_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to mainGui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Grab the type of mouse button event
handles.buttonType = get(hObject, 'SelectionType');

guidata(hObject, handles);



% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function mainGui_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to mainGui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

switch handles.selection.mode
    case 'point'
        switch handles.buttonType
            case 'normal' % Left Single-Click
                if handles.onImage
                    handles = analyzePoint(handles);
                end
            case 'open' % Left Double-Click
        end
    case 'line'
        switch handles.buttonType
            case 'normal'
                if handles.onImage
                    if ~handles.drawing.active
                        txt = {'Drag the ends of the line to select a cross', ...
                               'section. The temporal evolution will be shown', ...
                               'in real time in a popup figure.', ...
                               'To remove the line, double click on it.'};
                        uiwait(msgbox(txt));
                        handles.drawing.active = true;
                        startPos = [handles.posIdx(1), handles.posIdx(1) + 10; ...
                                    handles.posIdx(2), handles.posIdx(2) + 10];
                        handles.drawing.line = imline(handles.mainAx, ...
                                                      startPos(1, :), ...
                                                      startPos(2, :));
                        handles.drawing.line.setColor('black');
                        handles.drawing.line.addNewPositionCallback(@(pos)analyzeLine(pos, handles.mainGui));
                        
                        % If there is a template, create a cloned line for
                        % comparison
                        if isfield(handles, 'tmpl')
                            handles.drawing.lineTmpl = imline(handles.tmplAx, ...
                                                              startPos(1, :), ...
                                                              startPos(2, :));
                            handles.drawing.lineTmpl.setColor('black');
                        end
                        
                        % Push data to gui before calling analyzeLine
                        guidata(hObject, handles);
                        analyzeLine(startPos', handles.mainGui);
                    end
                end
            case 'open'
                handles.drawing.active = false;
                handles.drawing.line.delete();
                if isfield(handles, 'tmpl')
                    handles.drawing.lineTmpl.delete();
                end
                try
                    close(handles.figLine);
                catch ME
                end
        end
    case 'rectangle'
        switch handles.buttonType
            case 'normal'
            case 'open'                
        end
    case 'circle'
        switch handles.buttonType
            case 'normal'
            case 'open'                
        end
end

guidata(hObject, handles);


% --- Update array indexing
function handles = updateIdx(handles)
try
    pos = [handles.posIdx(2), ...
           handles.posIdx(1), ...
           handles.sliceIdx, ...
           handles.stackIdx];
    handles.arrayIdx = num2cell(pos);
catch ME
end


% --------------------------------------------------------------------
% MENU
% --------------------------------------------------------------------

% --------------------------------------------------------------------
function menuOptions_Callback(hObject, eventdata, handles)
% hObject    handle to menuOptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mOptColormap_Callback(hObject, eventdata, handles)
% hObject    handle to mOptColormap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Ask user to pick the colormap  
[s, v] = listdlg('PromptString', 'Select the desired colormap:', ...
                 'SelectionMode', 'single', ...
                 'ListString', handles.cmaps);
             
% If error, bail
if v == 0
    msgbox('There was an error during the selection process.');
    return
end

% Check if the colormap exists
map = handles.cmaps{s};
if exist(map, 'file') == 0
    msgbox('The selected colormap is not available on this system');
    return
end

% Change the colormap of the main axis
try
    colormap(handles.mainAx, map);
    colormap(handles.tmplAx, map);
catch ME
end

guidata(hObject, handles);





% --------------------------------------------------------------------
function menuExport_Callback(hObject, eventdata, handles)
% hObject    handle to menuExport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mExp2Ws_Callback(hObject, eventdata, handles)
% hObject    handle to mExp2Ws (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mExp2File_Callback(hObject, eventdata, handles)
% hObject    handle to mExp2File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mExp2Tiff_Callback(hObject, eventdata, handles)
% hObject    handle to mExp2Tiff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function mExp2TiffOrig_Callback(hObject, ~, handles)
% hObject    handle to mExp2TiffOrig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

if ~isfield(handles, 'stackOrig')
    msgbox('There is no stack to export!');
    return
end

% Prepare name of file
name = 'Original';
if isfield(handles, 'expInfo')
    name = strcat('Orig_', handles.expInfo.expNameExp);
end

% Ask user if slice vs time or stack at current time
export = questdlg('What should be exported?', ...
                  'Export to Tiff', ...
                  'Slice vs Time', ...
                  'Stack at Time', ...
                  'Stack at Time');
if isempty(export)
    export = 'Stack at Time';
end

% Prepare file name appendix
fileSpec = ['-t' num2str(handles.stackIdx)];
if strcmp(export, 'Slice vs Time')
    fileSpec = ['-s' num2str(handles.sliceIdx)];
end

% Check if there is a last dir and prepare a default location
dir = handles.storePath;
if isfield(handles, 'lastSaveDir')
    dir = handles.lastSaveDir;
end
fileName = fullfile(dir, ...
                    char(strcat(handles.machineId, ...
                                name, ...
                                fileSpec, ...
                                '.tif')));

% Suggest user and ask where to save
[file, dir] = uiputfile('*.tif', ...
                        'Save file name', ...
                        fileName);

% Check if the user cancelled
if isequal(file, 0) || isequal(dir, 0)
    return
end

% Notify user that saving is ongoing
h = msgbox('Exporting to Tiff...');

if strcmp(export, 'Stack at Time')
    % Extract the current time stack
    data = handles.stackOrig(:, :, :, handles.stackIdx);

    % Normalize and scale to 16-bit
    data = uint16(65535 * (data - min(data(:))) / (max(data(:)) - min(data(:))));

    % Save current time to tiff file
    handles.lastSaveDir = dir;
    for sliceIdx = 1:handles.sliceNum
        imwrite(data(:, :, sliceIdx), ...
                fullfile(dir, file), ...
                'WriteMode', 'append');
    end
else
    % Extract the current time slice
    data = squeeze(handles.stackOrig(:, :, handles.sliceIdx, :));

    % Normalize and scale to 16-bit
    data = uint16(65535 * (data - min(data(:))) / (max(data(:)) - min(data(:))));

    % Save current time to tiff file
    handles.lastSaveDir = dir;
    for stackIdx = 1:handles.stackNum
        imwrite(data(:, :, stackIdx), ...
                fullfile(dir, file), ...
                'WriteMode', 'append');
    end
end
    
% Remove notification
try
    delete(h);
catch ME
end


guidata(hObject, handles);


% --------------------------------------------------------------------
function mExp2TiffCurr_Callback(hObject, eventdata, handles)
% hObject    handle to mExp2TiffCurr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

if ~isfield(handles, 'stackImg')
    msgbox('There is no stack to export!');
    return
end

% Prepare name of file
name = 'Current';
if isfield(handles, 'expInfo')
    name = strcat('Curr_', handles.expInfo.expNameExp);
end

% Ask user if slice vs time or stack at current time
export = questdlg('What should be exported?', ...
                  'Export to Tiff', ...
                  'Slice vs Time', ...
                  'Stack at Time', ...
                  'Stack at Time');
if isempty(export)
    export = 'Stack at Time';
end

% Prepare file name appendix
fileSpec = ['-t' num2str(handles.stackIdx)];
if strcmp(export, 'Slice vs Time')
    fileSpec = ['-s' num2str(handles.sliceIdx)];
end

% Check if there is a last dir and prepare a default location
dir = handles.storePath;
if isfield(handles, 'lastSaveDir')
    dir = handles.lastSaveDir;
end
fileName = fullfile(dir, ...
                    char(strcat(handles.machineId, ...
                                name, ...
                                fileSpec, ...
                                '.tif')));

% Suggest user and ask where to save
[file, dir] = uiputfile('*.tif', ...
                        'Save file name', ...
                        fileName);

% Check if the user cancelled
if isequal(file, 0) || isequal(dir, 0)
    return
end

% Notify user that saving is ongoing
h = msgbox('Exporting to Tiff...');

if strcmp(export, 'Stack at Time')
    % Extract the current time slice
    data = handles.stackImg(:, :, :, handles.stackIdx);

    % Normalize and scale to 16-bit
    data = uint16(65535 * (data - min(data(:))) / (max(data(:)) - min(data(:))));

    % Save current time to tiff file
    handles.lastSaveDir = dir;
    for sliceIdx = 1:handles.sliceNum
        imwrite(data(:, :, sliceIdx), ...
                fullfile(dir, file), ...
                'WriteMode', 'append');
    end
else
    % Extract the current time slice
    data = squeeze(handles.stackImg(:, :, handles.sliceIdx, :));

    % Normalize and scale to 16-bit
    data = uint16(65535 * (data - min(data(:))) / (max(data(:)) - min(data(:))));

    % Save current time to tiff file
    handles.lastSaveDir = dir;
    for stackIdx = 1:handles.stackNum
        imwrite(data(:, :, stackIdx), ...
                fullfile(dir, file), ...
                'WriteMode', 'append');
    end
end

% Remove notification
try
    delete(h);
catch ME
end

guidata(hObject, handles);


% --------------------------------------------------------------------
function mExp2FileOrig_Callback(hObject, eventdata, handles)
% hObject    handle to mExp2FileOrig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

if ~isfield(handles, 'stackOrig')
    msgbox('There is no stack to export!');
    return
end

% Prepare name of file
name = 'Original';
if isfield(handles, 'expInfo')
    name = strcat('Orig_', handles.expInfo.expNameExp);
end

% Check if there is a last dir and prepare a default location
dir = handles.storePath;
if isfield(handles, 'lastSaveDir')
    dir = handles.lastSaveDir;
end
fileName = fullfile(dir, char(strcat(handles.machineId, name, '.mat')));

% Suggest user and ask where to save
[file, dir] = uiputfile('*.mat', ...
                        'Save file name', ...
                        fileName);

% Check if the user cancelled
if isequal(file, 0) || isequal(dir, 0)
    return
end

% Notify user that saving is ongoing
h = msgbox('Exporting to file...');

% Save to file
handles.lastSaveDir = dir;
save(fullfile(dir, file), ...
     '-struct', 'handles', 'stackOrig');
 
% Remove notification
try
    delete(h);
catch ME
end

guidata(hObject, handles);


% --------------------------------------------------------------------
function mExp2FileCurr_Callback(hObject, eventdata, handles)
% hObject    handle to mExp2FileCurr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

if ~isfield(handles, 'stackImg')
    msgbox('There is no stack to export!');
    return
end

% Prepare name of file
name = 'Current';
if isfield(handles, 'expInfo')
    name = strcat('Curr_', handles.expInfo.expNameExp);
end

% Check if there is a last dir and prepare a default location
dir = handles.storePath;
if isfield(handles, 'lastSaveDir')
    dir = handles.lastSaveDir;
end
fileName = fullfile(dir, char(strcat(handles.machineId, name, '.mat')));

% Suggest user and ask where to save
[file, dir] = uiputfile('*.mat', ...
                        'Save file name', ...
                        fileName);

% Check if the user cancelled
if isequal(file, 0) || isequal(dir, 0)
    return
end
     
% Notify user that saving is ongoing
h = msgbox('Exporting to file...');

% Save to file
handles.lastSaveDir = dir;
save(fullfile(dir, file), ...
     '-struct', 'handles', 'stackImg');

 % Remove notification
 try
     delete(h);
 catch ME
 end
 
guidata(hObject, handles);



% --------------------------------------------------------------------
function mExp2WsOrig_Callback(hObject, eventdata, handles)
% hObject    handle to mExp2WsOrig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

if ~isfield(handles, 'stackOrig')
    msgbox('There is no stack to export!');
    return
end

name = 'Original';
if isfield(handles, 'expInfo')
    name = strcat('Orig_', handles.expInfo.expNameExp);
end

% Save to workspace
assignin('base', name, handles.stackOrig);

guidata(hObject, handles);



% --------------------------------------------------------------------
function mExp2WsCurr_Callback(hObject, eventdata, handles)
% hObject    handle to mExp2WsCurr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

if ~isfield(handles, 'stackImg')
    msgbox('There is no stack to export!');
    return
end

name = 'Current';
if isfield(handles, 'expInfo')
    name = strcat('Curr_', handles.expInfo.expNameExp);
end

% Save to workspace
assignin('base', name, handles.stackImg);

guidata(hObject, handles);
