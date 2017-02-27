% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% --- Analyze the data when a line is traced on the image
function handles = analyzeLine(pos, handles)
figure(2);
subplot(2, 1, 1);
colrs = jet(handles.stackNum);
hold off;

% Plot the the cross section evolution over time
for stk = 1 : handles.stackNum
    img = squeeze(handles.stackOrig(:, :, handles.sliceIdx, stk));
    plot(improfile(img, pos(:, 1), pos(:, 2)), 'color', colrs(stk, :)); 
    hold on;
end
txt = strcat('Evolution over time of cross section (Slice: ', ...
             mat2str(handles.sliceIdx), ...
             ') (Blue \rightarrow Red)');
title(txt);
ylabel('Amplitude');
txt = strcat('Points along cross section:', ...
              mat2str(round(pos(1, :))), ...
              '\rightarrow', ...
              mat2str(round(pos(2, :))));
xlabel(txt);



% Extract coordinates of points in the cross section
figure(2);
subplot(2, 1, 2);
[cx, cy, ~] = improfile(img, pos(:, 1), pos(:, 2));
lcx = length(cx);
colrs = jet(lcx);
hold off;

% Plot the time evolution of each point in the cross section
for pnt = 1 : lcx
    c = round(cx(pnt));
    r = round(cy(pnt));
    plot(squeeze(handles.stackOrig(r, c, handles.sliceIdx, :)), ...
         'color', colrs(pnt, :));
%     plot(squeeze(mean(mean(handles.stackOrig(r-2:r+2, c-2:c+2, handles.sliceIdx, :), 1), 2)), ...
%          'color', colrs(pnt, :));
    hold on;
end
txt = strcat('Evolution over time of points in the cross section: (Slice: ', ...
             mat2str(handles.sliceIdx), ...
             ') (Blue \rightarrow Red)');
title(txt);
ylabel('Amplitude');
xlabel('Time');


    


