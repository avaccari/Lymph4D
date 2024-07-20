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
% function handles = directionMap3d(handles)
%     method = handles.direction.mapType;
%     useHood = handles.direction.useHood;
%     hoodSiz = handles.direction.hoodSiz;
%     useTimWin = handles.direction.useTimeWin;
%     winSiz = handles.direction.timeWinSiz;
%     useSmooth = handles.direction.smoothModel;
%     % Define spatial and temporal steps
%     ds = handles.expInfo.ds;
%     dt = handles.expInfo.dt;
%     % Define time range
%     be = handles.dirTempStart;
%     en = handles.dirTempEnd - 1;
%     % Grab image
%     stk= handles.stackImg;
%
%     % Notify user that operation is ongoing
%     if ~handles.dirMap.quiet
%         h = msgbox('Evaluating directional map...');
%     end
%
%     % Switch based on the method
%     % Choices (defined in guide):
%     % 1 - 5 (2d)
%     % 6 - '3D_Difs-Adv.'
%     switch method
%         % Simple contrast along time axis
%         % Nothing to do. This are the value calculated above.
%         case 1
%         case 2
%         case 3
%         case 4
%         case 5
%             % 3D diffusion-advection model
%         case 6
%             % Evaluate the advection-diffusion model
%             coeff = modAdvecDiff3d(stk, ds, dt);
%            nc = {'Diff Coeff', ...
%                'Vx', ...
%                'Vy', ...
%                'Vz', ...
%                'Vmag'};
% 
%
%
%     end
%
%     % Remove notification
%     if ~handles.dirMap.quiet
%         try
%             delete(h);
%         catch
%         end
%     end
%
%     % If we are not showing the results, we are done
%     if ~handles.dirMap.show
%         return
%     end
function visualize()
    nc = {'Diff Coeff', ...
       'Vx', ...
       'Vy', ...
       'Vz', ...
       'Vmag'};
    coeff = load("coeff.mat");
    coeff = coeff.coeff;
    
    % Small 3d Gaussian to smooth data
    g3d = zeros(3, 3, 3);
    g3d(:, :, 1) = [[1,1.5,1];[1.5,2.5,1.5];[1,1.5,1]];
    g3d(:, :, 2) = [[1.5,2.5,1.5];[2.5,4,2.5];[1.5,2.5,1.5]];
    g3d(:, :, 3) = g3d(:, :, 1);
    g3d = g3d ./ 45;

    % Evaluate derived parameters
    % Velocioty magnitude
    coeff = cat(4, coeff, sqrt(coeff(:,:,:,2).^2 + coeff(:,:,:,3).^2 + coeff(:,:,:,4).^2));
    
    % Visualize results
    fig = uifigure();
    gl = uigridlayout(fig);
    gl.RowHeight = {35, '1x', 30};
    gl.ColumnWidth = {45, '1x',45};
    
    % Add image
    % TODO: make the smoothing dependent on the user
    imgAx = uiaxes(gl);
    imgAx.XTick = [];
    imgAx.YTick = [];
    imgAx.Layout.Row = 2;
    imgAx.Layout.Column = 2;
    imgZSlice = 1;
    imgChannel = 1;
    imgRange = [0, 100];
    dataCh = coeff(:, :, :, imgChannel);
    dataCh = convn(dataCh, g3d, "same");
    data = dataCh(:, :, imgZSlice);    
    imgH = imagesc(imgAx, dataCh(:, :, imgZSlice));
    colorbar(imgAx);

    % Add the coefficient selection drop down
    cDDown = uidropdown(gl);
    cDDown.Items = nc;
    cDDown.Layout.Row = 1;
    cDDown.Layout.Column = 2;
    cDDown.ValueChangedFcn = @cUpdateImage;
    function cUpdateImage(src, ~)
        imgChannel = src.ValueIndex;
        updateImage();
    end
    
    
    % Add the z slider
    zSlider = uislider(gl);
    zSlider.Orientation = 'vertical';
    zSlider.Limits = [1, size(coeff, 3)];
    zSlider.MajorTicks = 1:size(coeff, 3);
    zSlider.MinorTicks = [];
    zSlider.Layout.Row = 2;
    zSlider.Layout.Column = 1;
    zSlider.ValueChangedFcn = @zUpdateImage;
    function zUpdateImage(src, ~)
        imgZSlice = round(src.Value);
        updateImage();
    end

    
    % Add quantile clipping slider
    qSlider = uislider(gl, 'range');
    qSlider.Limits = [0, 100];
    qSlider.Layout.Row = 3;
    qSlider.Layout.Column = 2;
    qSlider.ValueChangedFcn = @qUpdateImage;
    function qUpdateImage(src, ~)
        imgRange = src.Value;
        updateImage();
    end

    function updateImage()
        % data = coeff(:, :, imgZSlice, imgChannel);
        % Convolve with small Gaussian to smooth
        % q = quantile(data(:), [imgRange(1), imgRange(2)] / 100);
        dataCh = coeff(:, :, :, imgChannel);
        q = quantile(dataCh(:), [imgRange(1), imgRange(2)] / 100);
        dataCh(dataCh < q(1)) = q(1);
        dataCh(dataCh > q(2)) = q(2);
        dataCh = convn(dataCh, g3d, "same");
        data = dataCh(:, :, imgZSlice);
        imgH.CData = data;
        switch imgChannel
            case {2, 3, 4}
                % Center data
                xtrema = max(abs(data(:)));
                clim(imgAx, [-xtrema, xtrema]);
                colormap(imgAx, turbo(256));
            otherwise
                clim(imgAx, "auto");
                colormap(imgAx, parula(256));   
        end
    end

end

visualize()