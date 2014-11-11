%JR_CNN_SCRIPT Script generates photo file names and passes them to jr_cnn
%and saves the returned feature vector

% initialise variables
flowerSetNumber = 5;
numberOfImagesPerFlower = 80;
imageFolder = 'oxfordflower5/';
numTotalImages = flowerSetNumber * numberOfImagesPerFlower;
numTrainingImages = numTotalImages/2;
numTestImages = numTotalImages/2;


% import vector of flower file names
imageName = importdata(strcat(imageFolder,'files.txt'));
imageName = cell2mat(imageName);

% generate vector of image categorisation labels
imageLabels = load(strcat(imageFolder,'labels.mat'));
imageLabels = (cell2mat(struct2cell(imageLabels)));

% for simplified 3 flower case only:
if flowerSetNumber == 5
    imageLabels = imageLabels(1:numTotalImages);
end


% generate vectors containing the indeces of training and testing data
trainingIndexVector = ones(1, numTrainingImages);
testIndexVector = ones(1, numTestImages);
trainingCount = 0;
testCount = 0;
flag = 1;
for i = 1:numTotalImages %size(imageLabels, 2)
   
   if flag == 1 
       trainingCount = trainingCount + 1;
       trainingIndexVector(trainingCount) = i;
   end
   
   if flag == -1 
       testCount = testCount + 1;
       testIndexVector(testCount) = i;
   end
   
   if mod(i, 40) == 0
       flag = flag * -1;
   end
   
end



% load / generate trainingInstanceMatrix storing training flower feature data
if exist(strcat(imageFolder,'trainingInstanceMatrix.mat'))
    trainingInstanceMatrix = load(strcat(imageFolder,'trainingInstanceMatrix.mat'));
    trainingInstanceMatrix = (cell2mat(struct2cell(trainingInstanceMatrix)));
else
    trainingInstanceMatrix = jr_cnn_genTrainingMatrix(imageName, imageFolder, trainingIndexVector);
end

% load / generate testInstanceMatrix storing test flower feature data
if  exist(strcat(imageFolder,'testInstanceMatrix.mat'))
    testInstanceMatrix = load(strcat(imageFolder,'testInstanceMatrix.mat'));
    testInstanceMatrix = (cell2mat(struct2cell(testInstanceMatrix)));
else
    testInstanceMatrix = ones(size(trainingIndexVector, 2), 4096);
    testImageFolder = strcat(imageFolder, 'jpg/');
    for i = 1 : size(trainingIndexVector, 2)
        testInstanceMatrix(i, :) = jr_cnn(imageName(testIndexVector(i), :), testImageFolder);
    end
    save(strcat(imageFolder,'testInstanceMatrix.mat'), 'testInstanceMatrix')
end



% train and test models 
if 0
    [predictLabels, accuracies, decValues] = jr_svm(flowerSetNumber, numTestImages, trainingInstanceMatrix, testInstanceMatrix);
end

% measure quality of results 
confusionMatrix = jr_confMatrix(decValues);
contingencyTable = jr_contingencyTable(flowerSetNumber, decValues);

% plot DOC curves
rocMatrix = jr_rocCurve(decValues);

plot(rocMatrix(2, :), rocMatrix(1, :), 'y', rocMatrix(4, :), rocMatrix(3, :), 'r', rocMatrix(6, :), rocMatrix(5, :), 'g', rocMatrix(8, :), rocMatrix(7, :), 'c', rocMatrix(10, :), rocMatrix(9, :), 'b');
legend('1', '2', '3', '4', '5', 'location', 'SouthEast')
%axis([0 1 0 1])




