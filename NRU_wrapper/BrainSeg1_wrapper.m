function project=BrainSeg1_wrapper(project,TaskIndex,MethodIndex,varargin)
% 
% Wrapper for running the BrainSeg1 routine from canterbury in the pipeline program.
% The BrainSeg1 program is written by:
% 
% Collects two inputpoints with Slice3 and executes the BrainSeg1 routine on the loaded T1-weighted MRI.
% Output is one segmented file with three values 80, 160 and 0, denoting respectively gray matter, white matter and surroundings+CSF. 
% This file is split in three files with only two values (0 and 265),to be compatible with atlas and PVE methods.
% 
% Only compiled for unix.
% 
% Input:
%   project: Structure for actual PVE correction process
%   TaskIndex: Index in the project-structure for actual task
%   MethodIndex: Index in the project-structure for actual method
%   varargin: Extra input arguments, not used
%
% Outout:
%   project: structure for actual PVE correction process
%____________________________________________
%By T. Rask, 211103, NRU
%SW version: 211103TR.

%____Check if BrainSeg1 exists
[status,message]=unix('which BrainSeg1');
if status
    msg='Error: Can not find BrainSeg1 in unix path';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return;
end

%_____________ Load configuration settings for project ___________________
%Defaults settings exist?
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))    
    % No user settings have been selected, set defaults...
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.settingsfile='BrainSeg1_settings.txt';
end
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;

% User defined setting exist?
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))    
    %User settings does not exist in project, use default
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
    msg='SpmCoreg_wrapper: Loading default settings.';  
else
    %User settings do exist
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
    msg='SpmCoreg_wrapper: Loading user settings.';
end;
project=logProject(msg,project,TaskIndex,MethodIndex);

%_________________________ Initialise file load ________________________

% How many modalities exist for given brain image...
noModalities=length(project.pipeline.imageModality); % Get number of modalities e.g. PET, T1se (MR)
ImageIndex=project.pipeline.imageIndex(1); %One image always exist, and right now only of one subject...

%____Get input and output
for i=1:noModalities
    %Set input-files to output from fileload task.
    project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.path=project.taskDone{1}.outputfiles{ImageIndex,i}.path;
    project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.name=project.taskDone{1}.outputfiles{ImageIndex,i}.name;
   
    %Set output-files to output from fileload task. (No change to original files)
    project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.path=project.taskDone{1}.outputfiles{ImageIndex,i}.path;
    project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.name=project.taskDone{1}.outputfiles{ImageIndex,i}.name;    
end
%____

%Get inputfile (modality index 2 = T1-weighted MRI)
inputFile=fullfile('',project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.name);
[inpath,inname,inext]=fileparts(inputFile);
inputFile=fullfile('',inpath,inname);

%Define output filename
outputFile=fullfile('',project.sysinfo.workspace,[inname,'_seg']);

%Define settings file
setFile=fullfile('',project.sysinfo.workspace,userConfig.settingsfile);

%______ Get scalp bright point & brain bright point, if points are not already selected
button='';

if (isfield(userConfig,'scalpPoint') & isfield(userConfig,'brainPoint'))
    button = questdlg('Do you want to use preselected points? (choosing ''No'' lets you select new points)',...
        'Use preselected points?','Yes','No','No');
end

if strcmp(button,'Yes') 
    project=logProject(['BrainSeg1_wrapper: Using pre-defined points.'],project,TaskIndex,MethodIndex);
    pos1=userConfig.scalpPoint;
    pos2=userConfig.brainPoint;
