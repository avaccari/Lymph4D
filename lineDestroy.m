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

% Destroy the analysis line
function handles = lineDestroy(handles)
handles.drawing.active = false;

handles.drawing.line.delete();
handles.drawing.textS.delete();
handles.drawing.textE.delete();

% Actually remove the fields
drw = handles.drawing;
drw = rmfield(drw, {'line', ...
                    'textS', ...
                    'textE'});

if isfield(handles, 'tmpl')
    handles.drawing.lineTmpl.delete();
    drw = rmfield(drw, 'lineTmpl');
end

handles.drawing = drw;

try
    close(handles.figLine);
catch ME
end

