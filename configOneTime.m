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

% --- Configure one-time only global values
function handles = configOneTime(handles)

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

% Figures id
handles.figs.lineAnalyze = 1;
handles.figs.evalVelocity = 2;
handles.figs.polyAnalyze = 3;
handles.figs.dirMap = 4;

% Get unique id
handles.machineId = getUniqueId();
handles.lastExpFile = char(strcat(handles.machineId, 'lastExp.mat'));

% Create a list of available colormaps
cmapDir = fullfile(matlabroot, '/toolbox/matlab/graphics/color/*.m');
cmaps = dir(cmapDir);
cmaps = {cmaps.name};
handles.cmaps = cellfun(@(x) erase(x, '.m'), cmaps, 'UniformOutput', false);

% Start Parallel Pool (if Distrib_Computing_Toolbox is available)
if license('test', 'Distrib_Computing_Toolbox')
    p = gcp('nocreate');
    if isempty(p)
        h = msgbox('Starting parallel pool using the default settings...');
        parpool;
        try
            delete(h);
        catch ME
        end
    end
else
    h = mesgbox('No parallel pool available, using single thread.');
end

% Set default values
handles = configDefaults(handles);

            