else
    %set variables
    ud=[];
    col=[252/255 252/255 254/255];
    ss=get(0,'ScreenSize'); %ScreenSize
    
    %____ Setup slice3
    h_viewer=Slice3(inputFile);
    oldUnits=get(h_viewer,'units');
    set(h_viewer,'units','pixels','position',[ss(1)+325 ss(2)+ss(4) ss(3)-350 ss(4)-25]);
    set(h_viewer,'units',oldUnits);
    %set endcallback, which is executed every time a point is selected.
    Slice3('SetEndCallBack',h_viewer,[...
            'h_dialog=findobj(''tag'',''PipeDialogFig'');',...
            'ud=get(gcf,''userdata'');',...
            'set(h_dialog,''userdata'',ud);',...
            'h_texCo1=findobj(h_dialog,''tag'',''coordTxt1'');',...
            'h_texCo2=findobj(h_dialog,''tag'',''coordTxt2'');',...
            'set(h_texCo1,''string'',[''Selected point [mm]: ('',num2str(ud.coords(1)),'','',num2str(ud.coords(2)),'','',num2str(ud.coords(3)),'')'']);',...
            'set(h_texCo2,''string'',[''Selected point [voxels]: ('',num2str(ud.coords(1)/ud.hdr.siz(1)),'','',num2str(ud.coords(2)/ud.hdr.siz(2)),'','',num2str(ud.coords(3)/ud.hdr.siz(3)),'')'']);']);
    
    %_____Setup dialog figure
    h_dialog=figure(...
        'tag','PipeDialogFig',...
        'units','pixels',...
        'position',[10 project.handles.data.figuresize(4)/2+100 300 200],...
        'resize','off',...
        'NumberTitle','off',...
        'name','Select scalp bright point',...
        'Menubar','none',...
        'Color',col,...
        'userdata',ud);
    
    h_fram=uicontrol('parent',h_dialog,...
        'style','frame',...
        'position',[5 5 290 190],...
        'BackgroundColor',col);
    
    h_texMain=uicontrol('parent',h_dialog,...
        'tag','textfieldPip',...
        'style','text',...
        'units','pixels',...
        'position',[15 150 270 30],...
        'fontweight','bold',...
        'string','Select a bright point in the scalp.',...
        'BackgroundColor',col);
    
    h_texCo1=uicontrol('parent',h_dialog,...
        'tag','coordTxt1',...
        'style','text',...
        'units','pixels',...
        'position',[15 110 270 30],...
        'string',['Selected point [voxels]: none'],...
        'BackgroundColor',col);
    
    h_texCo2=uicontrol('parent',h_dialog,...
        'tag','coordTxt2',...
        'style','text',...
        'units','pixels',...
        'position',[15 80 270 30],...
        'string',['Selected point [mm]: none'],...
        'BackgroundColor',col);
    
    h_okbut=uicontrol('parent',h_dialog,...
        'style','pushbutton',...
        'units','pixels',...    
        'String','Ok',...
        'position',[75 15 70 30],...
        'callback','set(findobj(''tag'',''textfieldPip''),''userdata'',''ok'')');
    h_cancelbut=uicontrol('parent',h_dialog,...
        'style','pushbutton',...
        'units','pixels',...    
        'String','Cancel',...
        'position',[155 15 70 30],...
        'callback','set(findobj(''tag'',''textfieldPip''),''userdata'',''cancel'')');
    
    project=logProject(['BrainSeg1_wrapper: Select points in viewer window...'],project,TaskIndex,MethodIndex);
    
    %______ Bright point in scalp
    waitfor(h_texMain,'userdata'); %Wait for ok or cancel
    
    %___ if cancel is pressed...
    if strcmp(get(h_texMain,'userdata'),'cancel') 
        msg='BrainSeg1_wrapper: User abort. Cancel pressed.';
        project=logProject(msg,project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=msg;
        delete(h_dialog);
        delete(h_viewer);
        return;
    end
    
    ud=get(h_dialog,'userdata');
    %Origin accounted for hereunder (BrainSeg1 does not use origin)
    pos1=round([ud.coords(1)/ud.hdr.siz(1)+ud.hdr.origin(1) ud.coords(2)/ud.hdr.siz(2)+ud.hdr.origin(2) ud.coords(3)/ud.hdr.siz(3)+ud.hdr.origin(3)]);
    userConfig.scalpPoint=pos1;
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
    
    %_______ Bright point in brain
    set(h_dialog,'name','Select brain bright point');
    set(h_texMain,'string','Select a bright point inside the brain.');
    set(h_texMain,'userdata','');
    
    waitfor(h_texMain,'userdata'); %Wait for ok or cancel
    
    %___ if cancel is pressed...
    if strcmp(get(h_texMain,'userdata'),'cancel') 
        msg='BrainSeg1_wrapper: User abort. Cancel pressed.';
        project=logProject(msg,project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=msg;
        delete(h_dialog);
        delete(h_viewer);
        return;
    end
    
    ud=get(h_dialog,'userdata');
    %Origin accounted for hereunder (BrainSeg1 does not use origin)
    pos2=round([ud.coords(1)/ud.hdr.siz(1)+ud.hdr.origin(1) ud.coords(2)/ud.hdr.siz(2)+ud.hdr.origin(2) ud.coords(3)/ud.hdr.siz(3)+ud.hdr.origin(3)]);
    userConfig.brainPoint=pos2;
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
    
    %______Delete dialog and viewer windows
    delete(h_dialog);
    delete(h_viewer);
end %if userConfig exists

%______ Write progress in logwindow
project=logProject(['BrainSeg1_wrapper: Points selected:'],project,TaskIndex,MethodIndex);
project=logProject(['BrainSeg1_wrapper: Scalp bright point: ',num2str(pos1)],project,TaskIndex,MethodIndex);
project=logProject(['BrainSeg1_wrapper: Brain bright point: ',num2str(pos2)],project,TaskIndex,MethodIndex);

%______ Write pipe-input txt-file 
fid=fopen(setFile,'wt+');
fprintf(fid,'%s\n',inputFile);
fprintf(fid,[num2str(pos1(1)),' ',num2str(pos1(2)),' ',num2str(pos1(3)),'\n']);
fprintf(fid,[num2str(pos2(1)),' ',num2str(pos2(2)),' ',num2str(pos2(3)),'\n']);
fprintf(fid,'%s\n',outputFile);
status=fclose(fid);
project.taskDone{TaskIndex}.userdata.settingsFile.name=userConfig.settingsfile;
project.taskDone{TaskIndex}.userdata.settingsFile.path=project.sysinfo.workspace;


%______ Execute BrainSeg1
project=logProject(['BrainSeg1_wrapper: Segmenting ',inname,inext,' ...'],project,TaskIndex,MethodIndex);
[s,mes]=unix(['BrainSeg1',' < ',setFile],'-echo');

if s
    msg=['Error: ',mes];
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return;
end

%______ Register outputfile in project structure
project.taskDone{TaskIndex}.userdata.BrainSeg1out.name=[inname,'_seg.img'];
project.taskDone{TaskIndex}.userdata.BrainSeg1out.path=project.sysinfo.workspace;

project=logProject(['BrainSeg1_wrapper: Outputfile: ',inname,'_seg.img succesfully written.'],project,TaskIndex,MethodIndex);

%______ Create proper header for output
[img,hdr]=ReadAnalyzeImg(fullfile('',project.taskDone{TaskIndex}.userdata.BrainSeg1out.path,project.taskDone{TaskIndex}.userdata.BrainSeg1out.name));
hdr.path=project.taskDone{TaskIndex}.userdata.BrainSeg1out.path;
hdr.lim=[65536 0];
hdr.scale=1;
inputHdr=ReadAnalyzeHdr(inputFile);
hdr.origin=inputHdr.origin; %set origin as in source MR, as they are in same space. (needed for reslice)
hdr.offset=0;
result=WriteAnalyzeHdr(hdr);

project=logProject(['BrainSeg1_wrapper: Splitting outputfile to:'],project,TaskIndex,MethodIndex);

%______ Split output to three files img1, img2 and img3 respectively gray matter, white matter and surroundings+CSF
img1Name=[inname,'_seg1'];
img2Name=[inname,'_seg2'];
img3Name=[inname,'_seg3'];

hdr.lim=[255 0];
hdr.pre=8;
img=reshape(img,hdr.dim');

%Image 1 (Gray matter)
project=logProject(['BrainSeg1_wrapper: Gray matter - ',img1Name,'.img'],project,TaskIndex,MethodIndex);
hdr.name=img1Name;
img1=img;
img1(img==80)=255;
img1(img1~=255)=0;
res=WriteAnalyzeImg(hdr,img1);
clear('img1');

%Image 2 (White matter)
project=logProject(['BrainSeg1_wrapper: White matter - ',img2Name,'.img'],project,TaskIndex,MethodIndex);
hdr.name=img2Name;
img2=img;
img2(img==160)=255;
img2(img2~=255)=0;
res=WriteAnalyzeImg(hdr,img2);
clear('img2');

%Image 3 (Surroundigs+CSF)
project=logProject(['BrainSeg1_wrapper: CSF & Surroundings - ',img3Name,'.img'],project,TaskIndex,MethodIndex);
hdr.name=img3Name;
img3=img;
img3(img==0)=255;
img3(img3~=255)=0;
res=WriteAnalyzeImg(hdr,img3);
clear('img3');

%Register the splitfiles in project structure
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,1}.name=[img1Name,'.img'];
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,2}.name=[img2Name,'.img'];
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,3}.name=[img3Name,'.img'];
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,1}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,2}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,3}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,1}.info='Segmented Gray Matter';
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,2}.info='Segmented White Matter';
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,3}.info='Segmented CSF';
