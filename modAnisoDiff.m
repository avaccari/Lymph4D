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
% TODO: Sliding temporal window not yet implemented. Need to find a way to
%       display all the results or mean, etc...
function [coeff, res, resNorm] = modAnisoDiff(stk, be, en, useTimWin, winSiz, useHood, hoodSiz)
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
