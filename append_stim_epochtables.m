 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %---- Appending all stim epoch files for 1s stim ----% 
           %--Run for data acquired from TRD patients--%
%--Combining 60 diff files (each containing 1 current direction, 1 frequency, 3 PW, 2 amplitudes)--%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%filename for indiv epoch files should look like this:  'epochtable_R_SGC_elec1_amp2000_freq130_pw180';

% get files 
[filename,filepath]=uigetfile('*.mat','Select .mat File','MultiSelect','on');

% load epoch tables 
for i = length(filename)
    S(i) = load(fullfile(filepath,filename{i}));  
end 

num_rows = height(S(1).tbl)*length(filename);
num_cols = width(S(1).tbl);
%set up size for final epoch table  
complete_table = table('Size',[num_rows, num_cols], 'VariableTypes', {'double', 'string', 'double','double','string','double'}, 'VariableNames', ...
{' ', 'Block', 'Time', 'Trial', 'Condition', 'Duration'});

%concatenate all epoch tables 
complete_table = vertcat(S(:).tbl);   


%save tbl as .mat file 
experiment_info = inputdlg('Enter file info in example format: "epochtable_stim1s_additionalinfonasneeded'); 
FileName = sprintf('epochtable_%s.mat', experiment_info{1})
save (FileName,'tbl'); 

%save table as csv for RAVE 
FileName_csv = sprintf('epochtable_%s.csv', experiment_info{1})
writetable(tbl,FileName_csv); 