% A demo script that instantiates one of the [Mutch & Lowe 2006] models, learns
% a feature dictionary, and computes feature vectors.
%
% Note that this is only a toy script that runs the model on a few images in
% order to illustrate command usage.  See hmax_cvpr06_run_cal101 for a script
% that performs a real task.
%
% See also: hmax_cvpr06_run_cal101, hmax_cvpr06_run_uiuc.

%-----------------------------------------------------------------------------------------------------------------------
% Define the model.
%-----------------------------------------------------------------------------------------------------------------------

% Choose model parameters.
p = hmax_cvpr06_params_base;
% p = hmax_cvpr06_params_full;

% A "library" contains the feature dictionary for each stage, if any.  In [Mutch & Lowe 2006] only S2 will have a
% feature dictionary, but it does not yet exist.
lib = struct;

demoPath = fileparts(mfilename('fullpath'));

%-----------------------------------------------------------------------------------------------------------------------
% Learn a feature dictionary for S2.
%-----------------------------------------------------------------------------------------------------------------------

n = 2048;

% Build the full CNS model structure.  Note that stages after C1 will have zero cells because the S2 dictionary
% is empty.
m = hmax.Model(p, lib);

% Create an empty dictionary for S2.
d = hmax_s.EmptyDict(m, m.s2, n);

% Initialize the model on the GPU.
cns('init', m, 'gpu');
% cns('init', m, 'cpu'); % use this instead if you don't have a GPU

for i = 1 : 1

    % Note: in a real situation we would loop over many training images.
    fn = 'image_0010.jpg';
    im = imread(fullfile(demoPath, fn));

    % Load training image into the GPU.
    hmax.LoadImage(m, im);

    % Compute the feature hierarchy for the image.
    cns('run');

    % Sample some S2 features (patches of C1 units).  Note we're sampling many features from a single image; in a
    % real situation we'd sample only a few from each training image.
    d = hmax_s.SampleFeatures(m, m.s2, d, n);

    fprintf('sampled %u "s2" features from "%s"\n', n, fn);

end

% Release GPU resources.
cns('done');

% Sort features by size.  This increases the speed of models that use the dictionary.
d = hmax_s.SortFeatures(d);

if cns_istype(m, -m.s2, 'ss')
    % Convert the features to "sparse" features.
    d = hmax_ss.SparsifyDict(d);
end

% Store the new dictionary in the library.
lib.groups{m.s2} = d;

clear d i n fn im;

%-----------------------------------------------------------------------------------------------------------------------
% Compute feature vectors for images.
%-----------------------------------------------------------------------------------------------------------------------

% Build the full CNS model structure.  This time there will be cells above C1 because there is an S2 dictionary.
m = hmax.Model(p, lib);

% Initialize the model on the GPU.
cns('init', m, 'gpu');
% cns('init', m, 'cpu'); % use this instead if you don't have a GPU

for i = 1 : 1

    % Note: in a real situation we would loop over many images.
    fn = 'image_0002.jpg';
    im = imread(fullfile(demoPath, fn));
    time = tic;

    % Load image into the GPU.
    hmax.LoadImage(m, im);

    % Compute the feature hierarchy for the image.
    cns('run');

    % Retrieve the contents of C2.
    c2 = cns('get', -m.c2, 'val');
    c2 = cat(1, c2{:});
    c2(c2 == cns_fltmin) = 0; % Convert any "unknown" values to 0.

    time = toc(time);
    fprintf('computed feature vector for "%s" (%f sec)\n', fn, time);

end

% Release GPU resources.
cns('done');

clear i fn im time;