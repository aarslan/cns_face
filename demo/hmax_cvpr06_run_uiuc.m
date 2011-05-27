% hmax_cvpr06_run_uiuc - Demo script that performs single-class detection and
% localization.
%
% This script runs hmax against the UIUC Car Detection dataset using the model
% configuration of [Mutch & Lowe 2006].
%
% *** NOTE: this script uses a large CNS model to compute all the sliding window
%     positions in parallel on a GPU.  It will *only* run on a GPU with at least
%     3GB memory (i.e., a Tesla card).  It has only been *tested* on a 4GB card.
%     (It could of course run in CPU mode, but much more slowly.)
%
% You will have to copy and edit this script to provide the path of the UIUC
% dataset on your system.
%
% You might also want to insert "save" commands at appropriate points in this
% script, as it will take some time to run.
%
% See hmax_cvpr06_run_simple for more comments on individual command usage.
%
% See also: hmax_cvpr06_run_simple, hmax_cvpr06_run_cal101.

%-----------------------------------------------------------------------------------------------------------------------

clc;

fprintf('\n');

while true
    ans = lower(strtrim(input('All variables will be cleared.  Is this okay (y/n) ? ', 's')));
    if isempty(ans), continue; end
    if ans(1) == 'y', break; end
    if ans(1) == 'n', return; end
end    

fprintf('\n');

clear;

%-----------------------------------------------------------------------------------------------------------------------

% Edit this section to supply script parameters.

dataPath = '/Users/aarslan/Documents/Databases/UIU/CarData/';       % Path where the UIUC car dataset and scoring programs can be found (*** required ***).

numFeatures = 1024;  % Number of S2 features in the final model.
numFeatures = 256; %ALI
rounds      = 3;     % Number of rounds of feature selection.

%-----------------------------------------------------------------------------------------------------------------------

if isempty(dataPath)
    error('you must edit this script to supply the path of the UIUC car dataset (variable "dataPath")');
end

if ~exist(fullfile(dataPath, 'trueLocations.txt'), 'file')
    error('cannot find the UIUC car dataset at path "%s"', dataPath);
end

totalSamples = numFeatures * 2 ^ rounds;

trainCats  = [];
trainPaths = {};
for i = 0 : 549
    trainCats (end + 1) = 1;
    trainPaths{end + 1} = fullfile(dataPath, 'TrainImages', sprintf('pos-%u.pgm', i));
end
for i = 0 : 499
    trainCats (end + 1) = 2;
    trainPaths{end + 1} = fullfile(dataPath, 'TrainImages', sprintf('neg-%u.pgm', i));
end
inds = randperm(numel(trainCats));
trainCats  = trainCats (inds);
trainPaths = trainPaths(inds);

ssTestPaths = {};
msTestPaths = {};
for i = 0 : 169
    ssTestPaths{end + 1} = fullfile(dataPath, 'TestImages', sprintf('test-%u.pgm', i));
end
for i = 0 : 107
    msTestPaths{end + 1} = fullfile(dataPath, 'TestImages_Scale', sprintf('test-%u.pgm', i));
end

clear i inds;

%-----------------------------------------------------------------------------------------------------------------------

fprintf('CREATING S2 FEATURE DICTIONARY BY SAMPLING FROM TRAINING IMAGES\n');

factor = 3.5;  % The training images are quite small and this model was designed for larger images.  The easiest way
               % to apply it to this task was to just scale up the images.  Yes, this isn't particularly efficient.

p = struct;
p.bufSize   = [40 100];           % Size of raw image buffer.
p.baseSize  = [40 100] * factor;  % Size of the base of the image scale pyramid.
p.numScales = 9;                  % Number of scales in the image scale pyramid.
p.baseScale = 1;
[p, g] = hmax_cvpr06_params_full(p);
p.groups{g.s1_orig}.zero = 0;

lib = struct;

m = hmax.Model(p, lib);
cns('init', m);

count = min(numel(trainPaths), totalSamples);

d = hmax_s.EmptyDict(m, m.s2, totalSamples);

