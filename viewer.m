% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

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

% Last Modified by GUIDE v2.5 04-Oct-2017 23:36:57

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

% Initialisation of POI Libs
% Add Java POI Libs to matlab javapath
if isdeployed == false
    [loc, ~, ~] = fileparts(mfilename('fullpath'));
    javaaddpath([loc, '/3rdParty/xlwrite/poi_library/poi-3.8-20120326.jar']);
    javaaddpath([loc, '/3rdParty/xlwrite/poi_library/poi-ooxml-3.8-20120326.jar']);
    javaaddpath([loc, '/3rdParty/xlwrite/poi_library/poi-ooxml-schemas-3.8-20120326.jar']);
    javaaddpath([loc, '/3rdParty/xlwrite/poi_library/xmlbeans-2.3.0.jar']);
    javaaddpath([loc, '/3rdParty/xlwrite/poi_library/dom4j-1.6.1.jar']);
    javaaddpath([loc, '/3rdParty/xlwrite/poi_library/stax-api-1.0.1.jar']);
    addpath([loc, '/3rdParty/xlwrite']);
    addpath([loc, '/3rdParty/colorcet']);
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

handles.direction.mapType = 1;
handles.direction.hoodSiz = 3;
handles.direction.useHood = false;


% Figures id
handles.figs.lineAnalyze = 1;
handles.figs.evalVelocity = 2;
handles.figs.polyAnalyze = 3;
handles.figs.dirMap = 4;


% Get unique id
handles.machineId = getUniqueId();
handles.lastExpFile = char(strcat(handles.machineId, 'lastExp.mat'));

% Create a list of available colormaps
% Eventually you might want to actually parse the following file
%   fullfile(matlabroot, 'toolbox', 'matlab', 'graph3d', 'Contents.m');
handles.cmaps = {'parula', 'hsv', 'hot', 'gray', 'bone', 'copper', 'pink', ...
                 'white', 'flag', 'lines', 'colorcube', 'vga', 'jet', ...
                 'prism', 'cool', 'autumn', 'spring', 'winter', 'summer'};

% Define single-sided percentage to be considered outliers
handles.outliers = 1.;
handles.cOut = [handles.outliers, 100 - handles.outliers];

             
% Add copyright info
txt = {'Copyright (C) 2017 Andrea Vaccari', ...
       '', ...
       'This program is free software: you can redistribute it and/or modify', ...
       'it under the terms of the GNU General Public License as published by', ...
       'the Free Software Foundation, either version 3 of the License, or', ...
       'any later version.', ...
       'This program is distributed in the hope that it will be useful,', ...
       'but WITHOUT ANY WARRANTY; without even the implied warranty of', ...
       'MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the', ...
       'GNU General Public License for more details.', ...
       '', ...
       'You should have received a copy of the GNU General Public License', ...
       'along with this program.  If not, see <http://www.gnu.org/licenses/>.', ...
       '', ...
       'For "xlwrite":',...
       'Copyright (C) 2013 Alec de Zegher', ...
       'Redistribution and use in source and binary forms, with or without', ...
       'modification, are permitted provided that the following conditions are', ...
       'met:', ...
       '', ...
       '    * Redistributions of source code must retain the above copyright', ...
       '      notice, this list of conditions and the following disclaimer.', ...
       '    * Redistributions in binary form must reproduce the above copyright', ...
       '      notice, this list of conditions and the following disclaimer in', ...
       '      the documentation and/or other materials provided with the distribution', ...
       '', ...
       'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"', ...
       'AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE', ...
       'IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE', ...
       'ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE', ...
       'LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR', ...
       'CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF', ...
       'SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS', ...
       'INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN', ...
       'CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)', ...
       'ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE', ...
       'POSSIBILITY OF SUCH DAMAGE.', ...
       '', ...
       '"xlwrite" uses the Apache POI library under the', ...
       'Apache License, Version 2.0, January 2004', ...
       'http://www.apache.org/licenses/', ...
       '', ...
       'Some of the colormaps upsed were designed by Peter Kovesi:', ...
       'Peter Kovesi. Good Colour Maps: How to Design Them.', ...
       'arXiv:1509.03700 [cs.GR] 2015'};
   
uicontrol('parent', handles.mainGui, ...
         'style', 'text', ...
         'string', ['Lymph4D ', char(169), '2017 - Andrea Vaccari'], ...
         'units', 'normalized', ...
         'position', [0.85, 0.0, 0.15, 0.025], ...
         'enable', 'inactive', ...
         'ButtonDownFcn', @(src, evt)msgbox(txt, 'Copyright'));
             
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
try
    load(fullfile(handles.storePath, handles.lastExpFile), 'path');
