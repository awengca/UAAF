function aa_frontend(xmlfile)
%
% generate aa userscript and tasklist from a unified aa analysis file (UAAF)
%
% usage: aa_frontend('/Users/peellelab/UAAF.xml');
%
%
%

[tree,~,~] = xml_read('UAAF_demo.xml');

fid = fopen('aa_temp_demo.m','w');
if (fid < 0); cleanup_and_exit(1); end
generate_userscript(fid,tree);
fclose(fid);

fid = fopen('aa_temp_demo.xml','w');
if (fid < 0); cleanup_and_exit(2); end
generate_tasklist(fid,tree);
fclose(fid);

% if (do_preflight); preflight_scripts; end
%
% run "aa_temp" here...
% aa_temp
% delete aa_temp.m and aa_temp.xml on exit

cleanup_and_exit(0);

end

%-----------------------------------------------------------------------------------------------------------------------------------
% generate_tasklist 
%-----------------------------------------------------------------------------------------------------------------------------------

function generate_tasklist(fid, tree)
	
    fprintf(fid,'%s\n','<?xml version="1.0" encoding="utf-8"?>');
    fprintf(fid,'%s\n','<aap>');
    fprintf(fid,'%s\n','<tasklist>');
    
    % initialization block
    
    fprintf(fid,'\n%s\n','<initialisation>');
  
	 for index = 1:numel(tree.tasklist.initialisation.module)
        module_name = tree.tasklist.initialisation.module(index).name;
       fprintf(fid,'\t<module><name>%s</name></module>\n', module_name);
     end

    fprintf(fid,'%s\n','</initialisation>');

    % tasklist block
    % FINISH ME -- text sub <extraparameters><aap><tasklist><currenttask><settings> for <option>
    
    
    fprintf(fid,'\n%s\n','<main>');
    
    for index = 1:numel(tree.tasklist.main.module)
        module_name = tree.tasklist.main.module(index).name;
        switch(module_name)
            case 'aamod_segment8_multichan'
                   fprintf(fid,'\t<module><name>%s</name>\n', module_name);
                   task_units(fid,tree);
            case 'aamod_smooth'
                   fprintf(fid,'\t<module><name>%s</name>\n', module_name);
                   smooth_FWHM(fid,tree);
            case 'aamod_norm_write'
                   fprintf(fid,'\t<module><name>%s</name></module>\n', module_name);
                   norm_write_warning(fid,tree);
            otherwise
                   fprintf(fid,'\t<module><name>%s</name></module>\n', module_name);
        end
    end
    
    
    fprintf(fid,'%s\n\n','</main>');
    fprintf(fid,'%s\n','</tasklist>');
    fprintf(fid,'%s\n','</aap>');
    
end


%-----------------------------------------------------------------------------------------------------------------------------------
% check for and handle preprocessing options
%-----------------------------------------------------------------------------------------------------------------------------------


function task_units(fid,tree)

      tasklist_fieldnames = fieldnames(tree.tasklist.settings);
      sampling_interval = 0;
    
      for index = 1:numel(tasklist_fieldnames)
        thisfieldname = tasklist_fieldnames{index};
        
        switch(thisfieldname)
            case 'segment_samp'
                sampling_interval = num2str(getfield(tree.tasklist.settings, 'segment_samp'));
        end
      end

     fprintf(fid,'\t\t<extraparameters>\n');
     fprintf(fid,'\t\t\t<aap><tasklist><currenttask><settings>\n');
     fprintf(fid,'\t\t\t\t<samp>%s</samp>\n',sampling_interval);
     fprintf(fid,'\t\t\t</settings></currenttask></tasklist></aap>\n');
     fprintf(fid,'\t\t</extraparameters>\n');
     fprintf(fid,'\t</module>\n\n\n');
end

function norm_write_warning(fid,tree)
    fprintf(fid,'\n\n\t<!-- you may need to change domain=''*'' to domain=''session'' in aamod_norm_write.xml! -->\n\n');
end


function smooth_FWHM(fid,tree)
          tasklist_fieldnames = fieldnames(tree.tasklist.settings);
      smooth_kernel = 0;
    
      for index = 1:numel(tasklist_fieldnames)
        
        
        thisfieldname = tasklist_fieldnames{index};
        switch(thisfieldname)
            case 'smooth_FWHM'
                smooth_kernel = num2str(getfield(tree.tasklist.settings, 'smooth_FWHM'));
        end
      end
 
     fprintf(fid,'\t\t<extraparameters>\n');
     fprintf(fid,'\t\t\t<aap><tasklist><currenttask><settings>\n');
     fprintf(fid,'\t\t\t\t<FWHM>%s</FWHM>\n',smooth_kernel);
     fprintf(fid,'\t\t\t</settings></currenttask></tasklist></aap>\n');
     fprintf(fid,'\t\t</extraparameters>\n');
     fprintf(fid,'\t</module>\n\n\n');
end





%-----------------------------------------------------------------------------------------------------------------------------------
% generate_userscript 
%-----------------------------------------------------------------------------------------------------------------------------------

