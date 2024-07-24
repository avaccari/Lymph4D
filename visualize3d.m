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

function visualize3d(nc, coeff)
    %% Needed items
    smoothViz = 0;

    %% Setup figure and layout
    fig = uifigure();
    fig.Name = "3d directional map";
    fig.Position = [100, 100, 1000, 600];
    fig.focus;

    %% Main layout
    mainLayout = uigridlayout(fig);
    mainLayout.ColumnWidth = {300, '1x'};
    mainLayout.RowHeight = {'1x'};

    %% Configuration layout
    configLayout = uipanel(mainLayout);
    configLayout.Title = 'Configuration';
    configLayout.Layout.Row = 1;
    configLayout.Layout.Column = 1;

    configGrid = uigridlayout(configLayout);
    configGrid.ColumnWidth = {'1x'};
    configGrid.RowHeight = {20, '1x'};

    % Smooth visualization
    smoothCB = uicheckbox(configGrid);
    smoothCB.Text = 'Gaussian smooth';
    smoothCB.Layout.Row = 1;
    smoothCB.Layout.Column = 1;
    smoothCB.ValueChangedFcn = @smoothCBCallback;
    function smoothCBCallback(src, ~)
        smoothViz = src.Value;
        updateImage;
    end

    %% Image layout
    imageLayout = uigridlayout(mainLayout);
    imageLayout.ColumnWidth = {45, '1x', 45};
    imageLayout.RowHeight = {35, '1x', 30};
    imageLayout.Layout.Row = 1;
    imageLayout.Layout.Column = 2;

    % Add image
    imgAx = uiaxes(imageLayout);
    imgAx.XTick = [];
    imgAx.YTick = [];
    imgAx.Layout.Row = 2;
    imgAx.Layout.Column = 2;
    axis(imgAx, 'tight')
    imgZSlice = 1;
    imgChannel = 1;
    imgRange = [0, 100];
    dataCh = coeff(:, :, :, imgChannel);
    if smoothViz == 1
        dataCh = smooth3(dataCh, 'gaussian', [3, 3, 3]);
    end
    data = dataCh(:, :, imgZSlice);
    imgH = imagesc(imgAx, dataCh(:, :, imgZSlice));
    colorbar(imgAx);

    % Add the coefficient selection drop down
    cDDown = uidropdown(imageLayout);
    cDDown.Items = nc;
    cDDown.Layout.Row = 1;
    cDDown.Layout.Column = 2;
    cDDown.ValueChangedFcn = @cUpdateImage;
    function cUpdateImage(src, ~)
        imgChannel = src.ValueIndex;
        updateImage();
    end

    % Add the z slider
    zSlider = uislider(imageLayout);
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
    qSlider = uislider(imageLayout, 'range');
    qSlider.Limits = [0, 100];
    qSlider.Layout.Row = 3;
    qSlider.Layout.Column = 2;
    qSlider.ValueChangedFcn = @qUpdateImage;
    function qUpdateImage(src, ~)
        imgRange = src.Value;
        updateImage();
    end

    function updateImage()
        dataCh = coeff(:, :, :, imgChannel);
        switch nc{imgChannel}
            case {'Vx', 'Vy', 'Vz', 'Source'}
                % Maintain centered data while clipping
                q = quantile(abs(dataCh(:)), [imgRange(1), imgRange(2)] / 100);
                dataCh(dataCh < -q(2)) = -q(2);
                dataCh((-q(1) < dataCh) & (dataCh < 0)) = -q(1);
                dataCh((0 < dataCh) & (dataCh < q(1))) = q(1);
                dataCh(dataCh > q(2)) = q(2);
            otherwise
                q = quantile(dataCh(:), [imgRange(1), imgRange(2)] / 100);
                dataCh(dataCh < q(1)) = q(1);
                dataCh(dataCh > q(2)) = q(2);
        end

        if smoothViz == 1
            dataCh = smooth3(dataCh, 'gaussian', [3, 3, 3]);
        end

        data = dataCh(:, :, imgZSlice);
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
    end
end
