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

% Evaluate the advection-diffusion model
% Each time step is calculated from previous based on
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
function [coeff, res, resNorm] = modAdvecDiff(stk, be, en, useHood, hoodSiz)
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
    lb = [0, -Inf, -Inf];
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
