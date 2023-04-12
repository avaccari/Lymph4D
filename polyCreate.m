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

% --- Create the analysis lines
function handles = polyCreate(handles, varargin)
handles.drawing.active = true;
% Need to push data back to handles because impoly is interactive and will
% run in parallel with the main gui causing the polyCreate to be triggered
% at every click if the active is not set to true.
guidata(handles.mainGui, handles);

% This will only exit after the user is done drawing
if isempty(varargin)
    handles.drawing.poly = impoly(handles.mainAx);
else
    handles.drawing.poly = impoly(handles.mainAx, varargin{1});
end
% Define callback
handles.drawing.poly.addNewPositionCallback(@(pos)polyAnalyze(pos, handles.mainGui));

% If there is a template, create a cloned line for
% comparison
if isfield(handles, 'tmpl')
    handles.drawing.polyTmpl = impoly(handles.tmplAx, ...
                                      handles.drawing.poly.getPosition());
end

% Push data to gui before calling lineAnalyze
guidata(handles.mainGui, handles);
handles = polyAnalyze(handles.drawing.poly.getPosition(), handles.mainGui);
guidata(handles.mainGui, handles);