catch ME
end

if exist('path', 'var')
    path = uigetdir(path);
else
    path = uigetdir();
end
if path == 0
    return
end

% Open and read the stack
try
    handles = openExperiment(handles, path);
catch ME
    msgbox(getReport(ME, 'extended', 'hyperlinks', 'off'));
    return
end

% Store path and experiment info for fast access
file = fullfile(handles.storePath, handles.lastExpFile);
if exist(file, 'file')
    save(file, 'path', '-append');
else
    save(file, 'path');
end
    
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
if fName == 0
    return
end
                       
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




% --- Executes on button press in dicomInfoBtn.
function dicomInfoBtn_Callback(hObject, eventdata, handles)
% hObject    handle to dicomInfoBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles = showImageInfo(handles);

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
function stackSlider_CreateFcn(hObject, ~, handles)
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

handles = configStack(handles);

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


% --- Executes on button press in selPolyRbtn.
function selPolyRbtn_Callback(hObject, eventdata, handles)
% hObject    handle to selPolyRbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of selPolyRbtn
handles = guidata(hObject);
    
handles.selection.mode = 'poly';

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
    lineAnalyze(handles.drawing.line.getPosition, handles.mainGui);
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
    lineAnalyze(handles.drawing.line.getPosition, handles.mainGui);
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
    lineAnalyze(handles.drawing.line.getPosition, handles.mainGui);
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



% --- Executes on button press in lineSaveBtn.
function lineSaveBtn_Callback(hObject, eventdata, handles)
% hObject    handle to lineSaveBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles = analysisTmpls(handles, 'line', 'save');

guidata(hObject, handles);



% --- Executes on button press in lineLoadBtn.
function lineLoadBtn_Callback(hObject, eventdata, handles)
% hObject    handle to lineLoadBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles = analysisTmpls(handles, 'line', 'load');

guidata(hObject, handles);




% --- Executes on button press in lineDelBtn.
function lineDelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to lineDelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles = analysisTmpls(handles, 'line', 'delete');

guidata(hObject, handles);


% --- Executes on button press in polySaveBtn.
function polySaveBtn_Callback(hObject, eventdata, handles)
% hObject    handle to polySaveBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles = analysisTmpls(handles, 'poly', 'save');

guidata(hObject, handles);


% --- Executes on button press in polyLoadBtn.
function polyLoadBtn_Callback(hObject, eventdata, handles)
% hObject    handle to polyLoadBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles = analysisTmpls(handles, 'poly', 'load');

guidata(hObject, handles);


% --- Executes on button press in polyDelBtn.
function polyDelBtn_Callback(hObject, eventdata, handles)
% hObject    handle to polyDelBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

handles = analysisTmpls(handles, 'poly', 'delete');

guidata(hObject, handles);






% --- Executes on button press in dirMapBtn.
function dirMapBtn_Callback(hObject, eventdata, handles)
% hObject    handle to dirMapBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
try
    handles = directionMap(handles);
catch ME
    msgbox(getReport(ME, 'extended', 'hyperlinks', 'off'));
    return
end

guidata(hObject, handles);



% --- Executes on selection change in setDirMapTypPop.
function setDirMapTypPop_Callback(hObject, eventdata, handles)
% hObject    handle to setDirMapTypPop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns setDirMapTypPop contents as cell array
%        contents{get(hObject,'Value')} returns selected item from setDirMapTypPop
handles = guidata(hObject);

% Choices (defined in guide):
% 1 - 'Time Contr.'
% 2 - 'Anis. Difs'
% 3 - 'Difs-Adv.'
% 4 - 'Difs-Adv.+Src'
% 5 - 'Comp. Mods'
handles.direction.mapType = get(hObject, 'Value');

% Need to push the data so that it is available in handles.mainGui
guidata(hObject, handles);





