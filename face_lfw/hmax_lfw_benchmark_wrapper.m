for splitNo=1:10

    % test if same person
    fid = fopen([num2str(splitNo) '_same.txt']);
    [person ] = textscan(fid, '%s %s %s');
    
    sameSetA(splitNo)    = {cellfun(@(person,x) [person '_' regexprep(num2str(zeros(4-length(x),1)'), '[^\w'']','') x], person{1,1}, person{1,2},'uni',false)};
    sameSetB(splitNo)    = {cellfun(@(person,x) [person '_' regexprep(num2str(zeros(4-length(x),1)'), '[^\w'']','') x], person{1,1}, person{1,3},'uni',false)};
    
    fid = fopen([num2str(splitNo) '_diff.txt']);
    [person ] = textscan(fid, '%s %s %s %s');    
    diffSet1(splitNo)    = {cellfun(@(person,x) [person '_' regexprep(num2str(zeros(4-length(x),1)'), '[^\w'']','') x], person{1,1}, person{1,2},'uni',false)};
    diffSet2(splitNo)    = {cellfun(@(person,x) [person '_' regexprep(num2str(zeros(4-length(x),1)'), '[^\w'']','') x], person{1,3}, person{1,4},'uni',false)};


end


    totalSet    = [ sameSetA ; sameSetB ; diffSet1 ; diffSet2];
    uniqTotalSet = unique([totalSet{:}]);
    
c2s = hmax_cvpr06_run_lfw_benchmark(uniqTotalSet);