for i = 1 : count

    numSamples = floor(totalSamples / count);
    if i <= mod(totalSamples, count), numSamples = numSamples + 1; end

    fprintf('%u/%u: sampling %u feature(s) from %s\n', i, count, numSamples, trainPaths{i});

    hmax.LoadImage(m, trainPaths{i});
    cns('run');

    d = hmax_s.SampleFeatures(m, m.s2, d, numSamples);

end

cns('done');

d = hmax_s.SortFeatures(d);

if cns_istype(m, -m.s2, 'ss')
    d = hmax_ss.SparsifyDict(d);
end

lib.groups{m.s2} = d;

clear factor count d i numSamples;

%-----------------------------------------------------------------------------------------------------------------------

fprintf('COMPUTING C2 VECTORS FOR TRAINING IMAGES\n');

m = hmax.Model(p, lib);
cns('init', m);

trainVectors = zeros(totalSamples, numel(trainPaths), 'single');

for i = 1 : numel(trainPaths)

    fprintf('%i/%i: computing C2 vector for %s\n', i, numel(trainPaths), trainPaths{i});

    hmax.LoadImage(m, trainPaths{i});
    cns('run');

    c2 = cns('get', -m.c2, 'val');
    c2 = cat(1, c2{:});

    trainVectors(:, i) = c2;

end

cns('done');

clear i c2;

%-----------------------------------------------------------------------------------------------------------------------

if rounds > 0

    fprintf('SELECTING FEATURES\n');

    % Find the best features.
    dims = hmax_linclass_select(trainVectors, trainCats, rounds);

    % Keep only those features.
    lib.groups{m.s2} = hmax_s.SelectFeatures(lib.groups{m.s2}, dims);
    trainVectors = trainVectors(dims, :);

end

fprintf('BUILDING CLASSIFIER\n');

% Build the final classifier.
classifier = hmax_linclass_train(trainVectors, trainCats);

clear dims;

%-----------------------------------------------------------------------------------------------------------------------

fprintf('GENERATING SINGLE-SCALE DETECTION MAPS\n');

factor = 3.5;

p = struct;
p.bufSize   = [199 360];
p.baseSize  = round([199 360] * factor);
p.numScales = 9;
p.baseScale = 1;
[p, g] = hmax_cvpr06_params_full(p);
p.groups{g.s1_orig}.zero = 0;

p.groups{g.c2}.sCount  = inf;              % Here we do not slide the window over scales.
p.groups{g.c2}.yCount  = factor * 40;      % Size of the sliding window (in base-level image coordinates).
p.groups{g.c2}.xCount  = factor * 100;
p.groups{g.c2}.sStep   = 1;
p.groups{g.c2}.yStep   = factor * 2;       % Step size of the sliding window.
p.groups{g.c2}.xStep   = factor * 5;
p.groups{g.c2}.yMargin = factor * 2 * -4;  % The sliding window can go a little off the edge.
p.groups{g.c2}.xMargin = factor * 5 * -4;

nsa.factor = factor;
nsa.yHood  = factor * 40;  % Size of the suppression neighborhood (in base-level image coordinates).
nsa.xHood  = factor * 55;

m = hmax.Model(p, lib);
cns('init', m);

imSizes = zeros(numel(ssTestPaths), 2);
maps    = cell(1, numel(ssTestPaths));

for i = 1 : numel(ssTestPaths)

    fprintf('%u/%u: generating detection map for %s\n', i, numel(ssTestPaths), ssTestPaths{i});

    im = imread(ssTestPaths{i});
    imSizes(i, :) = size(im);

    hmax.LoadImage(m, im, 'center', factor);
    cns('run');

    c2 = cns('get', -m.c2, 'val');
    c2 = cat(1, c2{:});

    [ans, map] = hmax_linclass_test(classifier, c2);
    maps{i}{1} = shiftdim(map, 1);

end

cns('done');

fprintf('COMPUTING SINGLE-SCALE PRECISION-RECALL CURVE\n');

fprintf('thres: recall precis f-meas\n');

best = 0;

