function hmax_uiuc_show(path, locs)

% Displays an image with detection boxes.

%-----------------------------------------------------------------------------------------------------------------------

cla;
hold on;

image(uint8(floor(double(imread(path)) / 255 * 63)));    

for i = 1 : numel(locs.y)

    ys = locs.y(i) + [0, locs.h(i)];
    xs = locs.x(i) + [0, locs.w(i)];

    plot(xs([1 1 2 2 1]), ys([1 2 2 1 1]), 'r-');

end

hold off;

colormap gray;
axis image ij;

[rest, name, ext] = fileparts(path);
[ans, dir] = fileparts(rest);
title(strrep(sprintf('%s/%s%s', dir, name, ext), '_', '\_'));

return;