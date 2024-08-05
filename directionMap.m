% Copyright 2024 Andrea Vaccari (avaccari@middlebury.edu)

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

% Evaluate directional map
function handles = directionMap(handles)
    method = handles.direction.mapType;
    % Check if it is a 3d analysis
    if method > 4
        try
            % Evaluate the 3d directional map
            handles = directionMap3d(handles);
        catch ME
            msgbox(getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
        return
    end
    useHood = handles.direction.useHood;
    hoodSiz = handles.direction.hoodSiz;
    useTimWin = handles.direction.useTimeWin;
    winSiz = handles.direction.timeWinSiz;
    useSmooth = handles.direction.smoothModel;
    % Define spatial and temporal steps
    ds = handles.expInfo.ds;
    dt = handles.expInfo.dt;
    % Define time range
    be = handles.dirTempStart;
    en = handles.dirTempEnd - 1; % This will automatically drop the uneeded last slice of GI

    % Evaluate the ds to use for the Peclet number
    % We are simply using the dx=dy value entered by the user.
    ds_peclet = max(ds(1:2));
    if useHood
        ds_peclet = hoodSiz * ds_peclet;
    end

    % Notify user that saving is ongoing
    if ~handles.dirMap.quiet
        h = msgbox('Evaluating directional map...');
    end

    % Define the base image
    lmf = handles.stackImg(:, :, handles.sliceIdx, end) - handles.stackImg(:, :, handles.sliceIdx, 1);
    img = lmf;

    % Repeat for template, if there is one
    if isfield(handles, 'tmpl')
        imgTmpl = mean(handles.stackTmpl, 4);
        imgTmpl = imgTmpl(:, :, handles.sliceIdx);
    end

    % Check if a region is defined
    if isfield(handles.drawing, 'poly')
        % Find enclosing rectangle
        mM = minmax(handles.drawing.poly.getPosition()');
        rmM = floor(mM(1, :));
        cmM = ceil(mM(2, :));

        % Extract the temporal stack for the current slice
        stk = squeeze(handles.stackImg(cmM(1) - 1:cmM(2) + 1, rmM(1) - 1:rmM(2) + 1, handles.sliceIdx, :));

        % Repeat for template, if there is one
        if isfield(handles, 'tmpl')
            stkTmpl = squeeze(handles.stackTmpl(cmM(1) - 1:cmM(2) + 1, rmM(1) - 1:rmM(2) + 1, handles.sliceIdx, :));
        end

        % Define the polygon mask
        mask = handles.drawing.poly.createMask();
    else
        % Encosing rectangle is the whole image
        rmM = [2, size(img, 1) - 1];
        cmM = [2, size(img, 2) - 1];

        % Extract the temporal stack for the current slice
        stk = squeeze(handles.stackImg(:, :, handles.sliceIdx, :));

        % Repeat for template, if there is one
        if isfield(handles, 'tmpl')
            stkTmpl = squeeze(handles.stackTmpl(:, :, handles.sliceIdx, :));
        end

        mask = ones(size(img));
    end

    % Define global channels arrays (append to these inside each method)
    chnls = {'Max-Min', ...
                 'Luminance', ...
                 'Michelson', ...
                 'C.Var.', ...
             'Last-First'};
    lMax = max(handles.stackImg(:, :, handles.sliceIdx, :), [], 4);
    lMin = min(handles.stackImg(:, :, handles.sliceIdx, :), [], 4);
    lAvg = mean(handles.stackImg(:, :, handles.sliceIdx, :), 4);
    lStd = std(handles.stackImg(:, :, handles.sliceIdx, :), [], 4);
    mm = lMax - lMin; % Simple max difference
    lum = (lMax - lMin) ./ lAvg; % Relative importance of contrast (Weber-Fechner)
    mic = (lMax - lMin) ./ (lMax + lMin); % Mostly for periodic fuction - visibility (Michelson)
    cvar = lStd ./ lAvg; % Normalized spread for comparison
    ovrl = cat(3, ...
        mm, ...
        lum, ...
        mic, ...
        cvar, ...
        lmf);

    % Repeat for template, if there is one
    if isfield(handles, 'tmpl')
        lMax = max(handles.stackTmpl(:, :, handles.sliceIdx, :), [], 4);
        lMin = min(handles.stackTmpl(:, :, handles.sliceIdx, :), [], 4);
        lAvg = mean(handles.stackTmpl(:, :, handles.sliceIdx, :), 4);
        lStd = std(handles.stackTmpl(:, :, handles.sliceIdx, :), [], 4);
        mm = lMax - lMin; % Simple max difference
        lum = (lMax - lMin) ./ lAvg; % Relative importance of contrast (Weber-Fechner)
        mic = (lMax - lMin) ./ (lMax + lMin); % Mostly for periodic fuction - visibility (Michelson)
        cvar = lStd ./ lAvg; % Normalized spread for comparison
        ovrlTmpl = cat(3, ...
            mm, ...
            lum, ...
            mic, ...
            cvar);
    end

    % Switch based on the method
    % Choices (defined in guide):
    % 1 - 'Time Contr.'
    % 2 - 'Anis. Difs'
    % 3 - 'Difs-Adv.'
    % 4 - 'Difs-Adv.+Src'
    switch method
            % Simple contrast along time axis
            % Nothing to do. This are the value calculated above.
        case 1

            % Anisotropic diffusion
        case 2

            % Define model results
            nc = {'Coeff Max', ...
                      'Reluctance', ...
                      'Coeff Idx', ...
                      'Coeff North', ...
                      'Coeff South', ...
                      'Coeff East', ...
                      'Coeff West', ...
                  'Resid Norm'};
            snc = length(nc);
            chnls = [chnls, nc];

            % Evaluate anisotropic diffusion model on current stack
            [coeff, ~, resNorm] = modAnisoDiff(stk, ...
                be, en, ...
                ds, dt, ...
                useTimWin, winSiz, ...
                useHood, hoodSiz, ...
                useSmooth);

            % Store results in overlays
            [M, I] = max(coeff, [], 3);
            relc = exp(-M);
            ovrl = cat(3, ovrl, zeros([size(img), snc]));
            ovrl(cmM(1):cmM(2), rmM(1):rmM(2), end - snc + 1:end) = cat(3, ...
                M, ...
                relc, ...
                I, ...
                coeff, ...
                resNorm);

            % Repeat for template, if there is one
            if isfield(handles, 'tmpl')

                % Evaluate anisotropic diffusion model on template stack
                [coeff, ~, resNorm] = modAnisoDiff(stkTmpl, ...
                    be, en, ...
                    ds, dt, ...
                    useTimWin, winSiz, ...
                    useHood, hoodSiz, ...
                    useSmooth);

                % Store data in overlays
                [M, I] = max(coeff, [], 3);
                relc = exp(-M);
                ovrlTmpl = cat(3, ovrlTmpl, zeros([size(img), snc]));
                ovrlTmpl(cmM(1):cmM(2), rmM(1):rmM(2), end - snc + 1:end) = cat(3, ...
                    M, ...
                    relc, ...
                    I, ...
                    coeff, ...
                    resNorm);
            end

            % Advection-diffusion
        case 3
            % Define model results
            nc = {'Diff Coeff', ...
                      'Reluctance', ...
                      'P�clet Num.', ...
                      'Vmag', ...
                      'Vdir', ...
                      'Vx', ...
                      'Vy', ...
                  'Resid Norm'};
            chnls = [chnls, nc];

            % Evaluate advection-diffusion model on current stack
            [coeff, ~, resNorm] = modAdvecDiff(stk, ...
                be, en, ...
                ds, dt, ...
                useTimWin, winSiz, ...
                useHood, hoodSiz, ...
                useSmooth);

            % Evaluate derived parameters
            relc = exp(-coeff(:, :, 1));
            vmag = sqrt(coeff(:, :, 2) .^ 2 + coeff(:, :, 3) .^ 2);
            vdir = atan2d(coeff(:, :, 3), coeff(:, :, 2));
            pec = (vmag ./ coeff(:, :, 1)) * ds_peclet;

            % Add data to overlays
            ovrl = cat(3, ...
                ovrl, ...
                coeff(:, :, 1), ...
                relc, ...
                pec, ...
                vmag, ...
                vdir, ...
                coeff(:, :, 2:end), ...
                resNorm);

            % Repeat for template, if there is one
            if isfield(handles, 'tmpl')

                % Evaluate advection-diffusion model on template stack
                [coeff, ~, resNorm] = modAdvecDiff(stkTmpl, ...
                    be, en, ...
                    ds, dt, ...
                    useTimWin, winSiz, ...
                    useHood, hoodSiz, ...
                    useSmooth);

                % Evaluate derived parameters
                relc = exp(-coeff(:, :, 1));
                vmag = sqrt(coeff(:, :, 2) .^ 2 + coeff(:, :, 3) .^ 2);
                vdir = atan2d(coeff(:, :, 3), coeff(:, :, 2));
                pec = (vmag ./ coeff(:, :, 1)) * ds_peclet;

                % Add data to overlays
                ovrlTmpl = cat(3, ...
                    ovrlTmpl, ...
                    coeff(:, :, 1), ...
                    relc, ...
                    pec, ...
                    vmag, ...
                    vdir, ...
                    coeff(:, :, 2:end), ...
                    resNorm);
            end

            % Advection-diffusion + source (or sink)
        case 4
            % Define model results
            nc = {'Diff Coeff', ...
                      'Reluctance', ...
                      'P�clet Num.', ...
                      'Vmag', ...
                      'Vdir', ...
                      'Vx', ...
                      'Vy', ...
                      'Source', ...
                  'Resid Norm'};
            chnls = [chnls, nc];

            % Evaluate advection-diffusion-source model on current stack
            [coeff, ~, resNorm] = modAdvecDiffSrc(stk, ...
                be, en, ...
                ds, dt, ...
                useTimWin, winSiz, ...
                useHood, hoodSiz, ...
                useSmooth);

            % Evaluate derived parameters
            relc = exp(-coeff(:, :, 1));
            vmag = sqrt(coeff(:, :, 2) .^ 2 + coeff(:, :, 3) .^ 2);
            vdir = atan2d(coeff(:, :, 3), coeff(:, :, 2));
            pec = (vmag ./ coeff(:, :, 1)) * ds_peclet;

            % Add data to overlays
            ovrl = cat(3, ...
                ovrl, ...
                coeff(:, :, 1), ...
                relc, ...
                pec, ...
                vmag, ...
                vdir, ...
                coeff(:, :, 2:end), ...
                resNorm);

            % Repeat for template, if there is one
            if isfield(handles, 'tmpl')

                % Evaluate advection-diffusion-source model on template stack
                [coeff, ~, resNorm] = modAdvecDiffSrc(stkTmpl, ...
                    be, en, ...
                    ds, dt, ...
                    useTimWin, winSiz, ...
                    useHood, hoodSiz, ...
                    useSmooth);

                % Evaluate derived parameters
                relc = exp(-coeff(:, :, 1));
                vmag = sqrt(coeff(:, :, 2) .^ 2 + coeff(:, :, 3) .^ 2);
                vdir = atan2d(coeff(:, :, 3), coeff(:, :, 2));
                pec = (vmag ./ coeff(:, :, 1)) * ds_peclet;

                % Add data to overlays
                ovrlTmpl = cat(3, ...
                    ovrlTmpl, ...
                    coeff(:, :, 1), ...
                    relc, ...
                    pec, ...
                    vmag, ...
                    vdir, ...
                    coeff(:, :, 2:end), ...
                    resNorm);
            end
    end

    % Remove notification
    if ~handles.dirMap.quiet
        try
            delete(h);
        catch
        end
    end

    % If we are not showing the results, we are done
    if ~handles.dirMap.show
        return
    end

    %% Visualization
    % Store original results
    ovrlOrig = ovrl;
    handles.ovrl = ovrl;
    if isfield(handles, 'tmpl')
        ovrlTmplOrig = ovrlTmpl;
        handles.ovrlTmpl = ovrlTmpl;
    end

    % Overlay on grayscale version of image
    fig = figure(handles.figs.dirMap);
    fig.Units = 'normalized';
    fig.Resize = 'off'; % Prevent user from resizing the figure
    pos = [0.05, 0.1, 0.9, 0.8];
    if isfield(handles, 'tmpl')
        posTmpl = [0.05, 0.1, 0.4, 0.8];
        pos = [0.55, 0.1, 0.4, 0.8];
    end

    % Mask the overlays
    ovrlSiz = length(chnls);
    ovrl = ovrl .* repmat(mask, 1, 1, ovrlSiz);
    if isfield(handles, 'tmpl')
        ovrlTmpl = ovrlTmpl .* repmat(mask, 1, 1, ovrlSiz);
    end

    % Convert orignal image to rgb grayscale
    img = repmat(mat2gray(img), 1, 1, 3);
    ax = subplot('position', pos, 'parent', fig);
    imagesc(ax, img);
    title(['Directional Analysis (Temporal stacks: ', ...
               num2str(handles.dirTempStart), ...
               '-', ...
               num2str(handles.dirTempEnd - 1), ...
           ')']);
    hold(ax, 'on');
    if isfield(handles, 'tmpl')
        imgTmpl = repmat(1 - imadjust(mat2gray(imgTmpl)), 1, 1, 3);
        axT = subplot('position', posTmpl, 'parent', fig);
        imagesc(axT, imgTmpl);
        title('Directional Analysis (Template)');
        hold(axT, 'on');
    end

    % Show first channel
    channel = 1;
    data = ovrl(:, :, channel);
    h = imagesc(ax, data);
    colormap(ax, colorcet('L20', 'N', 256));
    set(h, 'AlphaData', mask);
    colorbar(ax);
    if isfield(handles, 'tmpl')
        dataTmpl = ovrlTmpl(:, :, channel);
        hT = imagesc(axT, dataTmpl);
        colormap(axT, colorcet('L20', 'N', 256));
        set(hT, 'AlphaData', mask);
        colorbar(axT);
    end

    % Show pop-up window with averages for original analysis polygon
    %     origMask = handles.drawing.poly.createMask(h);
    %     origMskd = ovrl .* repmat(origMask, 1, 1, size(ovrl, 3));
    origMskd = ovrl .* repmat(mask, 1, 1, size(ovrl, 3));
    origMskd(origMskd == 0) = nan;
    vals = squeeze(mean(mean(origMskd, 1, "omitnan"), 2, "omitnan"));
    txt = {'Mean values within original polygon:'};
    for ch = 1:size(ovrl, 3)
        %             disp([num2str(ch), ' ', chnls{ch}, ' ', num2str(vals(ch))]);
        if strcmp(chnls{ch}, 'Vmag')
            vm = sqrt(vals(ch + 2) ^ 2 + vals(ch + 3) ^ 2);
            txt{end + 1} = [chnls{ch}, ': ', num2str(vm, '%3.2f')];
        elseif strcmp(chnls{ch}, 'Vx') || strcmp(vals(ch), 'Vy')
            txt{end + 1} = [chnls{ch}, ': ', num2str(vals(ch), '%3.2f')];
        elseif strcmp(chnls{ch}, 'Vdir')
            vd = atan2d(vals(ch + 2), vals(ch + 1));
            txt{end + 1} = [chnls{ch}, ': ', num2str(vd, '%3.f')];
        else
            txt{end + 1} = [chnls{ch}, ': ', num2str(vals(ch), '%3.2e')];
        end
    end
    %     txt{end + 1} = ['Pixels within polygon:', num2str(nnz(origMask))];
    txt{end + 1} = ['Pixels within polygon:', num2str(nnz(mask))];
    msgbox(txt, 'Avgs in original poly');

    % Set colormaps and scales
    function setCMapScale()
        % Check ranges
        mM = minmax(data(:)');
        if isfield(handles, 'tmpl')
            mMT = minmax(dataTmpl(:)');
            mM = minmax([mM, mMT]);
        end

        % Define colormap and scales depending on what is shown
        switch chnls{channel}
            case 'Vdir'
                colormap(ax, colorcet('C3', 'N', 256));
                if isfield(handles, 'tmpl')
                    colormap(axT, colorcet('C3', 'N', 256));
                end
                scale = [-180, 180];
            case {'Vx', 'Vy', 'P�clet Num.', 'Source', 'Last-First'}
                colormap(ax, colorcet('D1', 'N', 256));
                if isfield(handles, 'tmpl')
                    colormap(axT, colorcet('D1', 'N', 256));
                end
                mx = max(mM);
                scale = [-mx, mx];
            otherwise
                colormap(ax, colorcet('L20', 'N', 256));
                if isfield(handles, 'tmpl')
                    colormap(axT, colorcet('L20', 'N', 256));
                end
                scale = mM;
        end

        % Set color scales
        set(ax, 'CLim', scale);
        if isfield(handles, 'tmpl')
            set(axT, 'CLim', scale);
        end
    end

    % Add channel selector
    uicontrol('parent', fig, ...
        'style', 'popup', ...
        'string', chnls, ...
        'units', 'normalized', ...
        'position', [0.8, 0.95, 0.2, 0.05], ...
        'callback', @setChannel);
    function setChannel(src, ~)
        % Update displayed data
        channel = src.Value;

        data = ovrl(:, :, channel);
        set(h, 'CData', data);

        % Do the same if there is a template
        if isfield(handles, 'tmpl')
            dataTmpl = ovrlTmpl(:, :, channel);
            set(hT, 'CData', dataTmpl);
        end

        % Set colormaps and scales
        setCMapScale();

        % If Vmag, show quiver controls
        hqtgl.Visible = 'off'; % Button to toggle quiver on
        hqsca.Visible = 'off'; % Scale adjustment
        hqsmp.Visible = 'off'; % Sampling adjustment
        if strcmp(chnls{channel}, 'Vmag')
            hqtgl.Visible = 'on';
            hqsca.Visible = 'on';
            hqsmp.Visible = 'on';
        end
    end

    % Add slider bar to adjust overlay intensity
    hsldr = uicontrol('parent', fig, ...
        'style', 'slider', ...
        'min', 0, ...
        'max', 1, ...
        'value', 1, ...
        'units', 'normalized', ...
        'position', [0.5, 0, 0.45, 0.05]);
    addlistener(hsldr, 'Value', 'PostSet', @setOverlay);

    % Add slider bar to adjust overlay threshold
    hthrs = uicontrol('parent', fig, ...
        'style', 'slider', ...
        'min', 0, ...
        'max', 1, ...
        'value', 0, ...
        'units', 'normalized', ...
        'position', [0.95, 0.1, 0.05, 0.8]);
    addlistener(hthrs, 'Value', 'PostSet', @setOverlay);
    function setOverlay(~, ~)
        data = ovrl(:, :, channel);
        q = prctile(abs(data(:)), 100 * hthrs.Value);

        tmask = mask;
        tmask((data > 0) & (data < q)) = 0;
        tmask((data < 0) & (data > -q)) = 0;
        set(h, 'AlphaData', hsldr.Value * tmask);

        if isfield(handles, 'tmpl')
            dataTmpl = ovrlTmpl(:, :, channel);
            mM = minmax(dataTmpl(:)');
            tmaskTmpl = mask;
            tmaskTmpl(dataTmpl < (mM(1) + diff(mM) * hthrs.Value)) = 0;
            set(hT, 'AlphaData', hsldr.Value * tmaskTmpl);
        end
    end

    % Add button with callback to smooth the results
    uicontrol('parent', fig, ...
        'style', 'pushbutton', ...
        'string', 'Smooth', ...
        'units', 'normalized', ...
        'position', [0.0, 0.95, 0.1, 0.05], ...
        'callback', @smoothResults);
    function smoothResults(~, ~)
        for chn = 1:size(ovrl, 3)
            ovrl(:, :, chn) = smoothdata2(ovrl(:, :, chn), 'gaussian', 3);
        end

        if isfield(handles, 'tmpl')
            for chn = 1:size(ovrl, 3)
                ovrlTmpl(:, :, chn) = smoothdata2(ovrlTmpl(:, :, chn), 'gaussian', 3);
            end
        end

        % Update screen
        data = ovrl(:, :, channel);
        set(h, 'CData', data);

        % Set colormaps and scales
        setCMapScale();
    end

    % Add button with callback to reset the results
    uicontrol('parent', fig, ...
        'style', 'pushbutton', ...
        'string', 'Reset', ...
        'units', 'normalized', ...
        'position', [0.1, 0.95, 0.1, 0.05], ...
        'callback', @resetResults);
    function resetResults(~, ~)
        ovrl = ovrlOrig;
        if isfield(handles, 'tmpl')
            ovrlTmpl = ovrlTmplOrig;
        end

        % Update screen
        data = ovrl(:, :, channel);
        set(h, 'CData', data);

        % Set colormaps and scales
        setCMapScale();

        set(h, 'AlphaData', mask);
        if isfield(handles, 'tmpl')
            set(hT, 'AlphaData', mask);
        end

    end

    % Add button with callback to apply velocity magnitude mask
    uicontrol('parent', fig, ...
        'style', 'pushbutton', ...
        'string', 'Vmag mask', ...
        'units', 'normalized', ...
        'position', [0.2, 0.95, 0.1, 0.05], ...
        'callback', @vMagMask);
    function vMagMask(~, ~)
        % Load the alpha magnitude from the Vmag channel
        idx = find(strcmp(chnls, 'Vmag'));
        alpha = ovrl(:, :, idx);
        % Set arbitrary threshold at 50%
        alpha = alpha / (0.5 * max(alpha(:)));
        % Apply original mask
        alpha = alpha .* mask;
        set(h, 'AlphaData', alpha);
        if isfield(handles, 'tmpl')
            alpha = ovrlTmpl(:, :, idx);
            % Set arbitrary threshold at 50%
            alpha = alpha / (0.5 * max(alpha(:)));
            % Apply original mask
            alpha = alpha .* mask;
            set(hT, 'AlphaData', alpha);
        end
    end

    satLevel = 0.1;
    % Add button with callback to apply color saturation
    uicontrol('parent', fig, ...
        'style', 'pushbutton', ...
        'string', 'Saturate', ...
        'units', 'normalized', ...
        'position', [0.3, 0.95, 0.1, 0.05], ...
        'callback', @colSaturation);
    function colSaturation(~, ~)
        data = ovrl(:, :, channel);
        q = prctile(abs(data(:)), 100 - satLevel);
        data(data > q) = q;
        data(data < -q) = -q;
        if isfield(handles, 'tmpl')
            dataTmpl = ovrlTmpl(:, :, channel);
            qT = prctile(abs(dataTmpl(:)), 100 - satLevel);
            dataTmpl(dataTmpl > qT) = qT;
            dataTmpl(dataTmpl < -qT) = -qT;
        end
        setCMapScale();
    end

    % Add entry box to specify color saturation level
    uicontrol('parent', fig, ...
        'style', 'edit', ...
        'string', '0.1%', ...
        'units', 'normalized', ...
        'position', [0.4, 0.95, 0.1, 0.05], ...
        'callback', @setSaturation);
    function setSaturation(src, evt)
        str = get(src, 'String');
        num = str2double(str);

        if isnan(num) || (num < 0) || (num >= 50)
            set(src, 'String', satLevel);
            msgbox('Enter a number between 0 and less than 50');
            return;
        end

        satLevel = num;
        set(src, 'String', [num2str(satLevel), '%']);

        colSaturation(src, evt);
    end

    % Add button to toggle quiver
    hqtgl = uicontrol('parent', fig, ...
        'visible', 'off', ...
        'style', 'toggleButton', ...
        'string', 'Qvr', ...
        'units', 'normalized', ...
        'position', [0.5, 0.95, 0.05, 0.05], ...
        'tag', 'QTgl', ...
        'callback', @drawQuiver);

    % Add silder to control quiver sampling
    hqsmp = uicontrol('parent', fig, ...
        'visible', 'off', ...
        'style', 'slider', ...
        'min', 0, ...
        'max', 1, ...
        'SliderStep', [0.1, 0.1], ...
        'value', 0, ...
        'units', 'normalized', ...
        'tag', 'QSmp', ...
        'callback', @drawQuiver, ...
        'position', [0.55, 0.95, 0.1, 0.05]);

    % Add slider to control quiver scaling
    hqsca = uicontrol('parent', fig, ...
        'visible', 'off', ...
        'style', 'slider', ...
        'min', 0.1, ...
        'max', 2, ...
        'SliderStep', [0.1, 0.1], ...
        'value', 0.1, ...
        'units', 'normalized', ...
        'tag', 'QSca', ...
        'callback', @drawQuiver, ...
        'position', [0.65, 0.95, 0.1, 0.05]);
    function drawQuiver(src, ~)
        if isfield(handles, 'hq')
            delete(handles.hq);
        end
        % If we are removing the quiver, delete and leave
        if strcmp(src.Tag, 'QTgl') && src.Value == 0
            hqsca.Value = 0.1;
            hqsmp.Value = 0;
            return;
        end

        % Extract velocity data
        vx = ovrl(:, :, find(strcmp(chnls, 'Vx')));
        vy = ovrl(:, :, find(strcmp(chnls, 'Vy')));

        % If we are changing sampling
        sampMax = min(cmM(2) - cmM(1), rmM(2) - rmM(1)) / 2;
        sampling = 1 + floor(hqsmp.Value * sampMax);

        % Sample coordinates info
        [cc, rr] = meshgrid(cmM(1):sampling:cmM(2), rmM(1):sampling:rmM(2));

        % Evaluate velocity at sampled coordinates
        vxt = impixel(vx, rr, cc);
        vxs = reshape(vxt(:, 1), size(rr));
        vyt = impixel(vy, rr, cc);
        vys = reshape(vyt(:, 1), size(rr));

        % If we are changing scaling
        scaling = 10 * hqsca.Value;

        handles.hq = quiver(rr, cc, vxs, vys, ...
            scaling, ...
            'Color', [1, 1, 1], ...
            'LineWidth', 1.0);
    end

    % Add button with callback to calculate differences between current and template
    uicontrol('parent', fig, ...
        'style', 'pushbutton', ...
        'string', 'Curr vs Tmpl', ...
        'units', 'normalized', ...
        'position', [0.0, 0.0, 0.15, 0.05], ...
        'callback', @(hObject, eventdata)compDirection(hObject, eventdata, handles));

    % Add text block to show values under mouse
    info = uicontrol('parent', fig, ...
        'style', 'text', ...
        'string', 'Velocity', ...
        'horizontalAlignment', 'left', ...
        'units', 'normalized', ...
        'position', [0.16, 0.0, 0.33, 0.06]);

    % Configure the figure to provide live data as the mouse is moved
    fig.WindowButtonMotionFcn = @showVelInfo;
    function showVelInfo(src, ~)
        % Get location of mouse respect to application window
        mPos = get(src, 'currentPoint'); % (0,0) is bottom-left
        pX = mPos(1);
        pY = mPos(2);

        % Get information about location and size of axes
        maLoc = get(ax, 'Position');
        maL = maLoc(1);
        maB = maLoc(2);
        maW = maLoc(3);
        maH = maLoc(4);

        % Check if within image limits
        if pX >= maL && pY >= maB
            maX = pX - maL;
            maY = pY - maB;
            if maX <= maW && maY <= maH
                cPos = get(ax, 'CurrentPoint');
                cPos = round(cPos(1, 1:2));
                cPos = [cPos(2), cPos(1)];
                posIdx = num2cell(cPos);
                try
                    val = ovrl(posIdx{:}, channel);
                catch
                    val = 0;
                end

                % If it is velocity mag or dir, show both numbers
                if strcmp(chnls{channel}, 'Vmag')
                    try
                        val2 = ovrl(posIdx{:}, channel + 1);
                    catch
                        val2 = 0;
                    end
                    txt = ['Vmag: ', num2str(val, '%3.2f'), ...
                               ' Vdir: ', num2str(val2, '%3.f')];
                elseif strcmp(chnls{channel}, 'Vdir')
                    try
                        val2 = ovrl(posIdx{:}, channel - 1);
                    catch
                        val2 = 0;
                    end
                    txt = ['Vmag: ', num2str(val2, '%3.2f'), ...
                               ' Vdir: ', num2str(val, '%3.f')];
                else
                    txt = [chnls{channel}, ': ', num2str(val, '%3.2e')];
                end

                info.String = txt;

            end
        end

    end

    % Add button with callback to do polygon analysis
    uicontrol('parent', fig, ...
        'style', 'pushbutton', ...
        'string', 'Polygon', ...
        'units', 'normalized', ...
        'position', [0.0, 0.90, 0.1, 0.05], ...
        'callback', @polygon);
    function polygon(~, ~)
        poly = impoly(ax);
        showData(false);
        poly.addNewPositionCallback(@newPos);
        function newPos(~, ~)
            showData(true);
        end
        function showData(update)
            pMask = poly.createMask(h);
            mskd = ovrl .* repmat(pMask, 1, 1, size(ovrl, 3));
            mskd(mskd == 0) = nan;
            vals = squeeze(mean(mean(mskd, 1, "omitnan"), 2, "omitnan"));
            txt = {'Mean values within polygon:'};
            for chn = 1:size(ovrl, 3)
                %             disp([num2str(ch), ' ', chnls{ch}, ' ', num2str(vals(ch))]);
                if strcmp(chnls{chn}, 'Vmag')
                    vm = sqrt(vals(chn + 2) ^ 2 + vals(chn + 3) ^ 2);
                    txt{end + 1} = [chnls{chn}, ': ', num2str(vm, '%3.2f')];
                elseif strcmp(chnls{chn}, 'Vx') || strcmp(vals(chn), 'Vy')
                    txt{end + 1} = [chnls{chn}, ': ', num2str(vals(chn), '%3.2f')];
                elseif strcmp(chnls{chn}, 'Vdir')
                    vd = atan2d(vals(chn + 2), vals(chn + 1));
                    txt{end + 1} = [chnls{chn}, ': ', num2str(vd, '%3.f')];
                else
                    txt{end +1} = [chnls{chn}, ': ', num2str(vals(chn), '%3.2e')];
                end
            end
            txt{end + 1} = ['Pixels within polygon:', num2str(nnz(pMask))];
            if update
                msgbox(txt, 'Avgs in selected poly', 'replace');
            else
                msgbox(txt, 'Avgs in selected poly');
            end
        end
    end

    % Add button with callback to export overlay file
    uicontrol('parent', fig, ...
        'style', 'pushbutton', ...
        'string', 'Ovrls ->', ...
        'units', 'normalized', ...
        'position', [0.1, 0.90, 0.1, 0.05], ...
        'callback', @exportOvrl)
    function exportOvrl(~, ~)
        % Build unique file name
        time = char(datetime('now', 'Format', 'yyyyMMddHHmmss'));
        file = char(strcat(handles.machineId, time, '-ovrl.mat'));
        [file, dir] = uiputfile('*.mat', ...
            'Save file name for ovrl', ...
            file);

        % Check if the user cancelled
        if isequal(file, 0) || isequal(dir, 0)
            return
        end

        % Notify user that saving is ongoing
        h = msgbox('Saving ovrl file...');

        % If the file exists, delete it
        if exist(fullfile(dir, file), 'file') == 2
            delete(fullfile(dir, file));
        end

        % Save ovrl to file
        save(fullfile(dir, file), 'ovrlOrig');

        % Remove notification
        try
            delete(h);
        catch
        end

        if isfield(handles, 'tmpl')

            file = char(strcat(handles.machineId, time, '-ovrlTmpl.mat'));
            [file, dir] = uiputfile('*.mat', ...
                'Save file name for template over', ...
                file);

            % Check if the user cancelled
            if isequal(file, 0) || isequal(dir, 0)
                return
            end

            % Notify user that saving is ongoing
            h = msgbox('Saving ovrlTmpl file...');

            % If the file exists, delete it
            if exist(fullfile(dir, file), 'file') == 2
                delete(fullfile(dir, file));
            end

            % Save ovrl to file
            save(fullfile(dir, file), 'ovrlTmplOrig');

            % Remove notification
            try
                delete(h);
            catch
            end
        end
    end
end
