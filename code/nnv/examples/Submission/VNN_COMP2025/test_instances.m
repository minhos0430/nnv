vnncomp_path = "C:\Users\diego\Documents\Research\vnncomp2025_benchmarks\benchmarks\";

% Things look better than last year, let's make sure we have no penalties this time
% Can we support any other benchmarks? what are the errors we are getting
% in some of them?


%% acasxu

disp("Running acas xu...")

acas_path = vnncomp_path + "acasxu_2023/";

acas_instances = [...
    "onnx/ACASXU_run2a_1_1_batch_2000.onnx" , "vnnlib/prop_1.vnnlib";...
    "onnx/ACASXU_run2a_2_3_batch_2000.onnx","vnnlib/prop_2.vnnlib";...
    "onnx/ACASXU_run2a_3_4_batch_2000.onnx","vnnlib/prop_3.vnnlib";...
    "onnx/ACASXU_run2a_2_5_batch_2000.onnx","vnnlib/prop_4.vnnlib";...
    "onnx/ACASXU_run2a_1_1_batch_2000.onnx","vnnlib/prop_5.vnnlib";...
    "onnx/ACASXU_run2a_1_1_batch_2000.onnx","vnnlib/prop_6.vnnlib";...
    "onnx/ACASXU_run2a_1_9_batch_2000.onnx","vnnlib/prop_7.vnnlib";...
    "onnx/ACASXU_run2a_2_9_batch_2000.onnx","vnnlib/prop_8.vnnlib";...
    "onnx/ACASXU_run2a_3_3_batch_2000.onnx","vnnlib/prop_9.vnnlib";...
    "onnx/ACASXU_run2a_4_5_batch_2000.onnx","vnnlib/prop_10.vnnlib";...
    ];

% Run verification for acas 
for i=1:length(acas_instances)
    onnx = acas_path + acas_instances(i,1);
    vnnlib = acas_path + acas_instances(i,2);
    try
        run_vnncomp_instance("acasxu",onnx,vnnlib,"acas_results_" + string(i)+".txt");
    catch ME
        warning("Failed")
        disp(onnx+"___"+vnnlib)
        warning(ME.message)
    end

end


% No errors

%% cgan

disp("Running cgan..")

cgan_path = vnncomp_path + "cgan_2023/";

cgan_instances = ["onnx/cGAN_imgSz32_nCh_1.onnx", "vnnlib/cGAN_imgSz32_nCh_1_prop_0_input_eps_0.010_output_eps_0.015.vnnlib";...
    "onnx/cGAN_imgSz32_nCh_3.onnx", "vnnlib/cGAN_imgSz32_nCh_3_prop_0_input_eps_0.010_output_eps_0.015.vnnlib";...
    "onnx/cGAN_imgSz32_nCh_3_nonlinear_activations.onnx", "vnnlib/cGAN_imgSz32_nCh_3_nonlinear_activations_prop_0_input_eps_0.015_output_eps_0.020.vnnlib";... 
    "onnx/cGAN_imgSz32_nCh_1_transposedConvPadding_1.onnx", "vnnlib/cGAN_imgSz32_nCh_1_transposedConvPadding_1_prop_0_input_eps_0.015_output_eps_0.020.vnnlib";...
    "onnx/cGAN_imgSz32_nCh_3_upsample.onnx", "vnnlib/cGAN_imgSz32_nCh_3_upsample_prop_0_input_eps_0.015_output_eps_0.020.vnnlib";... 
    "onnx/cGAN_imgSz32_nCh_3_small_transformer.onnx", "vnnlib/cGAN_imgSz32_nCh_3_small_transformer_prop_0_input_eps_0.010_output_eps_0.015.vnnlib";... 
];

% Run verification for cgan
for i=1:length(cgan_instances)
    onnx = cgan_path + cgan_instances(i,1);
    vnnlib = cgan_path + cgan_instances(i,2);
    try
        run_vnncomp_instance("cgan",onnx,vnnlib,"cgan_results_" + string(i)+".txt");
    catch ME
        warning("Failed")
        disp(onnx+"___"+vnnlib)
        warning(ME.message)
    end
