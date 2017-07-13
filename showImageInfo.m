% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% Evaluate directionality domains within the image
function handles = showImageInfo(handles)

% Extract current slice info
info = handles.expInfo.full(handles.sliceIdx, handles.stackIdx);

% Extract info from structure
keys = char(fieldnames(info));
len = size(keys, 1);
txt = cell(len);
for k = 1:len
    val = eval(['info.' keys(k, :)]);
    if ischar(val)
        sval = [' : ' val];
    elseif isnumeric(val)
        sval = [' : ' num2str(val(1:min(3,end))')];
    else
        sval = ' : ...';
    end
    txt{k} = sprintf('%3d %s', k, [keys(k, :) sval]);
end

h = figure('Units', 'normalized', ...
           'OuterPosition', [0, 0, 0.5, 1]);
uicontrol('Parent', h,...
          'Units', 'normalized',...
          'Position', [0, 0, 1, 1],...
          'Style', 'edit',...
          'Enable', 'inactive',...
          'Max', len, ...
          'FontName', 'FixedWidth', ...
          'HorizontalAlignment', 'left', ...
          'String', txt)

end

