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

% Evaluate model
function coeff = evalAdvecDiff3d(GI, y, useHood, hoodSiz)
    % Setup constraint problem
    A = [];
    b = [];
    Aeq = [];
    beq = [];
    lb = [0, -Inf, -Inf, -Inf];
    ub = [Inf, Inf, Inf, Inf];
    x0 = [];
    % Crashes if A and d are zeros
    %     options = optimoptions('lsqlin', ...
    %                            'Algorithm', 'trust-region-reflective', ...
    %                            'Display', 'off');
    options = optimoptions('lsqlin', ...
        'Algorithm', 'interior-point', ...
        'Display', 'off');

    % Calculate the advection-diffusion parameters
    % TODO think about the following: optimization with local regularization
    % in 3x3x3 neighborhood
    [sc, sr, sd, st, ~] = size(GI);
    coeff = zeros(sc, sr, sd, 4); % An array to hold the model coefficients

    % If we are using the neighborhood:
    % - pad the coeff array with repetition in x, y, and z depending on the hoodSiz
    % - for y use data from all the elements in the hood, no padding needed
    % - evaluate on hoodSiz x hoodSiz x hoodSiz only on valid part of the the
    %   padded arrays
    if useHood
        padSize = floor(hoodSiz / 2);
        % Pad GI and y
        GIp = padarray(GI, [padSize, padSize, padSize, 0, 0], 'replicate', 'both');
        yp = padarray(y, [padSize, padSize, padSize, 0], 'replicate', 'both');
        % Evaluate the coefficients
        parfor d = 1:sd
            for c =1:sc
                for r = 1:sr
                    % squeeze removes the empty dimensions
                    % permute brings the time as first axis
                    % reshape collapses x, y, z, and t and creates and
                    % creates two arrays:
                    % y1(t) with the value of y at time (t)
                    % GI1(t, :) with the gradients corresponding to that
                    % particluar y1(t)
                    y1 = reshape(permute(squeeze(yp(c:c + hoodSiz - 1, r:r + hoodSiz - 1, d:d + hoodSiz - 1, :)), [4, 1, 2, 3]), hoodSiz * hoodSiz * hoodSiz * size(y, 4), 1);
                    GI1 = reshape(permute(squeeze(GIp(c:c + hoodSiz - 1, r:r + hoodSiz - 1, d:d + hoodSiz - 1, :, :)), [4, 1, 2, 3, 5]), length(y1), size(GI, 5));
                    coeff(c, r, d, :) = lsqlin(GI1, y1, A, b, Aeq, beq, lb, ub, x0, options);
                end
            end
        end
    else  % No hood
        parfor d = 1:sd
            for c = 1:sc
                for r = 1:sr
                    % Calculate the coefficients
                    coeff(c, r, d, :) = lsqlin( ...
                        squeeze(GI(c, r, d, :, :)), ...
                        squeeze(y(c, r, d, :)), ...
                        A, b, Aeq, beq, lb, ub, x0, options);
                end
            end
        end
    end
end
