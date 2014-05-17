function [result,Data]=voxvoiGetData(voxvoiFile,VolumeFile,ResultsFile,GM_WM_File,Threshold,AbsThres)
%
% [result,Data]=voxvoiGetData([voxvoiFile,VolumeFile,[ResultFile[,GM_WM_File[,Threshold[,AbsThres]]]]])
%
% Program that extract ROI data from a volume
%
%   voxvoiFile  - File with an voxvoi VOI set (if not .descr is available,
%                  volumes are named as Voi 1, Voi 2, ....
%   VolumeFile  - File with a functional image, where data shall be
%                  extracted fro, if cell array of file names are given,
%                  then results are returned in cell array
%   ResultsFile - Txt file with result of ROI extraction, can be
%                  empty, then only results are returned
%   GM_WM_File  - Gray, white matter segmented file, same resolution as
%                  functional image. If present gray and white matter values
%                  are calculated for the ROIs too. Values in file should
%                  be
%                  0 - Background, 1 - CSF, 2 - GM, 3 - WM, 4- Fat, >10
%                  different GM ROIs (used as GM). If empty ignored
%   Threshold   - Fractile of voxel values where voxels below this value are
%                  ignored when calculating mean (default is 0%)
%   AbsThres    - Absolut threshold value. If this value is given then highest of this 
%                  and Threshold is used
%
%   result      - 1 if no problem, 0 if problem with one or more files
%   Data        - Structure array with data (i,j)
%                   i - is the ROI number
%                   j - is the voxel class (1 - all, 2 - GM, 3 - WM, 4 -
%                                           CSF, 5 - BG, 6 - Fat)
%                  for each of them the following information is returned:
%
%                     Data(i,j).Name='Name of ROI';
%                     Data(i,j).NoOfVoxels
%                     Data(i,j).Volume
%                     Data(i,j).Mean
%                     Data(i,j).Std
%                     Data(i,j).Median
%                     Data(i,j).Min
%                     Data(i,j).Max
%
% CS, 20030128
%
result=1;
%
if (nargin ~=0) && (nargin ~= 2) && (nargin ~= 3) && (nargin ~=4) && (nargin ~=5) && (nargin ~=6)
    error('voxvoiGetData has to be called with 0, 2, 3, 4 or 5 parameters');
end
if (nargin==2)
    ResultsFile=[];
end
if (nargin==3)
    GM_WM_File=[];
end
if (nargin <=4)
    Threshold=0;
end
if (nargin <=5)
    AbsThres=-Inf;
end
if isempty(Threshold)
    Threshold=0;
end
if isempty(AbsThres)
    AbsThres=-Inf;
end
%
if (nargin==0)
    [FILENAME, PATHNAME] = uigetfile('*.img','voxvoi file with ROIs');
    if (FILENAME==0)
        warning('voxvoiGetData: No voxvoi file selected')
    end
    voxvoiFile=[PATHNAME FILENAME];
    [FILENAME, PATHNAME] = uigetfile('*.hdr','Volume file to apply ROIs at');
    if (FILENAME==0)
        warning('voxvoiGetData: No volume file selected')
    end
    VolumeFile={[PATHNAME FILENAME]};
    [FILENAME, PATHNAME] = uiputfile('*.txt','Name of text file with results');
    if (FILENAME==0)
        warning('voxvoiGetData: No output file selected')
	ResultsFile=[];
    else
        ResultsFile=[PATHNAME FILENAME];
        [pn,fn,ext]=fileparts(ResultsFile);
        if (isempty(strfind(ext,'txt')))
            ResultsFile=[ResultsFile '.txt'];
        end
    end
    GM_WM_File=[PATHNAME FILENAME];
    [FILENAME, PATHNAME] = uigetfile('*.hdr','Volume file with GM/WM segmented volume');
    if (FILENAME==0)
        GM_WM_File=[];
    else
        GM_WM_File=[PATHNAME FILENAME];
    end
    prompt={'Voxel % threshold in image (0-100%):',...
            'Absolute threshold value:'};
    name='Other selections';
    numlines=1;
    defaultanswer={'0','-Inf'};
    answer=inputdlg(prompt,name,numlines,defaultanswer);
    Threshold=str2num(answer{1});
    AbsThres=str2num(answer{2});
else
    if (iscell(voxvoiFile))
        Tmp=voxvoiFile{1};
        voxvoiFile=Tmp;
    end
    if (~iscell(VolumeFile))
        Tmp{1}=VolumeFile;
        VolumeFile=Tmp;
    end
    if (iscell(ResultsFile))
        ResultsFile={ResultsFile};
    end
    if (iscell(GM_WM_File))
        GM_WM_File={GM_WM_File};
    end
end
%
[VoiVolume,hdr]=ReadAnalyzeImg(voxvoiFile,'raw');
%
MaxVoiVolume=max(VoiVolume(:));
%
for i=1:ceil(double(MaxVoiVolume)/64)
   VoiBit{i}=zeros(size(VoiVolume),'uint64');
end    
% Convert To Bit vol
%
for i=1:MaxVoiVolume
   pos=find(VoiVolume==i);
   VoiBit{ceil(double(i)/64)}(pos)=bitset(VoiBit{ceil(double(i)/64)}(pos),rem(i-1,64)+1); 
end
%
% Read or define txt string to each VOI
%
VoiDescription=ReadRoiDescription(voxvoiFile);
if isempty(VoiDescription)
    for i=1:MaxVoiVolume
        VoiDescription{i}=sprintf('VOI %i',i);
    end
end
if MaxVoiVolume~=length(VoiDescription)
    error('voxvoiGetData: No of description in .description file does not correspond to no of regions in volume file');
end
%
NoVoiDescription='All_voxels';
%
Data=editroiPrintData(VolumeFile,voxvoiFile,VoiBit,VoiDescription,NoVoiDescription,ResultsFile,GM_WM_File,Threshold,AbsThres);


function RoiDescription=ReadRoiDescription(FileName)
%
% Function that reads a simple text file with ROI names, if available
%  should have extension ".descr"
%
[pn,fn,ex]=fileparts(FileName);
if isempty(pn)
    pn='.';
end
pid=fopen([pn filesep fn '.descr'],'r');
if (pid == -1)
    RoiDescription=[];
else
    Counter=1;
    while ~feof(pid)
        Line=fgetl(pid);
        [i,no,err,next]=sscanf(Line,'%i,');
        Line=Line(next:length(Line));
        pings=strfind(Line,'"');
        if isempty(pings)
            descr=deblank(deblank(Line')');
        else  % Remove quatations from names
            descr=Line(pings(1)+1:pings(2)-1);
        end
        RoiDescription{Counter}=descr;
        Counter=Counter+1;
    end
    fclose(pid);
end