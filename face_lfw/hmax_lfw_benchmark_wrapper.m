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
%     
% c2s = hmax_cvpr06_run_lfw_benchmark(uniqTotalSet);

trainSameNorms = zeros(300,10);
trainDiffNorms = zeros(300,10);
trainSameAbsDif = zeros(300, size(c1s,1), 10);
trainDiffAbsDif = zeros(300, size(c1s,1), 10);

for splitNo =1:10
    for p=1:numel(sameSetA{splitNo})
        indA = strcmp(sameSetA{splitNo}{p}, uniqTotalSet);
        indB = strcmp(sameSetB{splitNo}{p}, uniqTotalSet);
        trainSameNorms(p,splitNo) = norm([c1s(:,indA), c1s(:,indB)]);
        trainSameAbsDif(p,:,splitNo) = abs(c1s(:,indA)- c1s(:,indB));
    end
    
    for p=1:numel(diffSet1{splitNo})
        indA = strcmp(diffSet1{splitNo}{p}, uniqTotalSet);
        indB = strcmp(diffSet2{splitNo}{p}, uniqTotalSet);
        trainDiffNorms(p,splitNo) = norm([c1s(:,indA), c1s(:,indB)]);  
        trainDiffAbsDif(p,:,splitNo) = abs(c1s(:,indA) - c1s(:,indB));
    end    
end

%leave one out section
allSplits = [1:10];

for thisSplit=allSplits
    
    trainSplitInd = setdiff(allSplits, thisSplit);
    %TRAIN prepare positive features
    offset = 0;
    trainPosFeats = zeros(2700, 19200);
    for jj=trainSplitInd
        trainPosFeats(1+offset:300+offset,:) = trainSameAbsDif(:,:,jj);
        offset = offset+300;
    end
    
    %TRAIN prepare positive features
    offset = 0;
    trainNegFeats = zeros(2700, 19200);
    
    for jj=trainSplitInd
        trainNegFeats(1+offset:300+offset,:) = trainDiffAbsDif(:,:,jj);
        offset = offset+300;
    end    
    
    trainFeats = [trainPosFeats; trainNegFeats];
    
    %TRAIN labels
    trainLabels = [ones(2700,1); zeros(2700,1)];
    
    %TEST prepare positive features & labels
    testPosFeats = trainSameAbsDif(:,:,thisSplit);
    
    %TEST prepare negative features & labels
    testNegFeats = trainSameAbsDif(:,:,thisSplit);
    testLabels = [ones(300,1); zeros(300,1)];
    
    testFeats = [testPosFeats; testNegFeats];
    model = svmtrain(trainFeats, trainLabels); %model = train( trainLabels, sparse(trainFeats));
end





