% hmax_cvpr06_run_cal101 - Demo script that performs multiclass classification.
%
% This script runs hmax against the Caltech 101 dataset using the model
% configuration of [Mutch & Lowe 2006].  With minor modifications it could run
% on any similar dataset.
%
% The script does everything in the paper (for the multiclass problem) except
% the final feature selection step.  (The feature selection step doesn't improve
% the classification score much -- it just reduces the number of features needed
% for the model.)
%
% You will have to copy and edit this script to provide the path of the Caltech
% 101 (or similar) dataset on your system.
%
% You might also want to insert "save" commands at appropriate points in this
% script, as it will take some time to run.
%
% See hmax_cvpr06_run_simple for more comments on individual command usage.
%
% See also: hmax_cvpr06_run_simple, hmax_cvpr06_run_uiuc.

%-----------------------------------------------------------------------------------------------------------------------

% while true
%     ans = lower(strtrim(input('All variables will be cleared.  Is this okay (y/n) ? ', 's')));
%     if isempty(ans), continue; end
%     if ans(1) == 'y', break; end
%     if ans(1) == 'n', return; end
% end    

function hmax_cvpr06_run_lfw

fprintf('\n');

clear;

%-----------------------------------------------------------------------------------------------------------------------

% Edit this section to supply script parameters.
if strcmp(computer, 'MACI64')
dataPath = '/Users/aarslan/Documents/Databases/lfw';                % Path where the Caltech 101 dataset can be found (*** required ***).
else
  dataPath = '/gpfs/data/tserre/data/face_database/lfw';    
end

p = hmax_cvpr06_params_full;  % Model configuration to use.  Note that this script assumes that the only stage having
                              % learned features is called "s2" and that the top stage is called "c2".

numFeatures = 4096;           % Number of S2 features to learn.
numTrain    = 8;             % Number of training images per category.
maxTest     = inf;            % Maximum number of test images per category.
minSetSize  = 15;              % minimum number of images for a person required to include that person in the classification.

%-----------------------------------------------------------------------------------------------------------------------

if isempty(dataPath)
    error('you must edit this script to supply the path of the Caltech 101 dataset (variable "dataPath")');
end

if ~exist(fullfile(dataPath, 'Aaron_Eckhart'), 'dir')
    error('cannot find the faces in the wild dataset at path "%s"', dataPath);
end

%-----------------------------------------------------------------------------------------------------------------------

fprintf('CREATING TRAIN/TEST SPLITS\n');

dirs = dir(dataPath);
catNames = {dirs([dirs.isdir]).name};
catNames = setdiff(catNames, {'.', '..'});
[ans, inds] = sort(lower(catNames));
catNames = catNames(inds);
catNames = lfw_cleaner(dataPath, minSetSize);

trainPaths = cell (1, numTrain * numel(catNames));
trainCats  = zeros(1, numTrain * numel(catNames));
testPaths  = {};
testCats   = [];

for i = 1 : numel(catNames)

    files = dir(fullfile(dataPath, catNames{i}, '*.jpg'));
    if numel(files) <= numTrain, error('not enough images in category "%s"', catNames{i}); end
    paths = cell(1, numel(files));
    for j = 1 : numel(files)
        paths{j} = fullfile(dataPath, catNames{i}, files(j).name);
    end

    inds = randperm(numel(paths));

    for j = 1 : numTrain
        trainPaths{(j-1) * numel(catNames) + i} = paths{inds(j)};
        trainCats ((j-1) * numel(catNames) + i) = i;
    end

    inds = inds(numTrain + 1 : end);
    if maxTest < numel(inds), inds = inds(1 : maxTest); end
    inds = sort(inds);

    for j = 1 : numel(inds)
        testPaths{end + 1} = paths{inds(j)};
        testCats (end + 1) = i;
    end

end

clear dirs ans inds i files paths j;

%-----------------------------------------------------------------------------------------------------------------------

fprintf('CREATING S2 FEATURE DICTIONARY BY SAMPLING FROM TRAINING IMAGES\n');

lib = struct;

m = hmax.Model(p, lib);
cns('init', m);

count = min(numel(trainPaths), numFeatures);

d = hmax_s.EmptyDict(m, m.s2, numFeatures);

for i = 1 : count

    numSamples = floor(numFeatures / count);
    if i <= mod(numFeatures, count), numSamples = numSamples + 1; end

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

clear count d i numSamples;

%-----------------------------------------------------------------------------------------------------------------------

fprintf('COMPUTING C2 VECTORS FOR TRAINING IMAGES\n');

m = hmax.Model(p, lib);
cns('init', m);

trainVectors = zeros(0, numel(trainPaths), 'single');
testVectors = zeros(0, numel(trainPaths), 'single');

for i = 1 : numel(trainPaths)

    fprintf('%u/%u: computing C2 vector for %s\n', i, numel(trainPaths), trainPaths{i});

    hmax.LoadImage(m, trainPaths{i});
    cns('run');

    c2 = cns('get', -m.c2, 'val');
    c2 = cat(1, c2{:});
    trainVectors(1 : numel(c2), i) = c2;

end

cns('done');

clear i c2;

%-----------------------------------------------------------------------------------------------------------------------

fprintf('BUILDING CLASSIFIER\n');

class = hmax_linclass_train(trainVectors, trainCats);

%-----------------------------------------------------------------------------------------------------------------------

fprintf('CLASSIFYING TEST IMAGES\n');

m = hmax.Model(p, lib);
cns('init', m);

predCats = zeros(1, numel(testPaths));

for i = 1 : numel(testPaths)

    hmax.LoadImage(m, testPaths{i});
    cns('run');

    c2 = cns('get', -m.c2, 'val');
    c2 = cat(1, c2{:});
    testVectors(1 : numel(c2), i) = c2;%%%%%
    predCats(i) = hmax_linclass_test(class, c2);
    
    if predCats(i) == testCats(i)
        fprintf('%u/%u: %s (correct)\n', i, numel(testPaths), testPaths{i});
    else
        fprintf('%u/%u: %s (incorrect: %s)\n', i, numel(testPaths), testPaths{i}, catNames{predCats(i)});
    end

end

cns('done');

clear i c2;

%-----------------------------------------------------------------------------------------------------------------------

fprintf('COMPUTING CLASSIFICATION SCORE\n');

scores = zeros(1, numel(catNames));

for i = 1 : numel(catNames)

    scores(i) = sum(predCats(testCats == i) == i) / sum(testCats == i) * 100;

end

fprintf('average score = %f\n', mean(scores));

clear i;

end
