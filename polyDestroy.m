% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

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

