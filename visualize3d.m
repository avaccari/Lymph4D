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

function visualize3d(nc, coeff, stk)
    %% Default values for image controls
    imgZSlice = 1;
    imgChannel = 1;
    imgRange = [0, 1];
    imgAValue = 1.0;
    smoothViz = 0;
    useBaseImg = 0;
    baseQValue = 0.5;
    vol3dAValue = 0.0;
    vol3dOAValue = 1.0;

    %% Setup figure and layout
    fig = uifigure();
    fig.Name = "3d directional map";
    fig.Position = [100, 100, 1000, 600];
    fig.focus;

    %% Main layout
    mainLayout = uigridlayout(fig);
    mainLayout.ColumnWidth = {'0.5x', '1x'};
    mainLayout.RowHeight = {'1x'};

    %% Config-3D layout
    config3dLayout = uigridlayout(mainLayout);
    config3dLayout.Layout.Row = 1;
    config3dLayout.Layout.Column = 1;
    config3dLayout.ColumnWidth = {'1x'};
    config3dLayout.RowHeight = {'0.5x', '1x'};

    %% Configuration analysis layout
    configLayout = uipanel(config3dLayout);
    configLayout.Title = 'Configuration';
    configLayout.Layout.Row = 1;
    configLayout.Layout.Column = 1;

    %% Configuration layout
    configGrid = uigridlayout(configLayout);
    configGrid.ColumnWidth = {'1x'};
    configGrid.RowHeight = {15, 15, 40, '1x'};

    % Smooth visualization
    smoothCB = uicheckbox(configGrid);
    smoothCB.Text = 'Gaussian smooth';
    smoothCB.Layout.Row = 1;
    smoothCB.Layout.Column = 1;
    smoothCB.ValueChangedFcn = @smoothCBUpdateImage;
    function smoothCBUpdateImage(src, ~)
        smoothViz = src.Value;
        updateImage();
        update3DVolume();
    end

    % Use base image to clean data
    useBaseCB = uicheckbox(configGrid);
    useBaseCB.Text = 'Use base image to clip results';
    useBaseCB.Layout.Row = 2;
    useBaseCB.Layout.Column = 1;
    useBaseCB.ValueChangedFcn = @useBaseCBUpdateImage;
    function useBaseCBUpdateImage(src, ~)
        useBaseImg = src.Value;
        updateImage();
        update3DVolume();
    end

    % Specify quantile to clean data
    useBaseSlider = uislider(configGrid);
    useBaseSlider.Limits = [0, 100];
    useBaseSlider.Value = 50;
    useBaseSlider.Layout.Row = 3;
    useBaseSlider.Layout.Column = 1;
    useBaseSlider.ValueChangedFcn = @useBaseSliderUpdateImage;
    function useBaseSliderUpdateImage(src, ~)
        baseQValue = src.Value / 100;
        updateImage();
    end

    %% 3D layout
    grid3d = uigridlayout(config3dLayout);
    grid3d.ColumnWidth = {'1x'};
    grid3d.RowHeight = {'1x', 40, 40};

    % 3D volume layout
    layout3D = uipanel(grid3d);
    layout3D.Title = '3D';
    layout3D.Layout.Row = 1;
    layout3D.Layout.Column = 1;

    % Add image
    v3dAx = viewer3d(Parent = layout3D);
    v3dAx.ClippingPlanes = [0, 0, 1, -imgZSlice];
    v3dAx.ClippingInteractions = 'none';
    sz = size(stk, 1:3) / 2;
    v3dAx.CameraPosition = [sz(1), sz(2), -1];
    v3dAx.LightPosition = [sz(1), sz(2), -1];
    v3dAx.CameraUpVector = [0, -1, 0];
    vol3dH = volshow(zeros(size(coeff, 1:3)), Parent = v3dAx);
    vol3dH.RenderingStyle = 'GradientOpacity';

    % Update 3D volume with current values
    update3DVolume();

    % Add the base image alpha slider
    vol3dBaseAlphaSlider = uislider(grid3d);
    vol3dBaseAlphaSlider.Limits = [0, 100];
    vol3dBaseAlphaSlider.Value = 0;
    vol3dBaseAlphaSlider.Layout.Row = 2;
    vol3dBaseAlphaSlider.Layout.Column = 1;
    vol3dBaseAlphaSlider.ValueChangedFcn = @vol3dBaseAlphaSliderUpdateImage;
    function vol3dBaseAlphaSliderUpdateImage(src, ~)
        vol3dAValue = src.Value / 100;
        update3DVolume();
    end

    % Add the overlay alpha slider
    vol3dOverlayAlphaSlider = uislider(grid3d);
    vol3dOverlayAlphaSlider.Limits = [0, 100];
    vol3dOverlayAlphaSlider.Value = 100;
    vol3dOverlayAlphaSlider.Layout.Row = 3;
    vol3dOverlayAlphaSlider.Layout.Column = 1;
    vol3dOverlayAlphaSlider.ValueChangedFcn = @vol3dOverlayAlphaSliderUpdateImage;
    function vol3dOverlayAlphaSliderUpdateImage(src, ~)
        vol3dOAValue = src.Value / 100;
        update3DVolume();
    end

    %% Image layout
    imageLayout = uigridlayout(mainLayout);
    imageLayout.ColumnWidth = {45, '1x', 45};
    imageLayout.RowHeight = {35, '1x', 30};
    imageLayout.Layout.Row = 1;
    imageLayout.Layout.Column = 2;

    % Add base image
    imgBAx = uiaxes(imageLayout);
    imgBAx.Visible = 'off';
    imgBAx.XTick = [];
    imgBAx.YTick = [];
    imgBAx.Layout.Row = 2;
    imgBAx.Layout.Column = 2;
    imgBH = imagesc(imgBAx, zeros(size(coeff, 1:2)));
    cb = colorbar(imgBAx);
    axis(imgBAx, 'tight');
    cb.Visible = "off";

    % Add image
    imgAx = uiaxes(imageLayout);
    imgAx.Visible = 'off';
    imgAx.XTick = [];
    imgAx.YTick = [];
    imgAx.Layout.Row = 2;
    imgAx.Layout.Column = 2;
    imgH = imagesc(imgAx, zeros(size(coeff, 1:2)));
    colorbar(imgAx);
    axis(imgAx, 'tight');

    % Update images with current values
    updateImage();

    % Add the coefficient selection drop down
    cDDown = uidropdown(imageLayout);
    cDDown.Items = nc;
    cDDown.Layout.Row = 1;
    cDDown.Layout.Column = 2;
    cDDown.ValueChangedFcn = @cSliderUpdateImage;
    function cSliderUpdateImage(src, ~)
        imgChannel = src.ValueIndex;
        updateImage();
        update3DVolume();
    end

    % Add the z slider
    zSlider = uislider(imageLayout);
    zSlider.Orientation = 'vertical';
    zSlider.Limits = [1, size(coeff, 3)];
    zSlider.Value = 1;
    zSlider.MajorTicks = 1:size(coeff, 3);
    zSlider.MinorTicks = [];
    zSlider.Layout.Row = 2;
    zSlider.Layout.Column = 1;
    zSlider.ValueChangingFcn = @zSliderUpdateImage;
    zSlider.ValueChangedFcn = @zSliderUpdate;
    zSlider.UserData.PreviousValue = imgZSlice;
    function zSliderUpdateImage(src, event)
        imgZSlice = round(event.Value);
        if imgZSlice ~= src.UserData.PreviousValue
            src.UserData.PreviousValue = imgZSlice;
            updateImage();
            update3DVolume();
        end
    end
    function zSliderUpdate(src, ~)
        src.Value = imgZSlice;
    end

    % Add quantile clipping slider
    qSlider = uislider(imageLayout, 'range');
    qSlider.Limits = [0, 100];
    qSlider.Value = [0, 100];
    qSlider.Layout.Row = 3;
    qSlider.Layout.Column = 2;
    qSlider.ValueChangedFcn = @qSliderUpdateImage;
    function qSliderUpdateImage(src, ~)
        imgRange = src.Value / 100;
        updateImage();
        update3DVolume();
    end

    % Add the alpha slider
    aSlider = uislider(imageLayout);
    aSlider.Orientation = 'vertical';
    aSlider.Limits = [0, 100];
    aSlider.Value = 100;
    aSlider.Layout.Row = 2;
    aSlider.Layout.Column = 3;
    aSlider.ValueChangedFcn = @aSliderUpdateImage;
    function aSliderUpdateImage(src, ~)
        imgAValue = src.Value / 100;
        updateImage();
        update3DVolume();
    end

    %% Update image callback
    function updateImage()
        % Update base image
        dataB = mean(stk, 4);
        qb = quantile(dataB(:), [0.05, 0.95, baseQValue]);
        dataB(dataB < qb(1)) = qb(1);
        dataB(dataB > qb(2)) = qb(2);
        imgBH.CData = dataB(:, :, imgZSlice);
        colormap(imgBAx, colorcet('L1', 'N', 256));

        % Evaluate data ranges based on slider
        dataq = coeff(:, :, :, imgChannel);
        switch nc{imgChannel}
            case {'Vx', 'Vy', 'Vz', 'Source'}
                % Maintain centered data while clipping
                q = quantile(abs(dataq(:)), [imgRange(1), imgRange(2)]);
                dataq(dataq < -q(2)) = -q(2);
                dataq((-q(1) < dataq) & (dataq < 0)) = -q(1);
                dataq((0 < dataq) & (dataq < q(1))) = q(1);
                dataq(dataq > q(2)) = q(2);
            otherwise
                q = quantile(dataq(:), [imgRange(1), imgRange(2)]);
                dataq(dataq < q(1)) = q(1);
                dataq(dataq > q(2)) = q(2);
        end

        % Smooth the volume if required
        if smoothViz == 1
            dataq = smooth3(dataq, 'gaussian', [3, 3, 3]);
        end

        % Update image
        data = dataq(:, :, imgZSlice);
        imgH.CData = data;
        switch nc{imgChannel}
            case {'Vx', 'Vy', 'Vz', 'Source'}
                % Center data around zero for better visualization
                xtrema = max(abs(data(:)));
                clim(imgAx, [-xtrema, xtrema]);
                colormap(imgAx, colorcet('D1', 'N', 256));
            otherwise
                clim(imgAx, "auto");
                colormap(imgAx, colorcet('L20', 'N', 256));
        end

        % Update alpha channel
        alpha = imgAValue * ones(size(data));
        if useBaseImg
            alpha(dataB(:, :, imgZSlice) <= qb(3)) = 0;
        end

        imgH.AlphaData = alpha;
    end

    %% Update 3D volume callback
    function update3DVolume()
        % Update base image
        dataB = mean(stk, 4);
        qb = quantile(dataB(:), [0.1, 0.95, baseQValue]);
        dataB(dataB < qb(1)) = qb(1);
        dataB(dataB > qb(2)) = qb(2);
        vol3dH.Data = dataB;
        colormap(vol3dH, colorcet('L1', 'N', 256));

        % Update 3D volume
        data = coeff(:, :, :, imgChannel);
        switch nc{imgChannel}
            case {'Vx', 'Vy', 'Vz', 'Source'}
                % Maintain centered data while clipping
                q = quantile(abs(data(:)), [imgRange(1), imgRange(2)]);
                data(data < -q(2)) = -q(2);
                data((-q(1) < data) & (data < 0)) = -q(1);
                data((0 < data) & (data < q(1))) = q(1);
                data(data > q(2)) = q(2);
            otherwise
                q = quantile(data(:), [imgRange(1), imgRange(2)]);
                data(data < q(1)) = q(1);
                data(data > q(2)) = q(2);
        end

        % Smooth the volume if required
        if smoothViz == 1
            data = smooth3(data, 'gaussian', [3, 3, 3]);
        end

        % Update 3D volume
        vol3dH.OverlayData = data;
        switch nc{imgChannel}
            case {'Vx', 'Vy', 'Vz', 'Source'}
                % Center data around zero for better visualization
                % xtrema = max(abs(data(:)));
                % vol3dH.DataLimits = [-xtrema, xtrema];
                % clim(v3dAx, [-xtrema, xtrema]);
                vol3dH.OverlayColormap = colorcet('D1', 'N', 256);
            otherwise
                % clim(v3dAx, "auto");
                vol3dH.DataLimitsMode = 'Auto';
                vol3dH.OverlayColormap = colorcet('L20', 'N', 256);
        end

        % Update base alpha value
        vol3dH.GradientOpacityValue = vol3dAValue;

        % Update overlay alpha value
        vol3dH.OverlayAlphamap = vol3dOAValue;

        % Update clipping plane
        v3dAx.ClippingPlanes = [0, 0, 1, -imgZSlice];
    end
end

% % test code
% coeff = load("coeff_test.mat");
% coeff = coeff.coeff;
% stack = load("stack_test.mat");
% stk = stack.stk4D;
% nc = {'Diff Coeff', ...
%           'Vx', ...
%           'Vy', ...
%       'Vz'};
% 
% visualize3da(nc, coeff, stk);
