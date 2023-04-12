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
function handles = polyDestroy(handles)
handles.drawing.active = false;

handles.drawing.poly.delete();

% Actually remove the fields
drw = handles.drawing;
drw = rmfield(drw, 'poly');

if isfield(handles, 'tmpl')
    handles.drawing.polyTmpl.delete();
    drw = rmfield(drw, 'polyTmpl');
end

handles.drawing = drw;

try
    close(handles.figPoly);
catch ME
end

