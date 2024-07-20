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
%   In = I + dt * (D * (Ixx + Iyy + Izz) - VxIx - VyIy - VzIz)
% or
%   y = A' * x
% where
%   y = (In - I) / dt
%   x = [D; Vx; Vy; Vz]
%   A = [(Ixx + Iyy + Izz), -Ix, -Iy, -Iz]
% which can be solved for x as
%   xm = argmin_x{0.5 * ||A' * x - y||^2_2}
%   0 <= x_k
% In this case the A and y are the temporal series of the values
function coeff = modAdvecDiff3d(stk, ds, dt)
    % Calculate the time series of gradients and laplacians
    % When visualized, the order of the coordinates in the stack is row, col, z, t
    % so, using the standard visualization, we will consider y, x, z, t for the
    % derivatives
    
    % Gradient
    [Ix, Iy, Iz, ~] = gradient(stk, ds(2), ds(1), ds(3), 1);
    
    % Calculate Laplacian for each time entry
    sizeStk = size(stk);
    tLen = sizeStk(4);
    lap = zeros(sizeStk);
    for tIdx = 1:tLen
        % Laplacian compensated for (del^2 u)/2/n, where n is ndims(u)
        lap(:, :, :, tIdx) = 6 * del2(stk(:, :, :, tIdx), ds(2), ds(1), ds(3));
    end
    
    % Stack the gradient image
    GI = cat(5, lap, -Ix, -Iy, -Iz);
    
    % Calculate the time series of the differences
    % [(2)-X(1)  X(3)-X(2) ... X(n)-X(n-1)]
    y = diff(stk, 1, 4) / dt;
    
    % The forward modes evaluates future ys based on the current GI. GI has an
    % additional temporal step which is not used in the forward model so we can
    % drop it.
    GI = GI(:, :, :, 1:end - 1, :);
    
    % Evaluate the x (coeff)
    coeff = evalAdvecDiff3d(GI, y);
end


