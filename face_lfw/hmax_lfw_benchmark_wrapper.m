parameters = 'cvpr';

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
fclose('all');

     totalSet    = [ sameSetA ; sameSetB ; diffSet1 ; diffSet2];
     uniqTotalSet = unique([totalSet{:}]);
%     
 c2s = hmax_cvpr06_run_lfw_benchmark(uniqTotalSet, parameters);

%trainSameNorms = zeros(300,10);
%trainDiffNorms = zeros(300,10);
trainSameAbsDif_C1 = zeros(300, size(c1s,1), 10);
trainDiffAbsDif_C1 = zeros(300, size(c1s,1), 10);

trainSameAbsDif_C2 = zeros(300, size(c2s,1), 10);
trainDiffAbsDif_C2 = zeros(300, size(c2s,1), 10);

for splitNo =1:10
    for p=1:numel(sameSetA{splitNo})
        indA = strcmp(sameSetA{splitNo}{p}, uniqTotalSet);
        indB = strcmp(sameSetB{splitNo}{p}, uniqTotalSet);
        trainSameNorms_C1(p,splitNo) = norm([c1s(:,indA), c1s(:,indB)]);
        trainSameAbsDif_C1(p,:,splitNo) = abs(c1s(:,indA) - c1s(:,indB));
        
        trainSameAbsDif_C2(p,:,splitNo) = abs(c2s(:,indA) - c2s(:,indB));
    end
    
    for p=1:numel(diffSet1{splitNo})
        indA = strcmp(diffSet1{splitNo}{p}, uniqTotalSet);
        indB = strcmp(diffSet2{splitNo}{p}, uniqTotalSet);
        trainDiffNorms_C1(p,splitNo) = norm([c1s(:,indA), c1s(:,indB)]);  
        trainDiffAbsDif_C1(p,:,splitNo) = abs(c1s(:,indA) - c1s(:,indB));
        
        trainDiffAbsDif_C2(p,:,splitNo) = abs(c2s(:,indA) - c2s(:,indB));
    end    
end

%leave one out section
allSplits = [1:10];
auc_C1 = zeros(numel(allSplits),1);
auc_C2 = zeros(numel(allSplits),1);

for thisSplit=allSplits
    
    trainSplitInd = setdiff(allSplits, thisSplit);
    trainSplitInd = [2 3];
    %TRAIN prepare positive features
    offset = 0;
    trainPosFeats_C1 = zeros(numel(trainSplitInd)*300, size(c1s,1));
    trainPosFeats_C2 = zeros(numel(trainSplitInd)*300, size(c2s,1));
    
    for jj=trainSplitInd
        trainPosFeats_C1(1+offset:300+offset,:) = trainSameAbsDif_C1(:,:,jj);
        trainPosFeats_C2(1+offset:300+offset,:) = trainSameAbsDif_C2(:,:,jj);
        offset = offset+300;
    end
    
    %TRAIN prepare Negative features
    offset = 0;
    trainNegFeats_C1 = zeros(numel(trainSplitInd)*300, size(c1s,1));
    trainNegFeats_C2 = zeros(numel(trainSplitInd)*300, size(c2s,1));
    
    for jj=trainSplitInd
        trainNegFeats_C1(1+offset:300+offset,:) = trainDiffAbsDif_C1(:,:,jj);
        trainNegFeats_C2(1+offset:300+offset,:) = trainDiffAbsDif_C2(:,:,jj);
        offset = offset+300;
    end    
    
    trainFeats_C1 = [trainPosFeats_C1; trainNegFeats_C1];
    trainFeats_C2 = [trainPosFeats_C2; trainNegFeats_C2];
    
    %TRAIN labels
    trainLabels = [ones(numel(trainSplitInd)*300,1); zeros(numel(trainSplitInd)*300,1)];
    
    %TEST prepare positive features & labels
    testPosFeats_C1 = trainSameAbsDif_C1(:,:,thisSplit);
    testPosFeats_C2 = trainSameAbsDif_C2(:,:,thisSplit);
    
    %TEST prepare negative features & labels
    testNegFeats_C1 = trainDiffAbsDif_C1(:,:,thisSplit);
    testNegFeats_C2 = trainDiffAbsDif_C2(:,:,thisSplit);
    
    testLabels = [ones(300,1); zeros(300,1)];
    
     
    testFeats_C1 = [testPosFeats_C1; testNegFeats_C1];
    testFeats_C2 = [testPosFeats_C2; testNegFeats_C2];
    
    testPosFeats_C1 = []; testNegFeats_C1 = []; trainPosFeats_C1 = []; trainNegFeats_C1 = [];
    testPosFeats_C2 = []; testNegFeats_C2 = []; trainPosFeats_C2 = []; trainNegFeats_C2 = [];
    
    model = svmtrain(trainLabels*2-1, trainFeats_C1);
    figure;
    auc_C1(thisSplit) = plotroc(testLabels*2-1, testFeats_C1, model);
    
    model = svmtrain(trainLabels*2-1, trainFeats_C2);
    figure;
    auc_C2(thisSplit) = plotroc(testLabels*2-1, testFeats_C2, model);
    
end