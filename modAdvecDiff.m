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

% Evaluate the advection-diffusion model
% Each time step is calculated from previous based on
%   In = I + dt * (D * (Ixx + Iyy) - VxIx - VyIy)
% or
%   y = A' * x
% where
%   y = (In - I) / dt
%   x = [D; Vx; Vy]
%   A = [(Ixx + Iyy), -Ix, -Iy]
% which can be solved for x as
%   xm = argmin_x{0.5 * ||A' * x - y||^2_2}
%   0 <= x_k
% In this case the A and y are the temporal series of the values
function [coeff, res, resNorm] = modAdvecDiff(stk, be, en, ds, dt, useTimWin, winSiz, useHood, hoodSiz, useSmooth)
    % If smoothing, smooth each layer of the stack
    sizeStk = size(stk);
    tLen = size(stk, 3);
    if useSmooth
        for tIdx = 1:tLen
            stk(:, :, tIdx) = smoothdata2(stk(:, :, tIdx), 'gaussian', 3);
        end
    end

    % Calculate the time series of gradients and laplacians
    % [Ix, Iy] = gradient(stk);
    % lap = 4 * del2(stk);
    [Ix, Iy, ~] = gradient(stk, ds(2), ds(1), ds(3));

    % Calculate Laplacian for each time entry
    lap = zeros(sizeStk);
    for tIdx = 1:tLen
        % Laplacian compensated for (del^2 u)/2/n, where n is ndims(u)
        lap(:, :, tIdx) = 4 * del2(stk(:, :, tIdx), ds(2), ds(1));
    end

    % Calculate the time series of the differences
    % TODO: make dependent on GI size
    y = diff(stk, 1, 3) / dt;

    % Scale variable before the fit (switch to physical units: um, s)
    % handles.expInfo.ds = [dr, dc, dz] but we assume dr=dc and dz=1
    % alpha = 0.5 * dt / ds(1);
    % beta = 2 * alpha / ds(1);  % beta = dt / ds(1)^2
    % Ix = alpha * Ix;
    % Iy = alpha * Iy;
    % lap = beta * lap;

    % Stack and restrict time if any
    GI = cat(4, lap, -Ix, -Iy);

    % Check if we are using the time sliding windows
    if useTimWin
        % Loop sliding the window
        for tIdx = be:en - winSiz + 1
            % Extract temporal slices
            GIs = GI(:, :, tIdx:tIdx + winSiz - 1, :);
            ys = y(:, :, tIdx:tIdx + winSiz - 1);
            [coeff(:, :, :, tIdx), ...
                 res(:, :, :, tIdx), ...
                 resNorm(:, :, tIdx)] = evalAdvecDiff(GIs, ys, useHood, hoodSiz);
        end

        % ************************ TEMPORARY ***********************
        % Extract values corresponding to max velocity mag
        vmag = sqrt(coeff(:, :, 2, :) .^ 2 + coeff(:, :, 3, :) .^ 2);
        [~, vMaxIdx] = max(vmag, [], 4);
        [sc, sr] = size(coeff(:, :, 1, 1));
        for i = 1:sc
            for j = 1:sr
                ncoeff(i, j, :) = coeff(i, j, :, vMaxIdx(i, j));
                nres(i, j, :) = res(i, j, :, vMaxIdx(i, j));
                nresNorm(i, j) = resNorm(i, j, vMaxIdx(i, j));
            end
        end
        coeff = ncoeff;
        res = nres;
        resNorm = nresNorm;

    else
        GI = GI(:, :, be:en, :);
        y = y(:, :, be:en);
        [coeff, res, resNorm] = evalAdvecDiff(GI, y, useHood, hoodSiz);
    end
end