for thres = -0.8 : 0.1 : 0.8

    nsa.thres = thres;

    locs = cell(1, numel(ssTestPaths));
    for i = 1 : numel(ssTestPaths)
        locs{i} = hmax_uiuc_nsa(m, m.c2, imSizes(i, :), maps{i}, nsa);
    end
    
    s = hmax_uiuc_score(dataPath, true, locs);

    fprintf('%5.2f: %6.2f %6.2f %6.2f\n', thres, s.recall, s.precision, s.fMeasure);

    if best <= mean([s.recall, s.precision])
        best = mean([s.recall, s.precision]);
        ssLocs = locs;
    end

end

clear factor nsa imSizes maps i im c2 ans map best thres locs s;

%-----------------------------------------------------------------------------------------------------------------------

fprintf('GENERATING MULTI-SCALE DETECTION MAPS\n');

factor = 3.5;

p = struct;
p.bufSize   = [240 434];
p.baseSize  = round([240 434] * factor);
p.numScales = 18;                          % This time we compute extra scales so we can slide the window over scale.
p.baseScale = 2;                           % Including going one scale finer than the baseSize above.
[p, g] = hmax_cvpr06_params_full(p);
p.groups{g.s1_orig}.zero = 0;

p.groups{g.c2}.sCount  = 9;                % Depth of the sliding window.
p.groups{g.c2}.yCount  = factor * 40;
p.groups{g.c2}.xCount  = factor * 100;
p.groups{g.c2}.sStep   = 1;                % Step size (in scale) of the sliding window.
p.groups{g.c2}.yStep   = factor * 2;
p.groups{g.c2}.xStep   = factor * 5;
p.groups{g.c2}.yMargin = factor * 2 * -2;
p.groups{g.c2}.xMargin = factor * 5 * -2;

nsa.factor = factor;
nsa.yHood  = factor * 40;
nsa.xHood  = factor * 55;

m = hmax.Model(p, lib);
cns('init', m);

imSizes = zeros(numel(msTestPaths), 2);
maps    = cell(1, numel(msTestPaths));

for i = 1 : numel(msTestPaths)

    fprintf('%u/%u: generating detection map for %s\n', i, numel(msTestPaths), msTestPaths{i});

    im = imread(msTestPaths{i});
    imSizes(i, :) = size(im);

    hmax.LoadImage(m, im, 'center', factor);
    cns('run');

    c2 = cns('get', -m.c2, 'val');

    for j = 1 : numel(c2)

        [ans, map] = hmax_linclass_test(classifier, c2{j});
        maps{i}{j} = shiftdim(map, 1);

    end

end

cns('done');

fprintf('COMPUTING MULTI-SCALE PRECISION-RECALL CURVE\n');

fprintf('thres: recall precis f-meas\n');

best = 0;

for thres = -0.8 : 0.1 : 0.8

    nsa.thres = thres;

    locs = cell(1, numel(msTestPaths));
    for i = 1 : numel(msTestPaths)
        locs{i} = hmax_uiuc_nsa(m, m.c2, imSizes(i, :), maps{i}, nsa);
    end
    
    s = hmax_uiuc_score(dataPath, false, locs);

    fprintf('%5.2f: %6.2f %6.2f %6.2f\n', thres, s.recall, s.precision, s.fMeasure);

    if best <= mean([s.recall, s.precision])
        best = mean([s.recall, s.precision]);
        msLocs = locs;
    end

end

clear factor nsa imSizes maps i im c2 j ans map best thres locs s;

%-----------------------------------------------------------------------------------------------------------------------

fprintf('DISPLAYING SINGLE-SCALE DETECTIONS\n');

for i = 1 : numel(ssTestPaths)
    hmax_uiuc_show(ssTestPaths{i}, ssLocs{i});
    ans = input(sprintf('%u/%u: press enter for next or enter "s" to stop: ', i, numel(ssTestPaths)), 's');
    if strcmpi(ans, 's'), break; end
end

fprintf('DISPLAYING MULTI-SCALE DETECTIONS\n');

for i = 1 : numel(msTestPaths)
    hmax_uiuc_show(msTestPaths{i}, msLocs{i});
    ans = input(sprintf('%u/%u: press enter for next or enter "s" to stop: ', i, numel(msTestPaths)), 's');
    if strcmpi(ans, 's'), break; end
end

clear i ans p g m;
