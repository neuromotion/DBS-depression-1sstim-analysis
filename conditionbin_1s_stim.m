%%%%%%%% conditionbin_1s_stim %%%%%%%%
%%%%%%%%%%% AA 01/2020 %%%%%%%%%%%%% 
% Input: tables created from epoch script, and preprocessed neural data from 
% preprocessing_stim_SIMNETS.m script, i.e. chXtime matrix, vectors with
% indices for good channels, vector containing Channel Labels

%Output: giant matrix that is trialsXtimeXchannels for input into cSIMS fxn
%Last modified 04/22/2020 AA

%% 
%load info for  tbl containing timestamps and condition info 
tbl_file = uigetfile('*.mat', 'All Files(*.*)','MultiSelect','on');
num_tbls = length(tbl_file); 

%load neural data info 
neuraldatafile = uigetfile('*.mat', 'All Files(*.*)','MultiSelect','on'); %select 
num_files = length(neuraldatafile);

%load data info 
trial_length = 3000; %approx average trial length (3s of data) 
num_channels = 142; %****hard coded change this      
%num_channels = size(good_ch,1); %num of good cchannels 
srate_raw = 2000;
fs = srate_raw; 

if num_files == num_tbls 
    disp('correct # of tbls and neuraldatafiles, proceed')
else 
    disp('incorrect # of tbls and neuraldatafiles, reevaluate life decisions') 
end 

%load one file or multiple 
if num_files == 1 
    %load the one table 
    tbl_forepoch = load(tbl_file); 
    neuraldata_signal = load(neuraldatafile); 
elseif num_files > 1  
    %load all tables 
    tbl_forepoch = cell(num_tbls,1); %initialize cell for tables 
    neuraldata_signal = cell(num_files,1); %initialize cell for neural datasets 
    for i = 1:num_files
        tbl_forepoch{i} = load(tbl_file{i});
        neuraldata_signal{i} = load(neuraldatafile{i}); %creates struct; each cell contains vars for each file 
    end 
end    
    
good_ch = neuraldata_signal{1, 1}.good_ch ; %*assuming same indices for good channels for all files 
ChannelLabel = neuraldata_signal{1, 1}.ChannelLabel ;
%% 
output_alpha = struct([]); 
output_beta = struct([]);
output_theta = struct([]);
output_lowgamma = struct([]);
output_highgamma = struct([]);

for i = 1:length(neuraldata_signal)  %this outputs freq bands for 6 conditions within neuraldata file, and corresponding conditions
    [output_alpha(i).conditions,output_alpha(i).condition_names] = bin_data(neuraldata_signal{i,1}.alpha_signal,tbl_forepoch{i,1}.tbl,srate_raw,trial_length,num_channels); 
    [output_beta(i).conditions,output_beta(i).condition_names] = bin_data(neuraldata_signal{i,1}.beta_signal,tbl_forepoch{i,1}.tbl,srate_raw,trial_length,num_channels); 
    [output_theta(i).conditions,output_theta(i).condition_names] = bin_data(neuraldata_signal{i,1}.theta_signal,tbl_forepoch{i,1}.tbl,srate_raw,trial_length,num_channels); 
    [output_lowgamma(i).conditions,output_lowgamma(i).condition_names] = bin_data(neuraldata_signal{i,1}.lowgamma_signal,tbl_forepoch{i,1}.tbl,srate_raw,trial_length,num_channels); 
    [output_highgamma(i).conditions,output_highgamma(i).condition_names] = bin_data(neuraldata_signal{i,1}.highgamma_signal,tbl_forepoch{i,1}.tbl,srate_raw,trial_length,num_channels); 
end 
 

%concatenate for SIMNETS 
output_all_alpha_mat = [];
output_all_beta_mat =[];
output_all_theta_mat=[];
output_all_lowgamma_mat =[];
output_all_highgamma_mat = []; 
output_all_cond = {}; 
for i = 1:length(neuraldata_signal)
    %for alpha 
    output_data_alpha = output_alpha(i).conditions;
    output_alpha_mat = cell2mat(output_data_alpha);
    output_all_alpha_mat = vertcat(output_all_alpha_mat, output_alpha_mat);% Add it to the giant output matrix by concatenating along 1st axis 
    %repeat for Beta 
    output_data_beta = output_beta(i).conditions;
    output_beta_mat = cell2mat(output_data_beta);
    output_all_beta_mat = vertcat(output_all_beta_mat, output_beta_mat);% Add it to the giant output matrix by concatenating along 1st axis 
    %repeat for Theta 
    output_data_theta = output_theta(i).conditions;
    output_theta_mat = cell2mat(output_data_theta);
    output_all_theta_mat = vertcat(output_all_theta_mat, output_theta_mat);% Add it to the giant output matrix by concatenating along 1st axis 
    %repeat for LowGamma 
    output_data_lowgamma = output_lowgamma(i).conditions;
    output_lowgamma_mat = cell2mat(output_data_lowgamma);
    output_all_lowgamma_mat = vertcat(output_all_lowgamma_mat, output_lowgamma_mat);% Add it to the giant output matrix by concatenating along 1st axis 
    %repeat for HighGamma 
    output_data_highgamma = output_highgamma(i).conditions;
    output_highgamma_mat = cell2mat(output_data_highgamma);
    output_all_highgamma_mat = vertcat(output_all_highgamma_mat, output_highgamma_mat);% Add it to the giant output matrix by concatenating along 1st axis 
    
    %now combine conditions 
    %conditions should be same across all freq band data so just using alpha's  
    output_cond = output_alpha(i).condition_names; 
    output_all_cond = vertcat(output_all_cond, output_cond);
end



%% save data 

    disp('saving file') 
    outputdir = '/Users/anushaallawala/Research/DBSTRD001/SIMNETS/formatted_data';
    %mkdir(outputdir);   %create the directory
    prompt = 'Enter Filename e.g. lVCVS_elec_xx_f_yy';
    text_entry = input(prompt,'s');
    thisfile = sprintf('cSIMSformatteddata_%s.mat', text_entry)  
    fulldestination = fullfile(outputdir, thisfile);  %name file relative to that directory
    save (fulldestination,'output_all_alpha_mat','output_all_beta_mat','output_all_theta_mat','output_all_lowgamma_mat','output_all_highgamma_mat','output_all_cond','trial_length','num_channels','srate_raw','good_ch','ChannelLabel') ;


 
