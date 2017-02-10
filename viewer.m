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

% Last Modified by GUIDE v2.5 10-Feb-2017 17:47:43

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
handles.lastExpFile = 'lastExp.mat';

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

% Store path and files for fast access
[storePath, ~, ~] = fileparts(mfilename('fullpath'));
save(fullfile(storePath, handles.lastExpFile), 'path');

% Open and read the stack
handles = openExperiment(handles, path);

guidata(hObject, handles);



function handles = configStack(handles)
img = handles.stackOrig;
[~, ~, handles.stackNum, handles.sliceNum] = size(img);

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

% Update display
handles = updateGui(handles);


% --- Executes on slider movement.
function sliceSlider_Callback(hObject, eventdata, handles)
% hObject    handle to sliceSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles = guidata(hObject);

% Update image when user use the slider
dx = 1.0 / (handles.sliceNum - 1);
idx = 1 + floor(get(hObject, 'Value') / dx);
if idx ~= handles.sliceIdx
    handles.sliceIdx = idx;
    set(handles.img, 'CData', handles.stackImg(:, :, handles.stackIdx, idx));    

    % Update display
    handles = updateGui(handles);

    guidata(hObject, handles);
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
dx = 1.0 / (handles.stackNum - 1);
idx = 1 + floor(get(hObject, 'Value') / dx);
if idx ~= handles.stackIdx
    handles.stackIdx = idx;
    set(handles.img, 'CData', handles.stackImg(:, :, idx, handles.sliceIdx));    

    % Update display
    handles = updateGui(handles);

    guidata(hObject, handles);
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

type = get(hObject,'SelectionType');
switch type
    case 'normal' % Left Single-Click
        if handles.onImage
            figure(1); 
            hold all;
            plot(squeeze(handles.stackOrig(handles.posIdx(2), handles.posIdx(1), :, handles.sliceIdx)));
        end
    case 'open' % Left Double-Click

end

guidata(hObject, handles);


% --- Update array indexing
function handles = updateIdx(handles)
try
    pos = [handles.posIdx(2), ...
           handles.posIdx(1), ...
           handles.stackIdx, ...
           handles.sliceIdx];
    handles.arrayIdx = num2cell(pos);
catch ME
end


% --- Update GUI
function handles = updateGui(handles)
handles = updateTxtSliceIdx(handles);
handles = updateTxtStackIdx(handles);
handles = updateTxtPosIdx(handles);


% --- Update index indicator
function handles = updateTxtSliceIdx(handles)
try
    txt = strcat('sl:', ...
                 num2str(handles.sliceIdx, '%03u'), ...
                 '/', ...
                 num2str(handles.sliceNum, '%03u'));

    set(handles.txtSliceIdx, 'String', txt);
catch ME
end


% --- Update time indicator
function handles = updateTxtStackIdx(handles)
try
    txt = strcat('st:', ...
                 num2str(handles.stackIdx, '%03u'), ...
                 '/', ...
                 num2str(handles.stackNum, '%03u'));

    set(handles.txtStackIdx, 'String', txt);
catch ME
end


% --- Update position indicator
function handles = updateTxtPosIdx(handles)
try
    txt = strcat('(', ...
                 num2str(handles.posIdx(1), '%03u'), ...
                 ',', ...
                 num2str(handles.posIdx(2), '%03u'), ...
                 ',', ...
                 num2str(handles.stackIdx, '%03u'), ...
                 ',', ...
                 num2str(handles.sliceIdx, '%03u'), ...
                 ')-', ...
                 num2str(handles.stackOrig(handles.arrayIdx{:}), '%04u'));
             
     set(handles.txtPosIdx, 'String', txt);
catch ME
end
