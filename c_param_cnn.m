function [train_instance_matrix, test_instance_matrix, ...
    train_label_vector, test_label_vector] = c_param_cnn ...
    (image_name, image_folder, image_labels, cnn_options, setid)

net = load('cnn_imagenet-vgg-f.mat') ;  % used in CNN. Taken out of cnn
                                        % function for speed
                                        
                                        
train_mirror = cnn_options.train_mirror;
train_jitter = cnn_options.train_jitter;
test_mirror = cnn_options.test_mirror;
test_jitter = cnn_options.test_jitter;                                       
                                        
trnid = setid.trnid;
valid = setid.valid;
tstid = setid.tstid;
num_images = size(image_name, 1);
num_test_images = size(tstid, 2);
num_train_images = size(trnid, 2) + size(valid, 2);
num_val_images = size(valid, 2);
num_trn_images = size(trnid, 2);


folder = fullfile(image_folder, 'jpg/');


% load / generate the standard instance matrix
if exist(fullfile(image_folder,'instance_matrix_standard.mat'))
    instance_matrix_standard = cell2mat(struct2cell( ...
        load(fullfile(image_folder,'instance_matrix_standard.mat'))));
else
    % Always use zeros instead of ones. Also you want to save space by using
    % singles instead of doubles. E.g. zeros(num_images, 4096, 'single') is the
    % function call I believe.
    instance_matrix_standard = ones(num_images, 4096);

    for i = 1 : num_images
        instance_matrix_standard(i, :) = ...
            cnn(image_name(i, :), folder, net, ...
            0, 0);
    end

    save(fullfile(image_folder,'instance_matrix_standard.mat'),...
        'instance_matrix_standard');
end


% load / generate the mirror instance matrix
if exist(fullfile(image_folder,'instance_matrix_mirror.mat'))
    instance_matrix_mirror = cell2mat(struct2cell( ...
        load(fullfile(image_folder,'instance_matrix_mirror.mat'))));
else
    instance_matrix_mirror = ones(num_images, 4096);

    for i = 1 : num_images
        instance_matrix_mirror(i, :) = ...
            cnn(image_name(i, :), folder, net, ...
            1, 0);
    end

    save(fullfile(image_folder,'instance_matrix_mirror.mat'), ...
        'instance_matrix_mirror');
end


% load / generate the jitter instance matrix
if exist(fullfile(image_folder,'instance_matrix_jitter.mat'))
    instance_matrix_jitter = cell2mat(struct2cell( ...
        load(fullfile(image_folder,'instance_matrix_jitter.mat'))));
else
    instance_matrix_jitter = ones(num_images * 5, 4096);

    for i = 1 : num_images
        instance_matrix_jitter(5*i - 4 : 5*i, :) = ...
            cnn(image_name(i, :), folder, net, ...
            0, 1);
    end

    save(fullfile(image_folder,'instance_matrix_jitter.mat'), ...
        'instance_matrix_jitter');
end

% construct train_instance_matrix

% Why dont you just concatenate the up to 3 matrices? The operation below seems
% slow and error prone....

trainid = sort(cat(2, trnid, valid));
if train_mirror == 1 && train_jitter == 1
    train_instance_matrix = zeros(num_train_images * 7, 4096);
    train_label_vector = zeros(num_train_images * 7, 1);
    for i = 1 : num_train_images
        train_instance_matrix(7*i - 6, :) = instance_matrix_standard(trainid(i), :);
        train_instance_matrix(7*i - 5, :) = instance_matrix_mirror(trainid(i), :);
        train_instance_matrix(7*i-4 : 7*i, :) = instance_matrix_jitter(5*trainid(i)-4 : 5*trainid(i), :);

        train_label_vector(7*i-6 : 7*i) = image_labels(trainid(i));
    end

elseif train_jitter == 1
    train_instance_matrix = zeros(num_train_images * 6, 4096);
    train_label_vector = zeros(num_train_images * 6, 1);
    for i = 1 : num_train_images
        train_instance_matrix(6*i - 5, :) = instance_matrix_standard(trainid(i), :);
        train_instance_matrix(6*i-4 : 6*i, :) = instance_matrix_jitter(5*trainid(i)-4 : 5*trainid(i), :);
        train_label_vector(6*i-5 : 6*i) = image_labels(trainid(i));
    end

elseif train_mirror == 1
    train_instance_matrix = zeros(num_train_images * 2, 4096);
    train_label_vector = zeros(num_train_images * 2, 1);
    for i = 1 : num_train_images
        train_instance_matrix(2*i - 1, :) = instance_matrix_standard(trainid(i), :);
        train_instance_matrix(2*i, :) = instance_matrix_mirror(trainid(i), :);

        train_label_vector(2*i-1 : 2*i) = image_labels(trainid(i));
    end

else
    train_instance_matrix = zeros(num_trn_images, 4096);
    train_label_vector = zeros(num_trn_images, 1);
    for i = 1 : num_trn_images
        train_instance_matrix(i, :) = instance_matrix_standard(trnid(i), :);

        train_label_vector(i) = image_labels(trnid(i));
    end
end


% construct test_instance_matrix

if test_mirror == 1 && test_jitter == 1
   test_instance_matrix = zeros(num_test_images, 4096);
    test_label_vector = zeros(num_test_images, 1);
    for i = 1 : num_test_images
        test_instance_matrix(i, :) = ( ... 
            instance_matrix_standard(tstid(i), :) + ...
            instance_matrix_mirror(tstid(i), :) + ...
        	sum( instance_matrix_jitter(5*tstid(i)-4 : 5*tstid(i), :), 1) ...
            /7);

        test_label_vector(i) = image_labels(tstid(i));
    end

elseif test_jitter == 1
    test_instance_matrix = zeros(num_test_images, 4096);
    test_label_vector = zeros(num_test_images, 1);
    for i = 1 : num_test_images
        test_instance_matrix(i, :) = ( ...
            instance_matrix_standard(tstid(i), :) + ...
            sum(instance_matrix_jitter(5*tstid(i)-4 : 5*tstid(i), :), 1) ...
            /6);
        
        test_label_vector(i) = image_labels(tstid(i));
    end

elseif test_mirror == 1
    test_instance_matrix = zeros(num_test_images, 4096);
    test_label_vector = zeros(num_test_images, 1);
    for i = 1 : num_test_images
        test_instance_matrix(i, :) = ...
            (instance_matrix_standard(tstid(i), :) + ...
            instance_matrix_mirror(tstid(i), :)) / 2;

        test_label_vector(i) = image_labels(tstid(i));
    end

else
    test_instance_matrix = zeros(num_val_images, 4096);
    test_label_vector = zeros(num_val_images, 1);
    for i = 1 : num_val_images
        test_instance_matrix(i, :) = instance_matrix_standard(valid(i), :);

        test_label_vector(i) = image_labels(valid(i));
    end
end



end