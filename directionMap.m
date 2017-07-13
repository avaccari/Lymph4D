% Copyright 2017 Andrea Vaccari (av9g@virginia.edu)

% Display info about current image
function handles = directionMap(handles)
    method = handles.dirMapType;

    % Notify user that saving is ongoing
    h = msgbox('Evaluating directional map...');

    % Define the base image
    img = mean(handles.stackImg, 4);
    img = img(:, :, handles.sliceIdx);

    % Check if a region is defined
    if isfield(handles.drawing, 'poly')
        % Find enclosing rectangle
        Mm = minmax(handles.drawing.poly.getPosition()');
        rmM = floor(Mm(1, :));
        cmM = ceil(Mm(2, :));

        % Extract the temporal stack for the current slice
        stk = squeeze(handles.stackImg(cmM(1)-1:cmM(2)+1, rmM(1)-1:rmM(2)+1, handles.sliceIdx, :));
        
        % Define the polygon mask
        mask = handles.drawing.poly.createMask();
    else
        % Encosing rectangle is the whole image
        rmM = [2, size(img, 1) - 1];
        cmM = [2, size(img, 2) - 1];
        
        % Extract the temporal stack for the current slice
        stk = squeeze(handles.stackImg(:, :, handles.sliceIdx, :));
        mask = ones(size(img));
    end
    
    % Define global channels arrays (append to these inside each method)
    chnls = {'Max-Min'};
    ovrl = max(handles.stackImg(:, :, handles.sliceIdx, :), [], 4) - ...
           min(handles.stackImg(:, :, handles.sliceIdx, :), [], 4);
    
    % Switch based on the method
    switch method
        % Anisotropic diffusion
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
        case 1
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
            be = 1;
            en = handles.stackNum - 1;  
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
            [sr, sc, ~, ~] = size(GI);
            coeff = zeros(sr, sc, 4);
            parfor c = 1:sc
                for r = 1:sr        
                    % Calculate the coefficients
                    coeff(r, c, :) = lsqlin(squeeze(GI(r, c, :, :)), ... 
                                            squeeze(y(r, c, :)), ...
                                            A, b, Aeq, beq, lb, ub, x0, options);
                end
            end
            
            % Add results to overlays list...
            nc = {'Coeff Max', ...
                  'Reluctance', ...
                  'Coeff Idx', ...
                  'Coeff North', ...
                  'Coeff South', ...
                  'Coeff East', ...
                  'Coeff West'};
            snc = length(nc);
            chnls = [chnls, nc];

            % ... and data
            [M, I] = max(coeff, [], 3);
            relc = exp(-M);
            ovrl = cat(3, ovrl, zeros([size(img), snc]));
            ovrl(cmM(1):cmM(2), rmM(1):rmM(2), end-snc+1:end) = cat(3, ...
                                                                    M, ...
                                                                    relc, ...
                                                                    I, ...
                                                                    coeff);
            
                        
        % Advection-diffusion
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
        case 2
            % Calculate the time series of gradients and laplacians
            [Ix, Iy] = gradient(stk);
            lap = del2(stk);

            % Calculate the time series of the differences
            % TODO: make dependent on GI size
            y = diff(stk, 1, 3);
            
            % Stack and restrict time if any
            be = 1;
            en = handles.stackNum - 1;  
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

            % Calculate the anisotropic parameters
            [sr, sc, ~, ~] = size(GI);
            coeff = zeros(sr, sc, 3);
            parfor c = 1:sc
                for r = 1:sr        
                    % Calculate the coefficients
                    coeff(r, c, :) = lsqlin(squeeze(GI(r, c, :, :)), ... 
                                            squeeze(y(r, c, :)), ...
                                            A, b, Aeq, beq, lb, ub, x0, options);
                end
            end
            
            % Add results to overlays list...
            nc = {'Diff Coeff', ...
                  'Reluctance', ...
                  'Vmag', ...
                  'Vx', ...
                  'Vy'};
            snc = length(nc);
            chnls = [chnls, nc];

            % ... and data
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
                                                                    coeff(:, :, 2:end));

                                                                
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
        case 3
            
            
            
    end

    
    
    % Remove notification
    try
        delete(h);
    catch ME
    end

    % Overlay on grayscale version of image
    fig = figure(handles.figs.dirMap);

    % Mask the overlays
    ovrlSiz = length(chnls);
    ovrl = ovrl .* repmat(mask, 1, 1, ovrlSiz);

    % Convert orignal image to rgb grayscale
    img = repmat(1-imadjust(mat2gray(img)), 1, 1, 3);
    imagesc(img);
    title('Directional Analysis');

    % Add the overlays
    hold on;

    channel = 1;
    h = imagesc(ovrl(:, :, channel));
    hax = gca();
    colormap(hax, 'hot');
    set(h, 'AlphaData', mask);
    colorbar;

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
        set(hax, 'CLim', mM);
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
                      'position', [0.9, 0.1, 0.05, 0.825]);
    addlistener(hthrs, 'Value', 'PostSet', @setOverlay);         
    function setOverlay(src, evt)
        data = ovrl(:, :, channel);
        mM = minmax(data(:)');
        tmask = mask;
        tmask(data < (mM(1) + diff(mM) * hthrs.Value)) = 0;
        set(h, 'AlphaData', hsldr.Value * tmask);      
        
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
    