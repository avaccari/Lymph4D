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

% --- Analyze the data when a point is placed on the image
function handles = pointAnalyze(handles)
figure(1);
hold all;
plot(squeeze(handles.stackOrig(handles.posIdx(2), handles.posIdx(1), handles.sliceIdx, :)));
txt = strcat('Evolution over time of selected points (Slice:', ...
             mat2str(handles.sliceIdx), ...
             ')');
title(txt);
ylabel('Amplitude');
xlabel('Time');

