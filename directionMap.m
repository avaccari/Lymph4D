% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

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
    useHood = handles.direction.useHood;
    hoodSiz = handles.direction.hoodSiz;

    % Notify user that saving is ongoing
    h = msgbox('Evaluating directional map...');
    
    % Define the base image
    img = mean(handles.stackImg, 4);
    img = img(:, :, handles.sliceIdx);
    
    % Repeat for template, if there is one
    if isfield(handles, 'tmpl')
        imgTmpl = mean(handles.stackTmpl, 4);
        imgTmpl = imgTmpl(:, :, handles.sliceIdx);
    end

    % Check if a region is defined
    if isfield(handles.drawing, 'poly')
        % Find enclosing rectangle
        Mm = minmax(handles.drawing.poly.getPosition()');
        rmM = floor(Mm(1, :));
        cmM = ceil(Mm(2, :));

        % Extract the temporal stack for the current slice
        stk = squeeze(handles.stackImg(cmM(1)-1:cmM(2)+1, rmM(1)-1:rmM(2)+1, handles.sliceIdx, :));

        % Repeat for template, if there is one
        if isfield(handles, 'tmpl')
            stkTmpl = squeeze(handles.stackTmpl(cmM(1)-1:cmM(2)+1, rmM(1)-1:rmM(2)+1, handles.sliceIdx, :));
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
             'C.Var.'};
    lMax = max(handles.stackImg(:, :, handles.sliceIdx, :), [], 4);
    lMin = min(handles.stackImg(:, :, handles.sliceIdx, :), [], 4);
    lAvg = mean(handles.stackImg(:, :, handles.sliceIdx, :), 4);
    lStd = std(handles.stackImg(:, :, handles.sliceIdx, :), [], 4);
    mm = lMax - lMin;  % Simple max difference
    lum = (lMax - lMin) ./ lAvg;  % Relative importance of contrast (Weber-Fechner)
    mic = (lMax - lMin) ./ (lMax + lMin);  % Mostly for periodic fuction - visibility (Michelson)
    cvar = lStd ./ lAvg;  % Normalized spread for comparison
    ovrl = cat(3, ...
               mm, ...
               lum, ...
               mic, ...
               cvar);
               
    % Repeat for template, if there is one
    if isfield(handles, 'tmpl')
        lMax = max(handles.stackTmpl(:, :, handles.sliceIdx, :), [], 4);
        lMin = min(handles.stackTmpl(:, :, handles.sliceIdx, :), [], 4);
        lAvg = mean(handles.stackTmpl(:, :, handles.sliceIdx, :), 4);
        lStd = std(handles.stackTmpl(:, :, handles.sliceIdx, :), [], 4);
        mm = lMax - lMin;  % Simple max difference
        lum = (lMax - lMin) ./ lAvg;  % Relative importance of contrast (Weber-Fechner)
        mic = (lMax - lMin) ./ (lMax + lMin);  % Mostly for periodic fuction - visibility (Michelson)
        cvar = lStd ./ lAvg;  % Normalized spread for comparison
        ovrlTmpl = cat(3, ...
                       mm, ...
                       lum, ...
                       mic, ...
                       cvar);
    end

    % Define time range
    be = 1;
    en = handles.stackNum - 1;  
       
    % Switch based on the method
    % Choices (defined in guide):
    % 1 - 'Time Contr.'
    % 2 - 'Anis. Difs'
    % 3 - 'Difs-Adv.'
    % 4 - 'Difs-Adv.+Src'
    % 5 - 'Comp. Mods'
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
            [coeff, res, resNorm] = anisoDiff(stk, be, en, useHood, hoodSiz);
            
            % Store results in overlays
            [M, I] = max(coeff, [], 3);
            relc = exp(-M);
            ovrl = cat(3, ovrl, zeros([size(img), snc]));
            ovrl(cmM(1):cmM(2), rmM(1):rmM(2), end-snc+1:end) = cat(3, ...
                                                                    M, ...
                                                                    relc, ...
                                                                    I, ...
                                                                    coeff, ...
                                                                    resNorm);
                                                             
            % Repeat for template, if there is one
            if isfield(handles, 'tmpl')
                
                % Evaluate anisotropic diffusion model on template stack
                [coeff, res, resNorm] = anisoDiff(stkTmpl, be, en, useHood, hoodSiz);

                % Store data in overlays
                [M, I] = max(coeff, [], 3);
                relc = exp(-M);
                ovrlTmpl = cat(3, ovrlTmpl, zeros([size(img), snc]));
                ovrlTmpl(cmM(1):cmM(2), rmM(1):rmM(2), end-snc+1:end) = cat(3, ...
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
                  'Vmag', ...
                  'Vx', ...
                  'Vy', ...
                  'Resid Norm'};
            snc = length(nc);
            chnls = [chnls, nc];

            % Evaluate advection-diffusion model on current stack
            [coeff, res, resNorm] = advecDiff(stk, be, en, useHood, hoodSiz);

            % Store data in overlays
            ovrl = cat(3, ovrl, zeros([size(img), snc]));
            
            % Adjust for central gradients (non need for the extra pixel at
            % the edges)
            cmM = cmM + [-1, 1];
            rmM = rmM + [-1, 1];
            relc = exp(-coeff(:, :, 1));
            vmag = sqrt(coeff(:, :, 2).^2 + coeff(:, :, 3).^2);
            ovrl(cmM(1):cmM(2), rmM(1):rmM(2), end-snc+1:end) = cat(3, ...
                                                                    coeff(:, :, 1), ...
                                                                    relc, ...
                                                                    vmag, ...
                                                                    coeff(:, :, 2:end), ...
                                                                    resNorm);

            % Repeat for template, if there is one
            if isfield(handles, 'tmpl')

                % Evaluate advection-diffusion model on template stack
                [coeff, res, resNorm] = advecDiff(stkTmpl, be, en, useHood, hoodSiz);

                % Store data in overlays
                ovrlTmpl = cat(3, ovrlTmpl, zeros([size(img), snc]));
                
                % Adjust for central gradients (non need for the extra pixel at
                % the edges)
                relc = exp(-coeff(:, :, 1));
                vmag = sqrt(coeff(:, :, 2).^2 + coeff(:, :, 3).^2);
                ovrlTmpl(cmM(1):cmM(2), rmM(1):rmM(2), end-snc+1:end) = cat(3, ...
                                                                            coeff(:, :, 1), ...
                                                                            relc, ...
                                                                            vmag, ...
                                                                            coeff(:, :, 2:end), ...
                                                                            resNorm);
            end
            
            
            
            
            
            
        % Advection-diffusion + source (or sink)
        case 4
            
            % Define model results
            nc = {'Diff Coeff', ...
                  'Reluctance', ...
                  'Vmag', ...
                  'Vx', ...
                  'Vy', ...
                  'Source', ...
                  'Resid Norm'};
            snc = length(nc);
            chnls = [chnls, nc];

            % Evaluate advection-diffusion-source model on current stack
            [coeff, res, resNorm] = advecDiffSrc(stk, be, en, useHood, hoodSiz);

            % Store data in overlays
            ovrl = cat(3, ovrl, zeros([size(img), snc]));
            
            % Adjust for central gradients (non need for the extra pixel at
            % the edges)
            cmM = cmM + [-1, 1];
            rmM = rmM + [-1, 1];
            relc = exp(-coeff(:, :, 1));
            vmag = sqrt(coeff(:, :, 2).^2 + coeff(:, :, 3).^2);
            ovrl(cmM(1):cmM(2), rmM(1):rmM(2), end-snc+1:end) = cat(3, ...
                                                                    coeff(:, :, 1), ...
                                                                    relc, ...
                                                                    vmag, ...
                                                                    coeff(:, :, 2:end), ...
                                                                    resNorm);

            % Repeat for template, if there is one
            if isfield(handles, 'tmpl')

                % Evaluate advection-diffusion-source model on template stack
                [coeff, res, resNorm] = advecDiffSrc(stkTmpl, be, en, useHood, hoodSiz);

                % Store data in overlays
                ovrlTmpl = cat(3, ovrlTmpl, zeros([size(img), snc]));
                
                % Adjust for central gradients (non need for the extra pixel at
                % the edges)
                relc = exp(-coeff(:, :, 1));
                vmag = sqrt(coeff(:, :, 2).^2 + coeff(:, :, 3).^2);
                ovrlTmpl(cmM(1):cmM(2), rmM(1):rmM(2), end-snc+1:end) = cat(3, ...
                                                                            coeff(:, :, 1), ...
                                                                            relc, ...
                                                                            vmag, ...
                                                                            coeff(:, :, 2:end), ...
                                                                            resNorm);
            end
            
            
            
        % Compare predominance of model
        case 5
            
            
        % Simpler approach:
        % At each time, look at the neighboring pixels (NSEW) and figure
        % out the direction of minimum variation and identify that as the
        % maximum diffusion direction at next time step. (This assumes that
        % we just have a diffusive process base entirely on the
        % concentration of contrast agent).
        % Repeat for every time slot and take the majority vote (mode) or
        % the average (?) and associate complex versors to corresponding 
        % directions (and possibly 0 to noise) and plot the corresponsing 
        % phase as direction. 
        case 6
            
            
            
    end

    
    
    % Remove notification
    try
        delete(h);
    catch ME
    end
    
    % Store original results
    ovrlOrig = ovrl;
    if isfield(handles, 'tmpl')
        ovrlTmplOrig = ovrlTmpl;
    end

    % Overlay on grayscale version of image
    fig = figure(handles.figs.dirMap);
    pos = [0.05, 0.1, 0.9, 0.8];
    if isfield(handles, 'tmpl')
        pos = [0.05, 0.1, 0.4, 0.8];
        posTmpl = [0.55, 0.1, 0.4, 0.8];
    end
        
    % Mask the overlays
    ovrlSiz = length(chnls);
    ovrl = ovrl .* repmat(mask, 1, 1, ovrlSiz);
    if isfield(handles, 'tmpl')
        ovrlTmpl = ovrlTmpl .* repmat(mask, 1, 1, ovrlSiz);
    end

    % Convert orignal image to rgb grayscale
    img = repmat(1 - imadjust(mat2gray(img)), 1, 1, 3);
    ax = subplot('position', pos, 'parent', fig);
    imagesc(ax, img);
    title('Directional Analysis');
    hold(ax, 'on');
    if isfield(handles, 'tmpl')
        imgTmpl = repmat(1 - imadjust(mat2gray(imgTmpl)), 1, 1, 3);
        axT = subplot('position', posTmpl, 'parent', fig);
        imagesc(axT, imgTmpl);
        title('Directional Analysis (Template)');
        hold(axT, 'on');
    end

    channel = 1;
    h = imagesc(ax, ovrl(:, :, channel));
    colormap(ax, 'jet');
    set(h, 'AlphaData', mask);
    colorbar(ax);
    if isfield(handles, 'tmpl')
        hT = imagesc(axT, ovrlTmpl(:, :, channel));
        colormap(axT, 'jet');
        set(hT, 'AlphaData', mask);
        colorbar(axT);
    end

    % Add channel selector
    hpop = uicontrol('parent', fig, ...
                     'style', 'popup', ...
                     'string', chnls, ...
                     'units', 'normalized', ...
                     'position', [0.8, 0.95, 0.2, 0.05], ...
                     'callback', @setChannel);             
    function setChannel(src, evt)
        channel = src.Value;
        data = ovrl(:, :, channel);
        mM = minmax(data(:)');
        set(h, 'CData', data);
        set(ax, 'CLim', mM);
        if isfield(handles, 'tmpl')
            dataTmpl = ovrlTmpl(:, :, channel);
            mMT = minmax(dataTmpl(:)');
            set(hT, 'CData', dataTmpl);
            % Same scales
            mM = minmax([mM, mMT]);
            set(ax, 'CLim', mM);
            set(axT, 'CLim', mM);
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
    function setOverlay(src, evt)
        data = ovrl(:, :, channel);
        mM = minmax(data(:)');
        tmask = mask;
        tmask(data < (mM(1) + diff(mM) * hthrs.Value)) = 0;
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
    function smoothResults(src, evt)
        % Store original
        fil = [[1,2,1];[2,4,2];[1,2,1]]/16;  % A 3x3 Gaussian kernel
        ovrl = imfilter(ovrl, fil, 'replicate', 'same');
        
        if isfield(handles, 'tmpl')
            ovrlTmpl = imfilter(ovrlTmpl, fil, 'replicate', 'same');
        end
        
        % Update screen
        data = ovrl(:, :, channel);
        mM = minmax(data(:)');
        set(h, 'CData', data);
        set(ax, 'CLim', mM);
        if isfield(handles, 'tmpl')
            dataTmpl = ovrlTmpl(:, :, channel);
            mMT = minmax(dataTmpl(:)');
            set(hT, 'CData', dataTmpl);
            % Same scales
            mM = minmax([mM, mMT]);
            set(ax, 'CLim', mM);
            set(axT, 'CLim', mM);
        end
    end

    % Add button with callback to reset the results
    uicontrol('parent', fig, ...
              'style', 'pushbutton', ...
              'string', 'Reset', ...
              'units', 'normalized', ...
              'position', [0.1, 0.95, 0.1, 0.05], ...
              'callback', @resetResults);
    function resetResults(src, evt)
        ovrl = ovrlOrig;
        if isfield(handles, 'tmpl')
            ovrlTmpl = ovrlTmplOrig;
        end

        % Update screen
        data = ovrl(:, :, channel);
        mM = minmax(data(:)');
        set(h, 'CData', data);
        set(ax, 'CLim', mM);
        if isfield(handles, 'tmpl')
            dataTmpl = ovrlTmpl(:, :, channel);
            mMT = minmax(dataTmpl(:)');
            set(hT, 'CData', dataTmpl);
            % Same scales
            mM = minmax([mM, mMT]);
            set(ax, 'CLim', mM);
            set(axT, 'CLim', mM);
        end        
    end

    % Add button with callback to calculate differences between current and template
    uicontrol('parent', fig, ...
              'style', 'pushbutton', ...
              'string', 'Curr vs Tmpl', ...
              'units', 'normalized', ...
              'position', [0.0, 0.0, 0.15, 0.05], ...
              'callback', @(hObject, eventdata)compDirection(hObject, eventdata, handles));

end




% Evaluate the anisotropic diffusion model
% Calculate using anisotropic diffusion and contraint least square
% Each diffusive step in time is calculated from the previous image
%   In = I + dt * (Cn * GIn + Cs * GIs + Ce * GIe + Cw * GIw)
% or
%   y = GI' * x
% where
%   y = (In - I)
%   x = dt * [Cn; Cs; Ce; Cw]
%   GI = [GIn, GIs, GIe, GIw]
% which can be solved for x (the Cs) as
%   xm = argmin_x{0.5 * ||GI' * x - y||^2_2}
%   0 <= x_k 
% In this case the GI and y are the temporal series of the values
function [coeff, res, resNorm] = anisoDiff(stk, be, en, useHood, hoodSiz)
    % Calculate the time series of the gradients
    [GIn, GIs, GIe, GIw] = grad(stk, ...
                                'valid', true, ...
                                'type', 'foward', ...
                                'winSize', 3);
    GI = cat(4, GIn, GIs, GIe, GIw);

    % Calculate the time series of the differences
    % TODO: make dependent on GI size
    y = diff(stk(2:end-1, 2:end-1, :), 1, 3);


    % Restrict time if any
    GI = GI(:, :, be:en, :);
    y = y(:, :, be:en);

    % Setup constraint problem
    A = [];
    b = [];
    Aeq = [];
    beq = [];
    lb = [0, 0, 0, 0];
    ub = [Inf, Inf, Inf, Inf];
    x0 = [];        
    options = optimoptions('lsqlin', ...
                           'Algorithm', 'trust-region-reflective', ...
                           'Display', 'off');

    % Calculate the anisotropic parameters
    [sr, sc, st, ~] = size(GI);
    coeff = zeros(sr, sc, 4);  % An array to hold the model coefficients
    resNorm = zeros(sr, sc);  % An array to hold the norm of the residuals 

    % If we are using the neighborhood
    if useHood
        hVol = hoodSiz * hoodSiz;
        hDel = (hoodSiz - 1) / 2;
        res = zeros(sr, sc, hVol * st);  % An array to hold the residuals at each time step
        for c = 1 + hDel : sc - hDel
            for r = 1 + hDel : sr - hDel
                y1 = reshape(permute(squeeze(y(r-hDel:r+hDel, c-hDel:c+hDel, :)), [3, 1, 2]), hVol * st, 1);
                GI1 = reshape(permute(squeeze(GI(r-hDel:r+hDel, c-hDel:c+hDel, :, :)), [3, 1, 2, 4]), length(y1), 4);
                % Calculate the coefficients
                [coeff(r, c, :), ...
                 resNorm(r, c), ...
                 res(r, c, :), ~, ~, ~] = lsqlin(GI1, ... 
                                                 y1, ...
                                                 A, b, Aeq, beq, lb, ub, x0, options);
            end
        end
        % Fix boundaries with repetition
        coeff = padarray(coeff(1 + hDel : sr - hDel, 1 + hDel : sc - hDel, :), [hDel, hDel, 0], 'replicate');
        res = padarray(res(1 + hDel : sr - hDel, 1 + hDel : sc - hDel, :), [hDel, hDel, 0], 'replicate');
        resNorm = padarray(resNorm(1 + hDel : sr - hDel, 1 + hDel : sc - hDel), [hDel, hDel], 'replicate');
    else
        res = zeros(sr, sc, st);  % An array to hold the residuals at each time step
        for c = 1:sc
            for r = 1:sr        
                % Calculate the coefficients
                [coeff(r, c, :), ...
                 resNorm(r, c), ...
                 res(r, c, :), ~, ~, ~] = lsqlin(squeeze(GI(r, c, :, :)), ... 
                                                 squeeze(y(r, c, :)), ...
                                                 A, b, Aeq, beq, lb, ub, x0, options);
            end
        end
    end
end




% Evaluate the advection-diffusion model
% Each time step is calculated from prefious based on
%   In = I + dt * (D * (Ixx + Iyy) - VxIx - VyIy)
% or
%   y = A' * x
% where
%   y = (In - I)
%   x = dt * [D; Vx; Vy]
%   A = [(Ixx + Iyy), -Ix, -Iy]
% which can be solved for x as
%   xm = argmin_x{0.5 * ||A' * x - y||^2_2}
%   0 <= x_k 
% In this case the A and y are the temporal series of the values
function [coeff, res, resNorm] = advecDiff(stk, be, en, useHood, hoodSiz)
    % Calculate the time series of gradients and laplacians
    [Ix, Iy] = gradient(stk);
    lap = del2(stk);

    % Calculate the time series of the differences
    % TODO: make dependent on GI size
    y = diff(stk, 1, 3);

    % Stack and restrict time if any
    GI = cat(4, lap, -Ix, -Iy);
    GI = GI(:, :, be:en, :);
    y = y(:, :, be:en);

    % Setup constraint problem
    A = [];
    b = [];
    Aeq = [];
    beq = [];
    lb = [0, 0, 0];
    ub = [Inf, Inf, Inf];
    x0 = [];        
    options = optimoptions('lsqlin', ...
                           'Algorithm', 'trust-region-reflective', ...
                           'Display', 'off');

    % Calculate the advection-diffusion parameters
    [sr, sc, st, ~] = size(GI);
    coeff = zeros(sr, sc, 3);  % An array to hold the model coefficients
    resNorm = zeros(sr, sc);  % An array to hold the norm of the residuals 
    
    % If we are using the neighborhood
    if useHood
        hVol = hoodSiz * hoodSiz;
        hDel = (hoodSiz - 1) / 2;
        res = zeros(sr, sc, hVol * st);  % An array to hold the residuals at each time step
        for c = 1 + hDel : sc - hDel
            for r = 1 + hDel : sr - hDel
                y1 = reshape(permute(squeeze(y(r-hDel:r+hDel, c-hDel:c+hDel, :)), [3, 1, 2]), hVol * st, 1);
                GI1 = reshape(permute(squeeze(GI(r-hDel:r+hDel, c-hDel:c+hDel, :, :)), [3, 1, 2, 4]), length(y1), 3);
                % Calculate the coefficients
                [coeff(r, c, :), ...
                 resNorm(r, c), ...
                 res(r, c, :), ~, ~, ~] = lsqlin(GI1, ... 
                                                 y1, ...
                                                 A, b, Aeq, beq, lb, ub, x0, options);
            end
        end
        % Fix boundaries with repetition
        coeff = padarray(coeff(1 + hDel : sr - hDel, 1 + hDel : sc - hDel, :), [hDel, hDel, 0], 'replicate');
        res = padarray(res(1 + hDel : sr - hDel, 1 + hDel : sc - hDel, :), [hDel, hDel, 0], 'replicate');
        resNorm = padarray(resNorm(1 + hDel : sr - hDel, 1 + hDel : sc - hDel), [hDel, hDel], 'replicate');
    else
        res = zeros(sr, sc, st);  % An array to hold the residuals at each time step
        for c = 1:sc
            for r = 1:sr        
                % Calculate the coefficients
                [coeff(r, c, :), ...
                 resNorm(r, c), ...
                 res(r, c, :), ~, ~, ~] = lsqlin(squeeze(GI(r, c, :, :)), ... 
                                                 squeeze(y(r, c, :)), ...
                                                 A, b, Aeq, beq, lb, ub, x0, options);
            end
        end
    end
end




% Evaluate the advection-diffusion-source model
% Each time step is calculated from prefious based on
%   In = I + dt * (D * (Ixx + Iyy) - VxIx - VyIy + s) 
% or
%   y = A' * x
% where
%   y = (In - I)
%   x = dt * [D; Vx; Vy; s]
%   A = [(Ixx + Iyy), -Ix, -Iy, 1]
% which can be solved for x as
%   xm = argmin_x{0.5 * ||A' * x - y||^2_2}
%   0 <= x_k (except s)
% In this case the A and y are the temporal series of the values
function [coeff, res, resNorm] = advecDiffSrc(stk, be, en, useHood, hoodSiz)
    % Calculate the time series of gradients and laplacians
    [Ix, Iy] = gradient(stk);
    lap = del2(stk);

    % Calculate the time series of the differences
    % TODO: make dependent on GI size
    y = diff(stk, 1, 3);

    % Stack and restrict time if any
    GI = cat(4, lap, -Ix, -Iy, ones(size(lap)));
    GI = GI(:, :, be:en, :);
    y = y(:, :, be:en);

    % Setup constraint problem
    A = [];
    b = [];
    Aeq = [];
    beq = [];
    lb = [0, 0, 0, -Inf];
    ub = [Inf, Inf, Inf, Inf];
    x0 = [];        
    options = optimoptions('lsqlin', ...
                           'Algorithm', 'trust-region-reflective', ...
                           'Display', 'off');

    % Calculate the advection-diffusion+source parameters
    [sr, sc, st, ~] = size(GI);
    coeff = zeros(sr, sc, 4);  % An array to hold the model coefficients
    resNorm = zeros(sr, sc);  % An array to hold the norm of the residuals 
    
    % If we are using the neighborhood
    if useHood
        hVol = hoodSiz * hoodSiz;
        hDel = (hoodSiz - 1) / 2;
        res = zeros(sr, sc, hVol * st);  % An array to hold the residuals at each time step
        for c = 1 + hDel : sc - hDel
            for r = 1 + hDel : sr - hDel
                y1 = reshape(permute(squeeze(y(r-hDel:r+hDel, c-hDel:c+hDel, :)), [3, 1, 2]), hVol * st, 1);
                GI1 = reshape(permute(squeeze(GI(r-hDel:r+hDel, c-hDel:c+hDel, :, :)), [3, 1, 2, 4]), length(y1), 4);
                % Calculate the coefficients
                [coeff(r, c, :), ...
                 resNorm(r, c), ...
                 res(r, c, :), ~, ~, ~] = lsqlin(GI1, ... 
                                                 y1, ...
                                                 A, b, Aeq, beq, lb, ub, x0, options);
            end
        end
        % Fix boundaries with repetition
        coeff = padarray(coeff(1 + hDel : sr - hDel, 1 + hDel : sc - hDel, :), [hDel, hDel, 0], 'replicate');
        res = padarray(res(1 + hDel : sr - hDel, 1 + hDel : sc - hDel, :), [hDel, hDel, 0], 'replicate');
        resNorm = padarray(resNorm(1 + hDel : sr - hDel, 1 + hDel : sc - hDel), [hDel, hDel], 'replicate');
    else
        res = zeros(sr, sc, st);  % An array to hold the residuals at each time step
        for c = 1:sc
            for r = 1:sr        
                % Calculate the coefficients
                [coeff(r, c, :), ...
                 resNorm(r, c), ...
                 res(r, c, :), ~, ~, ~] = lsqlin(squeeze(GI(r, c, :, :)), ... 
                                                 squeeze(y(r, c, :)), ...
                                                 A, b, Aeq, beq, lb, ub, x0, options);
            end
        end
    end
end







% Calculate NSEW gradients (2D and 3D)
function [an, as, ae, aw] = grad(array, varargin)
    % Parse parameters
    p = inputParser;

    addRequired(p, 'array');

    addOptional(p, 'valid', false);
    addOptional(p, 'type', 'forward');
    addOptional(p, 'winSize', 5);

    parse(p, array, varargin{:});

    a = p.Results.array;
    valid = p.Results.valid;
    type = p.Results.type;
    winSize = p.Results.winSize;

    % Calculate the 1-diff gradients ignoring the z-direction. 
    an = circshift(a, -1, 1) - a;
    as = circshift(a, 1, 1) - a;
    ae = circshift(a, -1, 2) - a;
    aw = circshift(a, 1, 2) - a;

    % Check the approach
    switch type
        case 'central'
            [ae, an] = gradient(array);
            aw = -ae;
            as = -an;
        case 'average'
            flt = fspecial('disk', floor(winSize/2));
            flt = fspecial('gaussian', 8*floor(winSize/2), floor(winSize/2));
            switch ndims(a)
                case 2
                    A = cat(3, an, as, ae, aw);
                case 3
                    A = cat(4, an, as, ae, aw);
            end
            AN = imfilter(A, flt);
            switch ndims(a)
                case 2
                    an = AN(:, :, 1);
                    as = AN(:, :, 2);
                    ae = AN(:, :, 3);
                    aw = AN(:, :, 4);            
                case 3
                    an = AN(:, :, :, 1);
                    as = AN(:, :, :, 2);
                    ae = AN(:, :, :, 3);
                    aw = AN(:, :, :, 4);            
            end
        case 'svd'
            switch ndims(a)
                case 2
                    [an, as, ae, aw] = gradSVD(an, as, ae, aw, winSize);
                case 3
                    % Repeat above for each slice
                    for sl = 1:size(a, 3)
                        [an(:, :, sl), ...
                         as(:, :, sl), ...
                         ae(:, :, sl), ...
                         aw(:, :, sl)] = gradSVD(an(:, :, sl), ...
                                                 as(:, :, sl), ...
                                                 ae(:, :, sl), ...
                                                 aw(:, :, sl), ...
                                                 winSize);                   
                    end
            end                        
    end

    % If we want to use only the 'valid' data, crop
    if valid 
        switch ndims(a)
            case 2
                an = an(2 : end - 1, 2 : end - 1);
                as = as(2 : end - 1, 2 : end - 1);
                ae = ae(2 : end - 1, 2 : end - 1);
                aw = aw(2 : end - 1, 2 : end - 1);
            case 3
                an = an(2 : end - 1, 2 : end - 1, :);
                as = as(2 : end - 1, 2 : end - 1, :);
                ae = ae(2 : end - 1, 2 : end - 1, :);
                aw = aw(2 : end - 1, 2 : end - 1, :);
            otherwise  % Should never end here
                an = zeros(size(a));
                as = an;
                ae = an;
                aw = an;
        end
        return
    end

    % Otherwise set gradient to 0 at the borders. Equivalent to repeating
    % the value in that direction.
    switch ndims(a)
        case 2
            an(end, :) = 0;
            as(1, :) = 0;
            ae(:, end) = 0;
            aw(:, 1) = 0;
        case 3
            an(end, :, :) = 0;
            as(1, :, :) = 0;
            ae(:, end, :) = 0;
            aw(:, 1, :) = 0;
        otherwise  % Should never end here
            an = zeros(size(a));
            as = an;
            ae = an;
            aw = an;
    end
end






% Calculate SVD of gradients within window
function [an, as, ae, aw] = gradSVD(an, as, ae, aw, winSize)
    % Stack gradients
    A = cat(3, an, as, ae, aw);
    AN = zeros(size(A));

    % Calculate SVD in blocks of the given windows size
    dx = floor(winSize/2);
    dy = dx;
    for c = dx+1:size(A,1)-dx
        for r = dy+1:size(A,2)-dy
            s = A(c-dx:c+dx, r-dy:r+dy, :);
            s = reshape(permute(s, [3, 1, 2]), 4, [])';
            [u, s, v] = svds(s, 1);
            AN(c, r, :) = v;
        end
    end

    % Extract individual components
    an = AN(:, :, 1);
    as = AN(:, :, 2);
    ae = AN(:, :, 3);
    aw = AN(:, :, 4);            
end
    