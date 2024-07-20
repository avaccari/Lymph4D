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
function coeff = evalAdvecDiff3d(GI, y)
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
    % TODO think about the following: local regularization in 3x3x3 neighborhood
    [sc, sr, sd, ~, ~] = size(GI);
    coeff = zeros(sc, sr, sd, 4);  % An array to hold the model coefficients
    
    parfor d = 1:sd
        for c = 1:sc
            for r = 1:sr
                % Calculate the coefficients
                coeff(c, r, d, :) = lsqlin(...
                    squeeze(GI(c, r, d, :, :)), ...
                    squeeze(y(c, r, d, :)), ...
                    A, b, Aeq, beq, lb, ub, x0, options);
            end
        end
    end
end