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

function evalVelocity(hObject, eventdata, handles)

% If they exist, remove zero traces
lineVal = handles.lineVal;
lineVal(:, sum(handles.lineVal.^2) == 0) = [];
lineSz = size(lineVal, 2);

% TODO: scaling information should be extracted when importing the DICOM
% file or set to a default of 1 at startup or in the stack configuration
% module. This and other modules should only read the value.
% Suggested variables:
% - handles.expInfo.ds [dr, dc, dz] (Pixel.Spacing from DICOM)
% - handles.expInfo.dt [dt]

% Extract spatial scaling info (from first file)
try
    scaling = [handles.expInfo.full(1, 1).PixelSpacing; ...  % dr, dc ??
               handles.expInfo.full(1, 1).SpacingBetweenSlices]; % dz
    xunits = 'mm';
catch ME
    uiwait(msgbox({'Spatial resolution information not available.', ...
                   'Using pixel and slices as spatial units.'}));
    scaling = [1; 1; 1];
    xunits = 'pixel';
end

% Evaluate distance using MRI units
linePts = handles.linePts - handles.linePts(1,:);
linePts = linePts .* repmat(scaling(1:2)', size(linePts, 1), 1);
dist = sqrt(sum(linePts.^2,2));

% Extract timing information (format hhmmss.ffffff)
try
    time = extractfield(handles.expInfo.full(handles.sliceIdx, :), 'AcquisitionTime');
    tsec = datevec(time, 'HHMMSS.FFF') * [0, 0, 0, 3600, 60, 1]';
    tmin = (tsec - tsec(1)) / 60;
    tunits = 'min';
catch ME
    uiwait(msgbox({'Temporal resolution information not available.', ...
                   'Using frame number as temporal unit.'}));
    tmin = (1:handles.stackNum)';
    tunits = 'frame';
end
tmin(sum(handles.lineVal.^2) == 0) = [];

% Plot distance vs value
fig = figure(handles.figs.evalVelocity);
pltCols = 1;

% Check if there is a template
if isfield(handles, 'tmpl')
    pltCols = 2;
end

% Plot for current stack
s1 = subplot(2, pltCols, 1, 'parent', fig);
colrs = jet(lineSz);
h = plot(dist, lineVal, '.');
set(h, {'color'}, num2cell(colrs, 2));
title('Evolution over time of cross section (Blue \rightarrow Red)');
ylabel('Amplitude');
xlabel(['Distance from first pixel [', xunits, ']']);

% Find maxima and location and identify on plot
[mx, mxIdx] = max(lineVal);
hold(s1, 'on');
scatter(dist(mxIdx), mx, ...
        'Marker', 'x', ...
        'CData', colrs);

% Plot maximum displacement as function of time
dmax = dist - dist(mxIdx(1));
s2 = subplot(2, pltCols, 2, 'parent', fig);
scatter(tmin, dmax(mxIdx), ...
        'CData', colrs);
title('Displacement of maximum over time (Blue \rightarrow Red)');
ylabel(['Displacement of Maximum [', xunits, ']']);
xlabel(['Time [', tunits, ']']);

% Evaluate and plot linear fit
beta = tmin \ dmax(mxIdx);
x = linspace(tmin(1), tmin(end), 100);
y = beta * x;
hold(s2, 'on');
plot(x, y, '--');

% Add text with velocity info
txt = ['\leftarrow Velocity: ', num2str(beta, '%3.2e'), ' [', xunits, '/', tunits, ']'];
text(x(50), y(50), txt);


% Repeat for template
if isfield(handles, 'tmpl')
    % If they exist, remove zero traces
    lineVal = handles.tmplLineVal;
    lineVal(:, sum(handles.tmplLineVal.^2) == 0) = [];
    lineSz = size(lineVal, 2);
    
    % Extract spatial scaling info (from first file)
    try
        scaling = [handles.tmplInfo.full(1, 1).PixelSpacing; ...  % dr, dc ??
                   handles.tmplInfo.full(1, 1).SpacingBetweenSlices]; % dz
        xunits = 'mm';
    catch ME
        uiwait(msgbox({'Spatial resolution information not available.', ...
                       'Using pixel and slices as spatial units.'}));
        scaling = [1; 1; 1];
        xunits = 'pixel';
    end

    % Evaluate distance using MRI units
    linePts = handles.linePts - handles.linePts(1,:);
    linePts = linePts .* repmat(scaling(1:2)', size(linePts, 1), 1);
    dist = sqrt(sum(linePts.^2,2));

    % Extract timing information (format hhmmss.ffffff)
    try
        time = extractfield(handles.tmplInfo.full(handles.sliceIdx, :), 'AcquisitionTime');
        tsec = datevec(time, 'HHMMSS.FFF') * [0, 0, 0, 3600, 60, 1]';
        tmin = (tsec - tsec(1)) / 60;
        tunits = 'min';
    catch ME
        uiwait(msgbox({'Temporal resolution information not available.', ...
                       'Using frame number as temporal unit.'}));
        tmin = (1:handles.stackNum)';
        tunits = 'frame';
    end
    tmin(sum(handles.tmplLineVal.^2) == 0) = [];

    % Plot for current template stack
    s3 = subplot(2, pltCols, 3, 'parent', fig);
    colrs = jet(lineSz);
    h = plot(dist, lineVal, '.');
    set(h, {'color'}, num2cell(colrs, 2));
    title('Evolution over time of cross section (Blue \rightarrow Red)');
    ylabel('Amplitude (Template)');
    xlabel(['Distance from first pixel [', xunits, ']']);
    
    
    % Fit advection-diffusion functions
   
    
    
    
    % Find maxima and location and identify on plot
    [mx, mxIdx] = max(lineVal);
    hold(s3, 'on');
    scatter(dist(mxIdx), mx, ...
            'Marker', 'x', ...
            'CData', colrs);
      
    % Plot maximum displacement as function of time
    dmax = dist - dist(mxIdx(1));
    s4 = subplot(2, pltCols, 4, 'parent', fig);
    scatter(tmin, dmax(mxIdx), ...
            'CData', colrs);
    title('Displacement of maximum over time (Blue \rightarrow Red)');
    ylabel(['Displacement of Maximum [', xunits, '] (Template)']);
    xlabel(['Time [', tunits, ']']);

    % Evaluate and plot linear fit
    beta = tmin \ dmax(mxIdx);
    x = linspace(tmin(1), tmin(end), 100);
    y = beta * x;
    hold(s4, 'on');
    plot(x, y, '--');

    % Add text with velocity info
    txt = ['\leftarrow Velocity: ', num2str(beta, '%3.2e'), ' [', xunits, '/', tunits, ']'];
    text(x(50), y(50), txt);
end

