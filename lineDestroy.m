% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

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

