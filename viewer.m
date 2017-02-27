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

% Last Modified by GUIDE v2.5 27-Feb-2017 16:08:24

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
        set(handles.img, 'CData', handles.stackImg(:, :, idx, handles.stackIdx));    

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
function stackSlider_Callback(hObject, ~, handles)
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
        set(handles.img, 'CData', handles.stackImg(:, :, handles.sliceIdx, idx));    

        % Update array indexing
        handles = updateIdx(handles);
        
        % Update display
        handles = updateGui(handles);

        guidata(hObject, handles);
    end
catch ME
end

% --- Executes during object creation, after setting all properties.
function stackSlider_CreateFcn(hObject, eventdata, ~)
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


% --- Executes on button press in exportOrig2Ws.
function exportOrig2Ws_Callback(hObject, eventdata, handles)
% hObject    handle to exportOrig2Ws (see GCBO)
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


% --- Executes on button press in exportCurrent2Ws.
function exportCurrent2Ws_Callback(hObject, eventdata, handles)
% hObject    handle to exportCurrent2Ws (see GCBO)
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


% --- Executes on button press in exportOrig2Fil.
function exportOrig2Fil_Callback(hObject, eventdata, handles)
% hObject    handle to exportOrig2Fil (see GCBO)
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

% Save to file
save(fullfile(handles.storePath, char(strcat(handles.machineId, name, '.mat'))), ...
     '-struct', 'handles', 'stackOrig');
 
guidata(hObject, handles);


% --- Executes on button press in exportCurr2Fil.
function exportCurr2Fil_Callback(hObject, eventdata, handles)
% hObject    handle to exportCurr2Fil (see GCBO)
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

% Save to file
save(fullfile(handles.storePath, char(strcat(handles.machineId, name, '.mat'))), ...
     '-struct', 'handles', 'stackImg');

guidata(hObject, handles);





% --- Executes on button press in exportOrig2Tif.
function exportOrig2Tif_Callback(hObject, eventdata, handles)
% hObject    handle to exportOrig2Tif (see GCBO)
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

% Extract the current time slice
data = handles.stackOrig(:, :, :, handles.stackIdx);

% Normalize and scale to 16-bit
data = uint16(65535 * (data - min(data(:))) / (max(data(:)) - min(data(:))));

% Save current time to tiff file
for sliceIdx = 1:handles.sliceNum
    imwrite(data(:, :, sliceIdx), ...
            fullfile(handles.storePath, ...
                     char(strcat(handles.machineId, ...
                                 name, ...
                                 '-t', ...
                                 num2str(handles.stackIdx), ...
                                 '.tif'))), ...
            'WriteMode', 'append');
end

guidata(hObject, handles);


% --- Executes on button press in exportCurr2Tiff.
function exportCurr2Tiff_Callback(hObject, eventdata, handles)
% hObject    handle to exportCurr2Tiff (see GCBO)
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

% Extract the current time slice
data = handles.stackOrig(:, :, :, handles.stackIdx);

% Normalize and scale to 16-bit
data = uint16(65535 * (data - min(data(:))) / (max(data(:)) - min(data(:))));

% Save current time to tiff file
for sliceIdx = 1:handles.sliceNum
    imwrite(data(:, :, sliceIdx), ...
            fullfile(handles.storePath, ...
                     char(strcat(handles.machineId, ...
                                 name, ...
                                 '-t', ...
                                 num2str(handles.stackIdx), ...
                                 '.tif'))), ...
            'WriteMode', 'append');
end

guidata(hObject, handles);


% --- Executes on button press in loadLatest.
function loadLatest_Callback(hObject, eventdata, handles)
% hObject    handle to loadLatest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

load(fullfile(handles.storePath, handles.lastExpFile), 'path');

% Open and read the stack
handles = openExperiment(handles, path);

% Configure the stack for visualization
handles = configStack(handles);

% Update display
handles = updateGui(handles);

guidata(hObject, handles);



% --- Executes on button press in loadVariable.
function loadVariable_Callback(hObject, eventdata, handles)
% hObject    handle to loadVariable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% If expInfo exists, clear it
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


% --- Executes on button press in loadFile.
function loadFile_Callback(hObject, eventdata, handles)
% hObject    handle to loadFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% If expInfo exists, clear it
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





% --- Executes on button press in clear.
function clear_Callback(hObject, eventdata, handles)
% hObject    handle to clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

try
    set(handles.img, 'CData', handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx));    
catch ME
end

guidata(hObject, handles);


% --- Executes on button press in selPoint.
function selPoint_Callback(hObject, eventdata, handles)
% hObject    handle to selPoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of selPoint
handles = guidata(hObject);
    
handles.selection.mode = 'point';

guidata(hObject, handles);


% --- Executes on button press in selLine.
function selLine_Callback(hObject, eventdata, handles)
% hObject    handle to selLine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of selLine
handles = guidata(hObject);
    
handles.selection.mode = 'line';

guidata(hObject, handles);


% --- Executes on button press in selRect.
function selRect_Callback(hObject, eventdata, handles)
% hObject    handle to selRect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of selRect
handles = guidata(hObject);
    
handles.selection.mode = 'rectangle';

guidata(hObject, handles);


% --- Executes on button press in selCircle.
function selCircle_Callback(hObject, eventdata, handles)
% hObject    handle to selCircle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of selCircle
handles = guidata(hObject);
    
handles.selection.mode = 'circle';

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
                        msgbox(txt);
                        handles.drawing.active = true;
                        handles.drawing.line = imline(handles.mainAx, ...
                                                      [handles.posIdx(1), handles.posIdx(1) + 10], ...
                                                      [handles.posIdx(2), handles.posIdx(2) + 10]);
                        handles.drawing.line.setColor('green');
                        handles.drawing.line.addNewPositionCallback(@(pos)analyzeLine(pos, handles));
                    end
                end
            case 'open'
                handles.drawing.active = false;
                handles.drawing.line.delete();
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
catch ME
end

guidata(hObject, handles);