% --- Executes during object creation, after setting all properties.
function setDirMapTypPop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to setDirMapTypPop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in setDIrHoodChk.
function setDIrHoodChk_Callback(hObject, eventdata, handles)
% hObject    handle to setDIrHoodChk (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of setDIrHoodChk
handles = guidata(hObject);

handles.direction.useHood = get(hObject, 'Value');

% Need to push the data so that it is available in handles.mainGui
guidata(hObject, handles);




function setDirHoodSizEd_Callback(hObject, eventdata, handles)
% hObject    handle to setDirHoodSizEd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of setDirHoodSizEd as text
%        str2double(get(hObject,'String')) returns contents of setDirHoodSizEd as a double
handles = guidata(hObject);

hoodSiz = str2double(get(hObject, 'String'));

% Check if odd, otherwise round to closest odd.
if hoodSiz < 3
    hoodSiz = 3;
end

if hoodSiz > 3
    if hoodSiz/2 == int8(hoodSiz/2)
        hoodSiz = hoodSiz + 1;
    end
end

% Update gui
set(hObject, 'String', num2str(hoodSiz));

handles.direction.hoodSiz = hoodSiz;

% Need to push the data so that it is available in handles.mainGui
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function setDirHoodSizEd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to setDirHoodSizEd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function setDirTempStart_Callback(hObject, eventdata, handles)
% hObject    handle to setDirTempStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of setDirTempStart as text
%        str2double(get(hObject,'String')) returns contents of setDirTempStart as a double
handles = guidata(hObject);

val = str2double(get(hObject,'String'));
if val < 1
    val = 1;
elseif val > handles.dirTempEnd
    val = handles.dirTempEnd;
end

handles.dirTempStart = val;
set(handles.setDirTempStart, 'String', num2str(handles.dirTempStart));

% Need to push the data so that it is available in handles.mainGui
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function setDirTempStart_CreateFcn(hObject, eventdata, handles)
% hObject    handle to setDirTempStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end





function setDirTempEnd_Callback(hObject, eventdata, handles)
% hObject    handle to setDirTempEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of setDirTempEnd as text
%        str2double(get(hObject,'String')) returns contents of setDirTempEnd as a double
handles = guidata(hObject);

val = str2double(get(hObject,'String'));
if val > handles.stackNum
    val = handles.stackNum;
elseif val < handles.dirTempStart
    val = handles.dirTempStart;
end

handles.dirTempEnd = val;
set(handles.setDirTempEnd, 'String', num2str(handles.dirTempEnd));

% Need to push the data so that it is available in handles.mainGui
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function setDirTempEnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to setDirTempEnd (see GCBO)
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
handles.stackTmplOrig = handles.stackImg;
handles.stackTmpl = handles.stackImg;
handles.tmplCLims = handles.stackCLims;

% If available, copy experiment info to template
try
    handles.tmplInfo = handles.expInfo;
catch ME
end


% Show current image
axes(handles.tmplAx);
handles.tmpl = imagesc(handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx), handles.tmplCLims);
colormap(handles.tmplAx, colormap(handles.mainAx));
pos = get(handles.tmplAx, 'Position');
handles.tmplCBar = colorbar('location', 'south', ...
                            'FontSize', 8, ...
                            'AxisLocation', 'in', ...
                            'Color', [0.5, 0.5, 0.5], ...
                            'Position', [pos(1), pos(2), pos(3), pos(4) * 0.02]);

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

% Delete colorbar
delete(handles.tmplCBar);

% Remove from handles
handles = rmfield(handles, {'stackTmplOrig', ...
                            'stackTmpl', ...
                            'tmpl'});

% Try to delete the template info
try
    rmfield(handles, 'tmplInfo');
catch ME
end
                        
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
imagesc(imfuse(fixed, moving, 'Scaling', 'joint'));
set(gca,'visible','off');
title('Before');
axis equal;

subplot(1, 2, 2);
imagesc(imfuse(fixed, movingReg, 'Scaling', 'joint'));
set(gca,'visible','off');
title('After');
axis equal;

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

% Align the 4D cubes
for sliceIdx = 1 : handles.sliceNum
    for stackIdx = 1 : handles.stackNum
        try
            reg = imwarp(handles.stackImg(:, :, sliceIdx, stackIdx), ...
                         tform, ...
                         'OutputView', imref2d(size(moving)), ...
                         'Interp', 'cubic');
            handles.stackImg(:, :, sliceIdx, stackIdx) = reg;
        catch ME
        end
    end
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



% --- Executes on button press in rmBaselnBtn.
function rmBaselnBtn_Callback(hObject, eventdata, handles)
% hObject    handle to rmBaselnBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Notify user that saving is ongoing
h = msgbox('Removing baseline...');

% Use first temporal stack as baseline
handles.stackImg = handles.stackImg - repmat(handles.stackImg(:, :, :, 1), 1, 1, 1, handles.stackNum);

% Change the colorscale to improve contrast
q = prctile(handles.stackImg(:), handles.cOut);
handles.stackCLims = [q(1), q(2)];
set(handles.mainAx, 'CLim', handles.stackCLims);

% Update the image
set(handles.img, 'CData', handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx));

