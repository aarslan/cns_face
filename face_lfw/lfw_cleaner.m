function catNames = lfw_cleaner(dataPath, setSize)

dirs = dir(dataPath);
catNames = {dirs([dirs.isdir]).name};
catNames = setdiff(catNames, {'.', '..'});
[ans, inds] = sort(lower(catNames));
catNames = catNames(inds);
removeThese={};

for thisDir = catNames 
    contents = dir([dataPath '/' thisDir{:}]); 
    contents = ~[contents(:).isdir];
    if sum(contents) < setSize
     removeThese = [removeThese thisDir];
    end
    
end
catNames = setdiff(catNames, removeThese);
end