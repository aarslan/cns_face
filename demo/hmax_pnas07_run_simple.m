% A demo script that instantiates the [Serre et al. 2007] model, learns feature
% dictionaries for each stage, and computes feature vectors.  Differs from
% hmax_cvpr06_run_simple only in that it learns multiple feature dictionaries;
% see that function for detailed comments.
%
% Note that this is only a toy script that runs the model on a few images in
% order to illustrate command usage.
%
% See also: hmax_cvpr06_run_simple.

%-----------------------------------------------------------------------------------------------------------------------

[p, g] = hmax_pnas07_params;

lib = struct;

demoPath = fileparts(mfilename('fullpath'));

%-----------------------------------------------------------------------------------------------------------------------

gs = [g.s2b, g.s2, g.s3]; % Each of these stages needs a dictionary.
ns = [2048 , 2048, 1024]; % Size of each dictionary.

for i = 1 : numel(gs)

    m = hmax.Model(p, lib);
    d = hmax_s.EmptyDict(m, gs(i), ns(i));
    cns('init', m, 'gpu');
    for j = 1 : 1
        fn = 'image_0010.jpg';
        im = imread(fullfile(demoPath, fn));
        hmax.LoadImage(m, im);
        cns('run');
        d = hmax_s.SampleFeatures(m, gs(i), d, ns(i));
        fprintf('sampled %u "%s" features from "%s"\n', ns(i), m.groups{gs(i)}.name, fn);
    end
    cns('done');
    d = hmax_s.SortFeatures(d);
    if cns_istype(m, -gs(i), 'ss')
        d = hmax_ss.SparsifyDict(d);
    end
    lib.groups{gs(i)} = d;

end

clear gs ns i d j fn im;

%-----------------------------------------------------------------------------------------------------------------------

m = hmax.Model(p, lib);
cns('init', m, 'gpu');
for j = 1 : 1
    fn = 'image_0002.jpg';
    im = imread(fullfile(demoPath, fn));
    time = tic;
    hmax.LoadImage(m, im);
    cns('run');
    c2b = cns('get', -m.c2b, 'val'); c2b = cat(1, c2b{:});
    c3  = cns('get', -m.c3 , 'val'); c3  = cat(1, c3 {:});
    c2b(c2b == cns_fltmin) = 0;
    c3 (c3  == cns_fltmin) = 0;
    time = toc(time);
    fprintf('computed feature vector for "%s" (%f sec)\n', fn, time);
end
cns('done');

clear j fn im time;