end

% All good apparently, can even verify some as seen on submission site


%% collins_rul

disp("Running collins_rul..")

rul_path = vnncomp_path + "collins_rul_cnn_2022/";

rul_instances = ["onnx/NN_rul_small_window_20.onnx" ,"vnnlib/robustness_2perturbations_delta5_epsilon10_w20.vnnlib";...
    "onnx/NN_rul_small_window_20.onnx" ,"vnnlib/monotonicity_CI_shift5_w20.vnnlib";...
    "onnx/NN_rul_small_window_20.onnx" ,"vnnlib/if_then_5levels_w20.vnnlib";...
    "onnx/NN_rul_full_window_20.onnx", "vnnlib/robustness_2perturbations_delta5_epsilon10_w20.vnnlib";...
    "onnx/NN_rul_full_window_40.onnx" ,"vnnlib/robustness_2perturbations_delta5_epsilon10_w40.vnnlib"];

% Run verification for collins_rul
for i=1:length(rul_instances)
    onnx = rul_path + rul_instances(i,1);
    vnnlib = rul_path + rul_instances(i,2);
    try
        run_vnncomp_instance("collins_rul",onnx,vnnlib,"collins_rul_results_" + string(i)+".txt");
    catch ME
        warning("Failed")
        disp(onnx+"___"+vnnlib)
        warning(ME.message)
    end
end


%% tllverify

disp("Running tllverify..")

tll_path = vnncomp_path + "tllverifybench_2023/";

tll_instances = ["onnx/tllBench_n=2_N=M=8_m=1_instance_0_0.onnx","vnnlib/property_N=8_0.vnnlib";...
    "onnx/tllBench_n=2_N=M=16_m=1_instance_1_0.onnx","vnnlib/property_N=16_0.vnnlib";...
    "onnx/tllBench_n=2_N=M=24_m=1_instance_2_2.onnx","vnnlib/property_N=24_2.vnnlib";...
    "onnx/tllBench_n=2_N=M=32_m=1_instance_3_0.onnx","vnnlib/property_N=32_0.vnnlib";...
    "onnx/tllBench_n=2_N=M=48_m=1_instance_5_3.onnx","vnnlib/property_N=48_3.vnnlib";...
    "onnx/tllBench_n=2_N=M=56_m=1_instance_6_0.onnx","vnnlib/property_N=56_0.vnnlib";...
    % "onnx/tllBench_n=2_N=M=64_m=1_instance_7_0.onnx","vnnlib/property_N=64_0.vnnlib";...
    ]; % last one not finishing after a loooong time

% Run verification for tllverify
for i=1:length(tll_instances)
    onnx = tll_path + tll_instances(i,1);
    vnnlib = tll_path + tll_instances(i,2);
    try
        run_vnncomp_instance("tllverifybench",onnx,vnnlib,"tllverify_results_" + string(i)+".txt");
    catch ME
        warning("Failed")
        disp(onnx+"___"+vnnlib)
        warning(ME.message)
    end
end

%% vit

disp("Running vit...")

vit_path = vnncomp_path + "vit_2023/";

vit_instances = ["onnx/pgd_2_3_16.onnx", "vnnlib/pgd_2_3_16_8835.vnnlib";...
    "onnx/ibp_3_3_8.onnx", "vnnlib/ibp_3_3_8_4868.vnnlib";...
    ]; 

% Run verification for vit
for i=1:length(vit_instances)
    onnx = vit_path + vit_instances(i,1);
    vnnlib = vit_path + vit_instances(i,2);
    try
        run_vnncomp_instance("vit_2023",onnx,vnnlib,"vit_results_" + string(i)+".txt");
    catch ME
        warning("Failed")
        disp(onnx+"___"+vnnlib)
        warning(ME.message)
    end
end
