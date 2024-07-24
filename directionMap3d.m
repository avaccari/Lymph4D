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
function handles = directionMap3d(handles)
    method = handles.direction.mapType;
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
    % This will automatically drop the last temporal slice of GI (see
    % in the model files)
    en = handles.dirTempEnd - 1;
    % Grab image
    stk = handles.stackImg;

    % Notify user that operation is ongoing
    if ~handles.dirMap.quiet
        h = msgbox('Evaluating directional map...');
    end

    % Switch based on the method
    % Choices (defined in guide):
    % 1 - 5 (2d)
    % 6 - '3D_Difs-Adv.'
    switch method
            % Simple contrast along time axis
            % Nothing to do. This are the value calculated above.
        case 1
        case 2
        case 3
        case 4
        case 5
            % 3D diffusion-advection model
        case 6
            % Evaluate the advection-diffusion model
            coeff = modAdvecDiff3d(stk, be, en, ds, dt, useHood, hoodSiz, useSmooth);

            % Evaluate derived parameters
            % Velocity magnitude
            coeff = cat(4, coeff, sqrt(coeff(:, :, :, 2) .^ 2 + coeff(:, :, :, 3) .^ 2 + coeff(:, :, :, 4) .^ 2));

            % Specify parameters to display
            nc = {'Diff Coeff', ...
                      'Vx', ...
                      'Vy', ...
                      'Vz', ...
                  'Vmag'};
            % 3D diffusion-advection-source model
        case 7
            % Evaluate the advection-diffusion-source model
            coeff = modAdvecDiffSrc3d(stk, be, en, ds, dt, useHood, hoodSiz, useSmooth);

            % Specify parameters to display
            nc = {'Diff Coeff', ...
                      'Vx', ...
                      'Vy', ...
                      'Vz', ...
                      'Vmag', ...
                  'Source'};

            % Evaluate derived parameters
            % Velocity magnitude
            vmag = sqrt(coeff(:, :, :, 2) .^ 2 + coeff(:, :, :, 3) .^ 2 + coeff(:, :, :, 4) .^ 2);

            % Build display array according to nc
            coeff = cat(4, ...
                coeff(:, :, :, 1:4), ...
                vmag, ...
                coeff(:, :, :, 5));
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

    % Visualize map
    visualize3d(nc, coeff);
