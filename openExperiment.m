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

% Preallocate the structure containing the files info
handles.expInfo.full = repmat(dicominfo(fil), sliceMax, stackNum);

% Notify user that saving is ongoing
h = msgbox('Loading experiment...');

% Load and store the stack
for st = 1 : stackNum
    for sl = 1 : sliceMax
        fil = char(fullfile(path, ex(st).files(sl).name));
        if exist(fil, 'file') == 0
            msgbox(strcat({'The file:' fil 'is no longer available!'}));
            return
        end
        img(:, :, sl, st) = dicomread(fil);
        try
            handles.expInfo.full(sl, st) = dicominfo(fil);
        catch ME
        end
    end
end

% Remove notification
try
    delete(h);
catch ME
end

% Extract basic info from dicom file (use first file)
info = handles.expInfo.full(1, 1);

% Extract name info
if isfield(info, 'SeriesDescription')
    handles.expInfo.expName = info.SeriesDescription;
    expInfo = regexprep(info.SeriesDescription, '( |-)+', '_');
    expInfo = regexprep(expInfo, '_+', '_');
    handles.expInfo.expNameExp = expInfo;
end

% Store original stack
handles.stackOrig = img;