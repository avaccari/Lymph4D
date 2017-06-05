% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% --- Analyze the data when a point is placed on the image
function handles = analyzePoint(handles)
figure(1);
hold all;
plot(squeeze(handles.stackOrig(handles.posIdx(2), handles.posIdx(1), handles.sliceIdx, :)));
txt = strcat('Evolution over time of selected points (Slice:', ...
             mat2str(handles.sliceIdx), ...
             ')');
title(txt);
ylabel('Amplitude');
xlabel('Time');

