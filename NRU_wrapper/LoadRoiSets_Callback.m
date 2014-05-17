function RoiSets = LoadRoiSets_Callback(h, eventdata, handles, varargin)
%applyrois_disp('Load ROI sets buttom pressed');
%
FileInfo=which('applyrois');
[StdRoiPath,StdRoiName,Ext]=fileparts(FileInfo);
StdRoiPath=[StdRoiPath filesep 'stdrois'];
BundleRoiSetPath=FindDirName(StdRoiPath,1);
BundleRoiPath=[StdRoiPath filesep BundleRoiSetPath{1}];
RoiSetsSelected=FindDirName(BundleRoiPath,0);
h=findobj('tag','RoiSetsSelected');
for i=1:length(RoiSetsSelected)
  StdROIs{i}=[BundleRoiPath filesep RoiSetsSelected{i}];
end  
set(h,'string',StdROIs,'value',1);
RoiSets.Sets=StdROIs;
RoiSets.BundleRoi=BundleRoiSetPath{1};
%
% Select ROI set
%
d = dir([BundleRoiPath filesep RoiSetsSelected{1} filesep '*.mat']);
if (~isempty(d))  %.mat files available (editroi ROI files)
  Counter=1;
  for i=1:length(d)
    if (~strncmp(d(i).name,'.',1))&&(~strncmp(d(i).name,'..',2))...
            &&(~strncmp(d(i).name,'CVS',3))&&(d(i).isdir==0)
        QuestDlg(Counter) = {d(i).name};
        Counter=Counter+1;
    end
  end
  if length(QuestDlg)>1
    [s,v] = listdlg('PromptString','Which standard ROIs to use?',...
        'SelectionMode','single',...
        'ListString',QuestDlg);
    if v==0
        error('No selection made');
    end
    StdRoiName=QuestDlg{s};
  else
    StdRoiName=QuestDlg{1};
  end
else               % assuming voxvoi (analyze) ROI files
  d = dir([BundleRoiPath filesep RoiSetsSelected{1} filesep '*.img']);
  Counter=1;
  for i=1:length(d)
    if (~strncmp(d(i).name,'.',1))&&(~strncmp(d(i).name,'..',2))...
            &&(~strncmp(d(i).name,'CVS',3))&&(d(i).isdir==0)
        QuestDlg(Counter) = {d(i).name};
        Counter=Counter+1;
    end
  end
  if length(QuestDlg)>1
    [s,v] = listdlg('PromptString','Which standard ROIs to use?',...
        'SelectionMode','single',...
        'ListString',QuestDlg);
    if v==0
        error('No selection made');
    end
    StdRoiName=QuestDlg{s};
  else
    StdRoiName=QuestDlg{1};
  end
end
%
[fp,ROIsetName,ext]=fileparts(StdRoiName);
h=findobj('tag','ROIsetName');
set(h,'String',ROIsetName);
RoiSets.SetName=ROIsetName;
%
% Select type of structural scan
%
d = dir([BundleRoiPath filesep RoiSetsSelected{1} filesep '*.img']);
Counter=1;
for i=1:length(d)
    if (~strncmp(d(i).name,'.',1))&&(~strncmp(d(i).name,'..',2))...
            &&(~strncmp(d(i).name,'CVS',3))&&(d(i).isdir==0)
        QuestDlg(Counter) = {d(i).name};
        Counter=Counter+1;
    end
end
if length(QuestDlg)>1
    [s,v] = listdlg('PromptString','Which type of structural scan?',...
        'SelectionMode','single',...
        'ListString',QuestDlg);
    if v==0
        error('No selection made');
    end
    StructuralScanTempl=QuestDlg{s};
else
    StructuralScanTempl=QuestDlg{1};
end
[fp,StructuralScanType,ext]=fileparts(StructuralScanTempl);
h=findobj('tag','StructuralScanType');
set(h,'String',StructuralScanType);
RoiSets.TemplateType=StructuralScanType;
 
% --------------------------------------------------------------------
function SelectedDirs=FindDirName(BaseDir,RoiSetsSelection)
%
% Functions that either return cell array of dirs which has been selected.
% If 'definition.txt' is present in the dirs this txt string is used for
% selection else the dir name is used 
%
d = dir(BaseDir);
Counter=1;
for i=1:length(d)
  if (~strncmp(d(i).name,'.',1))&&(~strncmp(d(i).name,'..',2))...
	&&(~strncmp(d(i).name,'CVS',3))&&(d(i).isdir==1)
    str(Counter) = {d(i).name};
    Counter=Counter+1;
  end
end
for i=1:length(str)
    DefinitionFile=fullfile(BaseDir,str{i},'definition.txt');
    if exist(DefinitionFile)==2
        pid=fopen(DefinitionFile,'r');
        if (pid~=-1)
            QuestDlg{i}=fgetl(pid);
            fclose(pid);
        else
            QuestDlg{i}=str{i};
        end
    else
        QuestDlg{i}=str{i};
    end
end
if (RoiSetsSelection==1)
   [s,v] = listdlg('PromptString','Which standard ROI bundles to use?',...
       'SelectionMode','single',...
       'ListString',QuestDlg);
else
   [s,v] = listdlg('PromptString','Which templates to use?',...
       'SelectionMode','multiple',...
       'ListString',QuestDlg);
end
if v==0
    error('No selection made');
end
SelectedDirs={str{s}};
            


% --------------------------------------------------------------------

 
