% --- Analyze the data when a line is traced on the image
function handles = analyzeLine(pos, handles)
figure(2);
colrs = jet(handles.stackNum);
hold off;
for stk = 1 : handles.stackNum
    img = squeeze(handles.stackOrig(:, :, handles.sliceIdx, stk));
    plot(improfile(img, pos(:, 1), pos(:, 2)), 'color', colrs(stk, :)); 
    hold on;
end
txt = strcat('Evolution over time of cross section: ', ...
             mat2str(round(pos(1, :))), ...
             '-', ...
             mat2str(round(pos(2, :))), ...
             ' (Blue \rightarrow Red)');
title(txt);




