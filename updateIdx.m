% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% Update array indexing
function handles = updateIdx(handles)
try
    pos = [handles.posIdx(2), ...
           handles.posIdx(1), ...
           handles.sliceIdx, ...
           handles.stackIdx];
    handles.arrayIdx = num2cell(pos);
catch ME
end

