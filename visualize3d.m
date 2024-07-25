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
    imgAValue = 1;
    smoothViz = 0;
    useBaseImg = 0;
    baseQValue = 0.5;


    %% Setup figure and layout
    fig = uifigure();
    fig.Name = "3d directional map";
    fig.Position = [100, 100, 1000, 600];
    fig.focus;

    %% Main layout
    mainLayout = uigridlayout(fig);
    mainLayout.ColumnWidth = {300, '1x'};
    mainLayout.RowHeight = {'1x'};

    %% Config-analysis layout
    configAnalysisLayout = uigridlayout(mainLayout);
    configAnalysisLayout.Layout.Row = 1;
    configAnalysisLayout.Layout.Column = 1;
    configAnalysisLayout.ColumnWidth = {'1x'};
    configAnalysisLayout.RowHeight = {'1x','1x'};
    
    %% Configuration analysis layout
    configLayout = uipanel(configAnalysisLayout);
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

    %% Analysis layout
    analysisconfigLayout = uipanel(configAnalysisLayout);
    analysisconfigLayout.Title = 'Analysis';
    analysisconfigLayout.Layout.Row = 2;
    analysisconfigLayout.Layout.Column = 1;

    

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
    zSlider.ValueChangedFcn = @zSliderUpdateImage;
    function zSliderUpdateImage(src, ~)
        imgZSlice = round(src.Value);
        updateImage();
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
    end




    % Update callback
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
end

% % test code
% coeff = load("coeff_test.mat");
% coeff = coeff.coeff;
% stack = load("stack_test.mat");
% stk = stack.stk4D;
% nc = {'Diff Coeff', ...
%           'Vx', ...
%           'Vy', ...
%           'Vz'};
% 
% visualize3da(nc, coeff, stk);