function [result,Data]=editroiGetData(EditroiFile,VolumeFile,ResultsFile,GM_WM_File,Threshold,AbsThres)
%
% [result,Data]=editroiGetData([EditroiFile,VolumeFile,[ResultFile[,GM_WM_File[,Threshold[,AbsThres]]]]])
%
% Program that extract ROI data from a volume
%
%   EditroiFile - File with an editroi ROI set
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
    error('editroiGetData has to be called with 0, 2, 3, 4 or 5 parameters');
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
    [FILENAME, PATHNAME] = uigetfile('*.mat','Editroi file with ROIs');
    if (FILENAME==0)
        warning('editroiGetData: No editroi file selected')
    end
    EditroiFile=[PATHNAME FILENAME];
    [FILENAME, PATHNAME] = uigetfile('*.hdr','Volume file to apply ROIs at');
    if (FILENAME==0)
        warning('No volume file selected')
    end
    VolumeFile={[PATHNAME FILENAME]};
    [FILENAME, PATHNAME] = uiputfile('*.txt','Name of text file with results');
    if (FILENAME==0)
        warning('No output file selected')
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
    if (iscell(EditroiFile))
        Tmp=EditroiFile{1};
        EditroiFile=Tmp;
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
[Result,RoiVolume,RoiDescription]=editroi2analyze(EditroiFile,VolumeFile{1},'',1);
NoRoiDescription='All_voxels';
%
Data=editroiPrintData(VolumeFile,EditroiFile,RoiVolume,RoiDescription,NoRoiDescription,ResultsFile,GM_WM_File,Threshold,AbsThres);









