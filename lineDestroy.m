% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% Destroy the analysis line
function handles = lineDestroy(handles)
handles.drawing.active = false;
handles.drawing.line.delete();
handles.drawing.textS.delete();
handles.drawing.textE.delete();
if isfield(handles, 'tmpl')
    handles.drawing.lineTmpl.delete();
end
try
    close(handles.figLine);
catch ME
end

