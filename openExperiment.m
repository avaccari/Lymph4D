% --- Open and read the stack files
function handles = openExperiment(handles, path)

% Bail if there is no experiment
if exist(path, 'dir') == 0
    msgbox(strcat({'The experiment:' path 'is no longer available!'}));
    return
end

list = dir(path);

% Remove directories
list([list.isdir]) = [];

% Sort based on file name (filed 1)
flds = fieldnames(list);
tmp = struct2cell(list);
sz = size(tmp);
tmp = reshape(tmp, sz(1), [])';
tmp = sortrows(tmp, 1);
tmp = reshape(tmp', sz);
list = cell2struct(tmp, flds, 1);

% Extract the stack and slice number from each file and store in structure
rex = '^(.*?\.)(\d{4})\.(\d{4})\.(.*)$';
stackMin = inf;
stackMax = -inf;
sliceMin = inf;
sliceMax = -inf;
oldStack = inf;
stackNum = 0;
ex = struct();
for i = 1:length(list)
    tk = regexp(list(i).name, rex, 'tokens');
    if ~isempty(tk)
        stack = str2double(tk{1, 1}{1, 2});
        if stack < stackMin
            stackMin = stack;
        end
        if stack > stackMax
            stackMax = stack;
        end
        slice = str2double(tk{1, 1}{1, 3});
        if slice < sliceMin
            sliceMin = slice;
        end
        if slice > sliceMax
            sliceMax = slice;
        end
        if stack ~= oldStack
            stackNum = stackNum + 1;
            ex(stackNum).files = list(i);
            ex(stackNum).stack = stack;
            oldStack = stack;
        else
            ex(stackNum).files = [ex(stackNum).files list(i)];
            ex(stackNum).slices = slice;
        end
    end
end

% Drop the stacks with less than max number of slices?  
ex([ex.slices] < sliceMax) = [];
stackNum = length(ex);
handles.stackList = [ex.stack];

% Read the first image and use it as template to preallocate the stack
stackIdx = 1;
sliceIdx = 1;
fil = char(fullfile(path, ex(stackIdx).files(sliceIdx).name));
img1 = dicomread(fil);
img = zeros([size(img1), sliceMax, stackNum]);
img(:, :, sliceIdx, stackIdx) = img1;

% Read the structure containing the file info (only the first file)
handles.expInfo.full = dicominfo(fil);
if isfield(handles.expInfo.full, 'SeriesDescription')
    handles.expInfo.expName = handles.expInfo.full.SeriesDescription;
    expInfo = regexprep(handles.expInfo.full.SeriesDescription, '( |-)+', '_');
    expInfo = regexprep(expInfo, '_+', '_');
    handles.expInfo.expNameExp = expInfo;
end

% Load and store the stack
for st = 1 : stackNum
    for sl = 1 : sliceMax
        fil = char(fullfile(path, ex(st).files(sl).name));
        if exist(fil, 'file') == 0
            msgbox(strcat({'The file:' fil 'is no longer available!'}));
            return
        end
        img(:, :, sl, st) = dicomread(fil);
    end
end

% Store original stack
handles.stackOrig = img;