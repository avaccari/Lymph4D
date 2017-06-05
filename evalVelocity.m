% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

function evalVelocity(hObject, eventdata, handles)

% If they exist, remove zero traces
lineVal = handles.lineVal;
lineVal(:, sum(handles.lineVal.^2) == 0) = [];
lineSz = size(lineVal, 2);

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
f3 = figure(3);
pltCols = 1;

% Check if there is a template
if isfield(handles, 'tmpl')
    pltCols = 2;
end

% Plot for current stack
s1 = subplot(2, pltCols, 1, 'parent', f3);
colrs = jet(lineSz);
h = plot(dist, lineVal);
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
s2 = subplot(2, pltCols, 2, 'parent', f3);
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
    s3 = subplot(2, pltCols, 3, 'parent', f3);
    colrs = jet(lineSz);
    h = plot(dist, lineVal);
    set(h, {'color'}, num2cell(colrs, 2));
    title('Evolution over time of cross section (Blue \rightarrow Red)');
    ylabel('Amplitude (Template)');
    xlabel(['Distance from first pixel [', xunits, ']']);
    
    % Find maxima and location and identify on plot
    [mx, mxIdx] = max(lineVal);
    hold(s3, 'on');
    scatter(dist(mxIdx), mx, ...
            'Marker', 'x', ...
            'CData', colrs);
      
    % Plot maximum displacement as function of time
    dmax = dist - dist(mxIdx(1));
    s4 = subplot(2, pltCols, 4, 'parent', f3);
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

