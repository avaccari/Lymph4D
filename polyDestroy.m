% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% Destroy the analysis line
function handles = polyDestroy(handles)
handles.drawing.active = false;
handles.drawing.poly.delete();
if isfield(handles, 'tmpl')
    handles.drawing.polyTmpl.delete();
end
try
    close(handles.figPoly);
catch ME
end

