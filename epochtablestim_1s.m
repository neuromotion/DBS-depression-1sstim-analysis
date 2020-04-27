function epochtablestim_1s() 

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %---- Stimulation Epoch file for 1s stim ----% 
        %--Run for data acquired from TRD patients--%
%Each neural data file for stim should contain the following params: 
        %1 freq, 2 amps, 3 PW, 1 curr dir, 1 lead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load .mat file containing comments from Blackrock NSP (originally NEV) 


disp('Select NEV files for 1s STIM')
[filename,filepath]=uigetfile('*.nev','Select NEV File');
NEV = openNEV(fullfile(filepath,filename),'nosave');

%filename = 'sub-TRDDBS001_task-shortstim_run_01_blk-rVCVSf130elec12'; %example filename 
%% 
%get timestamps from comment file 
comments = NEV.Data.Comments; 
timestamps = comments.TimeStampSec';

%get text from comment file
comments_text = string(NEV.Data.Comments.Text);

%% parse out stim param information from stimulation comments 

 header_text = "#StimOn#";
 N = length(comments_text); %number of total trials in this file 
frequency_field = strings(N,1); %preallocating freq string 
 %take out garbage comments (if theres any that say there is packet loss,
 %or error7uuyw252mk, .
  for i = 1:N
     trial_text = comments_text(i);
     disp(i)
     % Look for the known first column of data.  If it isn't there, skip
     % to the next loop index i with 'continue'.
     header_column = extractBetween(trial_text, 1, strlength(header_text));
     if header_column ~= header_text %if first few characters are not #StimOn#
         frequency_field(i) = "NODATA";
         continue;
     end
  end 
  
  
  %% 
  
  
 trashtrials_idx = frequency_field == "NODATA"; %trials without #stimon# header 
 keeptrials_idx = ~trashtrials_idx; 
 clean_comments_text = comments_text(keeptrials_idx); %comments with trash comments thrown out 
 
  %set up parsing out freq info 
 freq_pattern = 'f=\d*;';
 frequency_field = clean_comments_text; % Cheat to make a string array of length N by copying.
  
 %set up parsing out amplitude info  
 %amp_pattern = 'amp=\d*(\s*\d*)?;'
 amp_pattern = 'amp=\d*(\s*\d*\s*\d*)?;'
 amp_field = clean_comments_text;
 
 %set up parsing out pulse width info 
 %pw_pattern = 'PW=\d*;'
 pw_pattern = 'PW=\d*;'
 pw_field = clean_comments_text; 
 
 %set up parsing out electrode info 
 e_pattern = 'e=\d*(\s*\d*\s*\d*)?;';
 e_field = clean_comments_text;
  
  
 %number of trials after throwing out bad comments 
 num_trials = length(clean_comments_text); 
 
 
 if num_trials == N; 
     fprintf ('no comments thrown out') 
 else 
    fprintf('threw out some comments because of error') 
 end
%% creating strings with information for each parameter (freq,amp,PW,elec #) 
 for i = 1:num_trials
     %parse out freq 
     [start_idx, end_idx] = regexp(clean_comments_text(i),  freq_pattern);
     frequency_field(i) = extractBetween(clean_comments_text(i), start_idx+2, end_idx-1);
     
     %now for amplitude
     [start_idx_amp, end_idx_amp] = regexp(clean_comments_text(i),  amp_pattern);
     amp_field(i) = extractBetween(clean_comments_text(i), start_idx_amp+4, end_idx_amp-1);
     amp_field(i) = strrep(amp_field(i), '  ','_');
     
     %now for pulse width 
     [start_idx_pw, end_idx_pw] = regexp(clean_comments_text(i),  pw_pattern);
     pw_field(i) = extractBetween(clean_comments_text(i), start_idx_pw+3, end_idx_pw-1);
     
     %dont forget the electrode number grandma  
     [start_idx_e, end_idx_e] = regexp(clean_comments_text(i), e_pattern);
     e_field(i) = extractBetween(clean_comments_text(i), start_idx_e+2, end_idx_e-1);
     e_field(i) = strrep(e_field(i), '  ','_');
     
 end 



 %% set up remaining info for epoch table 

braintarget = 'blk-(l|r)(VCVS|SCC)';
[start_idx_br, end_idx_br] = regexp(filename,braintarget);
DBStarget = extractBetween(filename,start_idx_br+4,end_idx_br);


%create Mx1 variable with condition names for each trial 
condition = cell(num_trials,1);
for i = 1:num_trials 
tmp = sprintf('%s_elec%s_amp%s_freq%s_pw%s' ,DBStarget{1}, e_field(i), amp_field(i), frequency_field(i), pw_field(i)); 
condition{i} = tmp; 
end

%get additional information about run/block/trials 
subjectID= 'sub-\w*_'; 
[start_idx_subid end_idx_subid] = regexp(filename,subjectID);
subjectname = extractBetween(filename,start_idx_subid+4,end_idx_subid-1); 

taskinfo = 'task-\w*_'; 
[start_idx_run end_idx_run] = regexp(filename,taskinfo);
task_name = extractBetween(filename,start_idx_run+5,end_idx_run-8); 

block_info = 'blk-\w*'; 
[start_idx_block end_idx_block] = regexp(filename,block_info);
block_name = extractBetween(filename,start_idx_block+4, end_idx_block);

run_info = 'run-\d*';
[start_idx_run end_idx_run] = regexp(filename,run_info);
run_num = extractBetween(filename,start_idx_run+4,end_idx_run);

%generate epoch table 
table_as_matrix = zeros(num_trials, 9);
table_as_matrix(:, 1) = 1:num_trials;
%table_as_matrix(:, 2) = block_name; can't add string yet 
table_as_matrix(:, 3) = timestamps(keeptrials_idx);
%table_as_matrix(:, 4) = condition{:}; %cant add string yet 
table_as_matrix(:, 5) = frequency_field;
table_as_matrix(:, 6) = pw_field;
table_as_matrix(:, 7) = amp_field;
table_as_matrix(:, 8) = e_field;
%table_as_matrix(:, 9) = DBStarget{1};

tbl = array2table(table_as_matrix, 'VariableNames', ...
{'TrialNum', 'Block', 'Time', 'ConditionSummary', 'Frequency', 'PW', 'Amp',...
'Contacts', 'Stimtarget'});

% Reformat the block numbers as strings with 3 digits
block_numbers = repmat(block_name,1,num_trials);
tbl.Block = block_numbers'; 
tbl.ConditionSummary = string(condition);
tbl.Frequency = frequency_field;
tbl.PW = pw_field;
tbl.Amp = amp_field;
tbl.Contacts = e_field;
tbl.Stimtarget = repelem(string(DBStarget{1}),num_trials)';

 %% save/export epoch table 
 
disp('saving file') 
outputdir = '/Users/anushaallawala/Research/DBSTRD001/stimepochs';
%mkdir(outputdir);   %create the directory
thisfile = sprintf('epoch_Sub-%s_%s_Run_%s_Blk-%s.mat', subjectname{1}, task_name{1}, run_num{1}, block_name{1})
fulldestination = fullfile(outputdir, thisfile);  %name file relative to that directory
save(fulldestination, 'tbl');  %save the file there directory
 
%% comment out if not using RAVE 
FileName = sprintf('epoch_Sub-%s_%s_Run_%s_Blk-%s_RAVE.csv', subjectname{1}, task_name{1}, run_num{1}, block_name{1})
writetable(tbl,FileName); 

[savefile,savepath] = uiputfile([sprintf('epoch_Sub-%s_%s_Run_%s_Blk-%s_RAVE.csv', subjectname{1}, task_name{1}, run_num{1}, block_name{1})]);
disp(['Saving ',savefile])
writetable(tbl,fullfile(savepath,savefile))


end 



 