% If the template exists ask if it should be processed as well
if isfield(handles, 'tmpl')
    answ = questdlg('Process also the template (with its own baseline)?', ...
                    'Process template', ...
                    'Yes', 'No', 'Yes');
    switch answ
        case 'Yes'
            handles.stackTmpl = handles.stackTmpl - repmat(handles.stackTmpl(:, :, :, 1), 1, 1, 1, handles.stackNum);
            
            % Change the colorscale to improve contrast
            q = prctile(handles.stackTmpl(:), handles.cOut);
            handles.tmplCLims = [q(1), q(2)];
            set(handles.tmplAx, 'CLim', handles.tmplCLims);

            % Update the image
            set(handles.tmpl, 'CData', handles.stackTmpl(:, :, handles.sliceIdx, handles.stackIdx));
            
        case 'No'
    end
end


% Update array indexing
handles = updateIdx(handles);

% Update display
handles = updateGui(handles);

% Remove notification
try
    delete(h);
catch ME
end

guidata(hObject, handles);


% --- Executes on button press in eqScalesBtn.
function eqScalesBtn_Callback(hObject, eventdata, handles)
% hObject    handle to eqScalesBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Evaluate the data ranges within the two images
q = prctile(handles.stackImg(:), handles.cOut);
if isfield(handles, 'tmpl')
    qt = prctile(handles.stackTmpl(:), handles.cOut);
    q(1) = min(q(1), qt(1));
    q(2) = max(q(2), qt(2));
    handles.tmplCLims = q;
    set(handles.tmplAx, 'CLim', handles.tmplCLims);
end
handles.stackCLims = q;
set(handles.mainAx, 'CLim', handles.stackCLims);


% Update array indexing
handles = updateIdx(handles);

% Update display
handles = updateGui(handles);

guidata(hObject, handles);


% --- Executes on button press in thresNoiseBtn.
function thresNoiseBtn_Callback(hObject, eventdata, handles)
% hObject    handle to thresNoiseBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Can do some smart evaluation here by looking at the distribution of the
% data that appears to be bimodal. The minimum in between the modes would
% be a good spot to use as threshold.

thrs = 100;

% Threhsold image with the found value and store new mask
handles.stackMask = (handles.stackImg > thrs);
handles.stackImg = handles.stackImg .* handles.stackMask;

% Update image
set(handles.img, 'CData', handles.stackImg(:, :, handles.sliceIdx, handles.stackIdx));  

% Update array indexing
handles = updateIdx(handles);

% Update display
handles = updateGui(handles);

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
                    handles = pointAnalyze(handles);
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
                               'To remove the line, double-click on it.'};
                        uiwait(msgbox(txt));
                        startPos = [handles.posIdx(1), handles.posIdx(1) + 10; ...
                                    handles.posIdx(2), handles.posIdx(2) + 10];
                        handles = lineCreate(startPos, handles);
                    end
                end
            case 'open'
                handles = lineDestroy(handles);
        end
    case 'poly'
        switch handles.buttonType
            case 'normal'
                if handles.onImage
                    if ~handles.drawing.active
                        txt = {'Click on the image to add new vertices.', ...
                               'To close the polygon, click on the first vertex.', ...
                               'The temporal evolution will be shown in real', ...
                               'time as the vertices are moved. To remove the', ... 
                               'polygon, double click on it.'};
                        uiwait(msgbox(txt));
                        handles = polyCreate(handles);
                    end
                end
            case 'open'
                handles = polyDestroy(handles);
        end
end


guidata(hObject, handles);




% --------------------------------------------------------------------
% MENU
% --------------------------------------------------------------------

% --------------------------------------------------------------------
function mOpt_Callback(hObject, eventdata, handles)
% hObject    handle to mOpt (see GCBO)
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
function mOptSaturation_Callback(hObject, eventdata, handles)
% hObject    handle to mOptSaturation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);

% Check status, toggle and modify range
if strcmp(get(hObject, 'Checked'), 'on')
    set(hObject, 'Checked', 'off');
    handles.cOut = [0, 100];
else
    set(hObject, 'Checked', 'on');
    handles.cOut = [handles.outliers, 100 - handles.outliers];
end

% Update color limits on image and template
q = prctile(handles.stackImg(:), handles.cOut);
handles.stackCLims = q;
set(handles.mainAx, 'CLim', handles.stackCLims);
if isfield(handles, 'tmpl')
    q = prctile(handles.stackTmpl(:), handles.cOut);
    handles.tmplCLims = q;
    set(handles.tmplAx, 'CLim', handles.tmplCLims);
end

guidata(hObject, handles);





% --------------------------------------------------------------------
function mExp_Callback(hObject, eventdata, handles)
% hObject    handle to mExp (see GCBO)
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
