function project=runbatch_nogui(filelist, gm, wm, csf, rois, dat, x_fwhm, y_fwhm, z_fwhm)

project=setupProject_nogui(0,'pvelabCorrectOnly.ini');
TaskIndex = 1;
MethodIndex = 1;

%load template
template=load('SegSkipAtlas.tem','-MAT');

NumberMR=1;
if template.template.pipeline.userPipeline(1)==1
    project=logProject('1 MR per study',project,TaskIndex,MethodIndex);
else
    NumberMR=3;
    project=logProject('3 MR per study',project,TaskIndex,MethodIndex);
end    

a=textread(filelist,'%s','delimiter',';');

PETS=a(1:(1+NumberMR):end)';
T1WS=a(2:(1+NumberMR):end)';
T2WS=a(NumberMR:(1+NumberMR):end)';
PDWS=a(1+NumberMR:(1+NumberMR):end)';
project.handles.h_mainfig = 'n';

for i=1:length(PETS)
    project=logProject(['Running analysis ',num2str(i)],project,TaskIndex,MethodIndex);
    %project.sysinfo.prjfile = fullfile('/Users/erik/Dropbox/Analysis/Alzheimers/DemoImages','ErikProject.prj');
    project=RunPrjFromTemplate_nogui(project,TaskIndex,MethodIndex,cell2mat(PETS(i)),cell2mat(T1WS(i)),cell2mat(T2WS(i)),cell2mat(PDWS(i)), gm, wm, csf, rois, dat, x_fwhm, y_fwhm);
    disp project;
end

