% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% Handle line template operations
function handles = analysisTmpls(handles, objType, operation)

        
% Switch based on template operation
switch operation   
    % Save template
    case 'save'
        % Switch based on template type
        switch objType
            % We are handling lines
            case 'line'
                if ~(isfield(handles.drawing, 'line') && isvalid(handles.drawing.line))
                    return
                end

            % We are handling polygons
            case 'poly'
                if ~(isfield(handles.drawing, 'poly') && isvalid(handles.drawing.poly))
                    return
                end

             % Should never end up here
            otherwise
                txt = {'Template type invalid:', ...
                       ['"', objType, '"']};
                uiwait(msgbox(txt));
                return
        end       
        prompt = ['Enter name for this ', objType, ':'];
        var = inputdlg(prompt, 'Enter name');

        % Check if the answer is valid. If not bail.
        if isempty(var)
            return
        elseif isempty(var{1})
            return
        end

        var = [objType, '_', matlab.lang.makeValidName(var{1})];
        eval([var ['= handles.drawing.', objType, '.getPosition();']]);    
        file = fullfile(handles.storePath, handles.lastExpFile);

        if exist(file, 'file')
            save(file, var, '-append');
        else
            save(file, var);
        end

    % Load template
    case 'load'
        % Check if there is already a template on the screen.
        if handles.drawing.active
            uiwait(msgbox('Close existing analysis tools before loading a template.'));
            return
        end
        
        try
            file = fullfile(handles.storePath, handles.lastExpFile);
            rexp = ['^', objType, '_*'];
            vars = who('-file', file, '-regexp', rexp); 
        catch ME
            uiwait(msgbox(['Cannot locate file containing latest ', objType, ' information']));
            return
        end

        % If no objects are stored, notify user
        if isempty(vars)
            txt = ['There is no ', objType, ' stored.'];
            uiwait(msgbox(txt));
            return
        end
        
        % If more than one object exists, ask user to pick the one they want
        if length(vars) > 1
            [s, v] = listdlg('PromptString', ['Select the desired ', objType, ':'], ...
                             'SelectionMode', 'single', ...
                             'ListString', vars);

            % If error, bail
            if v == 0
                uiwait(msgbox(['There was an error during the ', objType, ' selection process.']));
                return
            end

            obj = vars{s};
        else
            obj = vars{1};
        end

        load(file, obj);
        
        switch objType
            case 'line'
                handles = lineCreate(eval(obj)', handles);
                handles.selLineRbtn.Value = 1.0;
            case 'poly'
                handles = polyCreate(handles, eval(obj));
                handles.selPolyRbtn.Value = 1.0;
        end

        handles.selection.mode = objType;

        
    % Delete template
    case 'delete'
        try
            file = fullfile(handles.storePath, handles.lastExpFile);
            rexp = ['^', objType, '_*'];
            vars = who('-file', file, '-regexp', rexp); 
        catch ME
            msgbox(['Cannot locate file containing latest ', objType, ' information']);
            return
        end

        % If no objects are stored, notify user
        if isempty(vars)
            txt = ['There is no ', objType, ' stored.'];
            uiwait(msgbox(txt));
            return
        end

        % Ask user to pick the ones they want to delete
        [s, v] = listdlg('PromptString', ['Select ', objType, '(s) to delete:'], ...
                         'SelectionMode', 'multiple', ...
                         'ListString', vars);

        % If error, bail
        if v == 0
            uiwait(msgbox(['There was an error during the ', objType, ' selection process.']));
            return
        end

        % Short of making your own MEX, there is no quick way to remove variables
        % from a .mat file so we load, delete, and save.
        mat = load(file);

        for i = 1:length(s)
            mat = rmfield(mat, vars{s(i)});
        end

        save(file, '-struct', 'mat'); 
        
    % Should never end up here
    otherwise
        txt = {'Template operation invalid:', ...
               ['"', operation, '"']};
        uiwait(msgbox(txt));
end
