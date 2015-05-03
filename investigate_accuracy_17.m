% FLOWER_RECOGNITION_SCRIPT 17
% Check mirroring code - looking for ~3%

% TODO tidy up use_mirror + use_jitter. cnn_options struct could be used.

% User specifies whether to use mirroring and jittering (use = 1,
% don't use = 0)
cnn_options.train_mirror = 1;
cnn_options.train_jitter = 1;
cnn_options.test_mirror = 0;
cnn_options.test_jitter = 0;

% initialise variables
flower_set_number = 17;
image_folder = 'oxfordflower17/';

% import vector of flower file names
image_name = importdata(fullfile(image_folder,'files.txt'));
image_name = cell2mat(image_name);

% generate vector of image categorisation labels
image_labels = load(fullfile(image_folder,'labels.mat'));
image_labels = (cell2mat(struct2cell(image_labels)));

% generate setid
[setid] = gen_setid(flower_set_number, size(image_labels, 2));



% perform CNN on flower images
[train_instance_matrix, test_instance_matrix, train_label_vector, ...
    test_label_vector] = investigate_accuracy_cnn(image_name, ...
    image_folder, image_labels, cnn_options, setid);


% train SVM models
[weight_matrix, model_labels] = svm_train( ...
    flower_set_number, train_instance_matrix, train_label_vector);


% test SVM models 
decision_values = ...
    svm_test(flower_set_number, test_instance_matrix, weight_matrix);

% generate confusion matrix
confusion_matrix = gen_conf_mat( ...
    decision_values, test_label_vector);

plot_confusion_matrix(confusion_matrix)


confusion_matrix_accuracy = trace(confusion_matrix) / ...
    flower_set_number;