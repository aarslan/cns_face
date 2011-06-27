function result = mkl_multiclass_ALI(train_x, train_y, test_x, test_y)

C = 0.5;         % SVM Parameter
size_cache = 100; % cache per kernel in MB
svm_eps=1e-3;	 % svm epsilon
mkl_eps=1e-3;	 % mkl epsilon

rbf_width = [0.01 0.1 1 10 100];     % different width for the five used rbf kernels


mkl_norm = 1; % >=1

  % train MKL

  sg('clean_kernel');
  sg('clean_features', 'TRAIN');
  
  
  %sg('set_constraint_generator', 'LIBSVM');
  sg('svm_epsilon', svm_eps);
  sg('set_kernel', 'COMBINED', 0);
%   sg('add_kernel', 1, 'GAUSSIAN', 'REAL', cache_size, rbf_width(1));
%   sg('add_kernel', 1, 'GAUSSIAN', 'REAL', cache_size, rbf_width(2));
%   sg('add_kernel', 1, 'GAUSSIAN', 'REAL', cache_size, rbf_width(1));
%   sg('add_kernel', 1, 'GAUSSIAN', 'REAL', cache_size, rbf_width(2));
  sg('add_kernel', 1, 'LINEAR', 'REAL', size_cache);
  sg('add_kernel', 1, 'LINEAR', 'REAL', size_cache);
  sg('c', C);
  
  
  sg('add_features','TRAIN', train_x{1});       % set a trainingset for every SVM
  sg('add_features','TRAIN', train_x{2});
  
  sg('set_labels','TRAIN', train_y);         % set the labels
  sg('new_classifier', 'MKL_CLASSIFICATION');
  sg('mkl_use_interleaved_optimization', 1); % 0, 1

  % use standard (p-norm) MKL
  sg('set_solver', 'DIRECT'); % DIRECT, BLOCK_NORM, NEWTON, CPLEX, AUTO, GLPK, ELASTICNET
  sg('mkl_parameters', mkl_eps, 0, mkl_norm);

  % elastic net MKL
  %sg('set_solver', 'ELASTICNET');
  %sg('elasticnet_lambda',ent_lambda);

  % mixed norm MKL
  %sg('set_solver', 'BLOCK_NORM');
  %sg('mkl_block_norm', mkl_block_norm);

  sg('train_classifier');
  [b,alphas]=sg('get_svm') ;
  result.b = b;
  result.alpha = alphas;
  result.w = sg('get_subkernel_weights');

  % calculate train error

  sg('clean_features', 'TEST');
  sg('add_features','TEST',train_x{1});
  %sg('add_features','TEST',train_x{1});
  sg('add_features','TEST',train_x{2});
  %sg('add_features','TEST',train_x{2});
  sg('set_labels','TEST', train_y);
  sg('set_threshold', 0);
  result.trainout = sg('classify');
  result.trainerr  = mean(train_y~=sign(result.trainout),2);  

  % calculate test error

  sg('clean_features', 'TEST');
  sg('add_features','TEST',test_x{1});
  %sg('add_features','TEST',test_x{1});
  sg('add_features','TEST',test_x{2});
  %sg('add_features','TEST',test_x{2});
  sg('set_labels','TEST',test_y);
  sg('set_threshold', 0);
  result.testout=sg('classify');
  result.testerr  = mean(test_y ~= sign(result.testout),2);    
	 
disp('done. now w contains the kernel weightings and result test/train outputs and errors')