function generate_userscript(fid, tree)

    fprintf(fid,'%s\n','clear all;');
    fprintf(fid,'%s\n','clear functions;');
    fprintf(fid,'%s\n','cd(''~'');');
    fprintf(fid,'%s\n\n','aa_ver5;');
    
    fprintf(fid,'\n\n');
    FSLhack(fid);
    
    % task_units default to 'scans'
    task_units = 'scans';
    tasklist_fieldnames = fieldnames(tree.tasklist.settings);
    
    for index = 1:numel(tasklist_fieldnames)
        thisfieldname = tasklist_fieldnames{index};
       
    
        switch (thisfieldname)

            case 'default_parameters'
                parameters_fname = getfield(tree.tasklist.settings, 'default_parameters');
                tasklist_fname = 'aa_temp_demo.xml';
                fprintf(fid,'aap = aarecipe(''%s'',''%s'');\n', parameters_fname, tasklist_fname);

            case 'root'
                root_directory = getfield(tree.tasklist.settings, 'root');
                fprintf(fid,'aap.acq_details.root = ''%s'';\n', root_directory);
            
            case 'result_directory'
                result_directory = getfield(tree.tasklist.settings, 'result_directory');
                fprintf(fid,'aap.directory_conventions.analysisid = ''%s'';\n', result_directory);
                      
            case 'data_directory'
                data_directory = getfield(tree.tasklist.settings, 'data_directory');
                fprintf(fid,'aap.directory_conventions.rawdatadir = ''%s'';\n', data_directory);  
            
            case 'identify_options'
                identify_dataset = getfield(tree.tasklist.settings, 'identify_options');
                inputParams(fid,identify_dataset);
                
            case 'task_units'
                task_units = getfield(tree.tasklist.settings, 'task_units');      
        end
    end
    
    
    % TODO, subject selection
    processBIDS(fid);
    fprintf(fid,'\n\naap.tasksettings.aamod_firstlevel_model.xBF.UNITS = ''%s'';\n\n', task_units);
   
    %modeling
    defineContrasts(fid);
    
    fprintf(fid,'\n%s\n','aa_doprocessing(aap);');
%     if (do_report); fprintf(fid,'%s\n','aa_report(fullfile(aas_getstudypath(aap),aap.directory_conventions.analysisid));'); end
    fprintf(fid,'%s\n','aa_close(aap);');
    
end



% -------------------------------------------------------------------
% Function toolbox
% -------------------------------------------------------------------

%placeholder while i figure out .txt(or other) specification for contrasts
%and modeling
function defineContrasts(fid)

        fprintf(fid,'aap = aas_addcontrast(aap, ''aamod_firstlevel_contrasts_*'',''*'',''sameforallsessions'', [1,0,0], ''faces'',''T'');\n');
        fprintf(fid,'aap = aas_addcontrast(aap, ''aamod_firstlevel_contrasts_*'',''*'',''sameforallsessions'', [0,1,0], ''objects'',''T'');\n');
        fprintf(fid,'aap = aas_addcontrast(aap, ''aamod_firstlevel_contrasts_*'',''*'',''sameforallsessions'', [0,0,1], ''places'',''T'');\n');
end


%placeholder for subject specification
function processBIDS(fid) 
      fprintf(fid,'aap = aas_processBIDS(aap, [], [], {''sub-01'', ''sub-02'', ''sub-03'', ''sub-04'', ''sub-05'', ''sub-06'', ''sub-07'', ''sub-08'', ''sub-09''});');
end

%FSL directory specification workaround
function FSLhack(fid)

   
        fprintf(fid,'FSL_binaryDirectory = ''/usr/local/fsl/bin'';\n');
        fprintf(fid,'currentPath = getenv(''PATH'');\n');
        fprintf(fid,'if ~contains(currentPath,FSL_binaryDirectory)\n');
        fprintf(fid,'\tcorrectedPath = [ currentPath '':'' FSL_binaryDirectory ];\n');
        fprintf(fid,'\tsetenv(''PATH'', correctedPath);\n');
        fprintf(fid,'end\n\n\n');

end

%input parameters for specific datasets
function inputParams(fid,dataset_name)
        switch(dataset_name)
            case('ds001497')
                fprintf(fid,'\n\naap.options.autoidentifystructural_choosefirst = 1;\n');
                fprintf(fid,'aap.options.autoidentifystructural_chooselast = 0;\n\n');
                fprintf(fid,'aap.options.NIFTI4D = 1;\n');
                fprintf(fid,'aap.acq_details.numdummies = 0;\n');
                fprintf(fid,'aap.acq_details.intput.correctEVfordummies = 0;\n\n');
                
        end
end



%-----------------------------------------------------------------------------------------------------------------------------------
% cleanup_and_exit 
%-----------------------------------------------------------------------------------------------------------------------------------

function cleanup_and_exit(ierr)

 	%system('rm -f aa_temp_demo.m');
 	%system('rm -f aa_temp_demo.xml');
    if (ierr); disp(aap, true, sprintf('\n%s: Script generation failed (ierr = %d).\n', mfilename, ierr)); end
	
end