function [Result,RoiOutVolume]=applyrois_reslice(EditroiInFN,AirFN,EditroiOutFN,...
    WarpField,GM_WM_segmented,FilterWidth)
%  
%  Reslices ROI's in a editroi file using an air file and eventually a warp field
%
%  [Result,RoiValues,RoiOutVolume]=
%             applyrois_reslice(EditroiInFN,AirFN,EditroiOutFN[,WarpField[,FilterWidth]])
%
%    EditroiInFN  - name of editroi file with definition of ROI's to reslice
%    AirFN        - airfile defining input volume, transformation and output 
%                     volume
%    EditroiOutFN - name of editroi file to save resulting ROI's in
%    WarpField    - Warp field to apply 
%    GM_WM_segmented - Segmented image (0 - BG, 1 - CSF, 2 - GM, 3 - WM)
%    FilterWidth  - Filter width in mm of filter to use (default is max. voxel size)
%
%    Result       - Error argument (1 for success, 0 for failure)
%    RoiOutVolume - Volume with ROIs
%
% CS, 180901, Vers. 1
%     290702, Vers. 2, Simplified and commented
%                      Can handle ROIs defined in analyze files
%
Result=1;
if (nargin ~= 0) & (nargin ~=3) & (nargin ~= 4) & (nargin ~= 5) & (nargin ~= 6)
  error('applyrois_reslice functions has to be called with either 0, 3, 4, 5, or 6 right handside arguments');
end
if (nargout > 2)
  error('applyrois_reslice functions has to be called with 0 to 2 left handside arguments');
end
%
if (nargin>0)
  EditroiInPN=[];
  AirPN=[];
  EditroiOutPN=[];
  %
else
  [EditroiInFN, EditroiInPN] = ...
    uigetfile('*.mat', 'Name of editroi file to transform');
  if (EditroiInFN==0)
    error('Editroi file has to be defined');
  end
  [AirFN, AirPN] = ...
    uigetfile('*.air', 'Name of airfile to apply');
  if (AirFN==0)
    error('AIR file has to be defined');
  end
  [EditroiOutFN, EditroiOutPN] = ...
    uiputfile('*.mat', 'Name of output editroi file');
  if (EditroiOutFN==0)
    error('editroi output file has to be defined');
  end
end
%
if (nargin < 6)
  FilterWidth='';
end
if (nargin < 5) 
  GM_WM_segmented='';
end  
if (nargin < 4) 
  WarpField='';
end  
%
TmpDir=GetTmpDirName(pwd);
%
[pn,fn,ext]=fileparts(tempname);
RoiFileIn=[TmpDir filesep fn '_in'];
RoiFileOut=[TmpDir filesep fn '_out'];
%
% Read information about Air transformation file
%
[A,A_Struct]=ReadAir([AirPN AirFN]);
%
% Read Roi that should be transformed and convert to bit volume
%
[ReadRoiResult,RoiDescription,FileType]=...
    ReadRoi([EditroiInPN EditroiInFN],A_Struct.hdrI,RoiFileIn);
if (ReadRoiResult==0)
  error('Not able to read and convert Roi file for reslicing');
end    
%
CallWarpReslice(RoiFileIn,RoiFileOut,A_Struct,WarpField);
%
WriteRoi(RoiFileOut,[EditroiInPN EditroiInFN],...
                 [EditroiOutPN EditroiOutFN],RoiDescription,FileType,GM_WM_segmented,FilterWidth);
%
[RoiOutVolume,Hdr]=ReadAnalyzeImg(RoiFileOut,':','raw');
%
delete(sprintf('%s%s*.*',TmpDir,filesep));
pause(1);
rmdir(TmpDir,'s');



function [Result,RoiDescription,Filetype]=ReadRoi(RoiFile,Hdr,RoiFileIn)
%
% Function that read a ROI definition from disk file, either as a Editroi file,
% or a analyze file containing a ROI volume (unique values for each ROI)
%
%  Result - 0, 1  (0 - error, 1 - OK)
%
Result=1;
RoiDescription=[];
%
[pn,fn,ext]=fileparts(RoiFile);
if isempty(pn)
  pn='.';
end  
%
if (exist([pn filesep fn '.mat']))
  [Res,RoiVolume,RoiDescription]=editroi2analyze(RoiFile,Hdr,[],1);
  Filetype='EditroiFile';
  if (Res == 0)
    Result=0;
  end  
elseif (exist([pn filesep fn '.hdr'])) | (Result==0)
  [Res,RoiVolume,RoiDescription]=ReadAnalyzeRoi(RoiFile,Hdr);
  Filetype='AnalyzeFile';
  if (Res == 0)
    Result=0;
  end
end
%
if (Result==1)
  Res=SaveRoiVolume(RoiVolume,RoiFileIn,Hdr);
  if (Res==0)
    warning('The roi volume has not been saved due to an unknown error');
    Result=0;
  end  
end


function WriteRoi(RoiFileOut,RoiFileIn,RoiOutFileName,...
    RoiDescription,Filetype,GM_WM_segmented,FilterWidth)
%
% Function that read an analyze file containing a ROI bit volume and
% converts it into a editroi file or analyze volume
%
[RoiBitVolume,hdr]=ReadAnalyzeImg(RoiFileOut);
%
if isempty(FilterWidth)
   FilterSpec='';
else
   FilterSpec=[1 1 1]*FilterWidth;
end
FilterThres='';   % Then defaults is used
%
if strcmp(Filetype,'EditroiFile')           % editroi file
  [Result,RoiOut]=analyze2editroi(RoiBitVolume,hdr,RoiDescription,FilterSpec,FilterThres);
  SaveRoi(RoiOutFileName,RoiOut);
  %
elseif strcmp(Filetype,'AnalyzeFile')       % analyze volume file
  [Result]=WriteAnalyzeRoi(RoiBitVolume,hdr,RoiDescription,RoiOutFileName);
else
  error('This format for saving ROI file is not supported');
end    


function [Result,RoiVolume,RoiDescription]=ReadAnalyzeRoi(RoiFile,Hdr)
%
% Function that import a ROI volume, including description fields for 
%  the ROIs
%
Result=1;
%
[RoiVolume,Hdr]=ReadAnalyzeImg(RoiFile,':','raw');
RoiVolume=reshape(RoiVolume,Hdr.dim');
%
[pn,fn,ext]=fileparts(RoiFile);
pid=fopen([pn filesep fn '.descr'],'r');
if (pid ~= -1)
  while ~feof(pid)
    Line=fgetl(pid);
    [RoiNumber,no,err,next]=sscanf(Line,'%i,');
    Line=Line(next:length(Line));
    pings=strfind(Line,'"');
    if isempty(pings)
      descr=deblank(deblank(Line')');     
    else
      descr=Line(pings(1)+1:pings(2)-1);
    end  
    RoiDescription{RoiNumber}=descr;
  end
  fclose(pid);
else
  RoiDescription=[];
  fprintf('No ROI description avaliable\n');
end  


function [Result]=WriteAnalyzeRoi(RoiVolume,Hdr,RoiDescription,RoiOutFileName)
%
% Function that save's a ROI volume, including description fields to
%  an analyze file
%
Result=1;
%
if (max(RoiVolume(:)) > 32767)
  error('Only less than 32767 ROIs can be handled');
end
%
RoiHdr=Hdr;
[pn,fn,ext]=fileparts(RoiOutFileName);
if isempty(pn)
  pn='.';
end  
RoiHdr.name=[pn filesep fn];
RoiHdr.pre=16;
RoiHdr.lim=[32767 -32768];
RoiHdr.scale=1;
RoiHdr.offset=0;
RoiHdr.descr='Roi volume file created by applyrois';
%
WriteAnalyzeImg(RoiHdr,RoiVolume);
%
pid=fopen([pn filesep fn '.descr'],'w');
if (pid == -1)
  warning('Not possible to write file with ROI description');
else
  for i=1:length(RoiDescription)
    if ~isempty(RoiDescription{i})
      fprintf(pid,'%i, "%s"\n',i,RoiDescription{i});
    end  
  end
  fclose(pid);
end

  


function [Result]=SaveRoiVolume(RoiInVolume,RoiFileIn,hdrI)
%
% Function that saves a Roi volume in a 64 bit analyzefile
%
RoiInHdr=hdrI;
RoiInHdr.name=RoiFileIn;
RoiInHdr.path='';
RoiInHdr.pre=64;
RoiInHdr.lim=[0 0];
RoiInHdr.dim=RoiInHdr.dim(1:3);
%
Result=WriteAnalyzeImg(RoiInHdr,RoiInVolume);




function CallWarpReslice(RoiFileIn,RoiFileOut,AirStruct,WarpField)
%
% Function that call WarpReslice program for reslicing of ROI volume
% Format of output volume is defined by the AIR file
%
if (all(AirStruct.hdrI.origin~=0))
  AirStruct.hdrI.origin=AirStruct.hdrI.origin-1;
end;  
if (all(AirStruct.hdrO.origin~=0))
  AirStruct.hdrO.origin=AirStruct.hdrO.origin-1;
end;  
A=inv(tala2voxa(AirStruct.A,AirStruct.hdrI,AirStruct.hdrO));
command1='warp_reslice -n ';                % command (nearest neighbour interpolation)
command2=['-g "' sprintf('%e ',A') '" '];   % AIR transformation file (E1, Kjems)
command3=sprintf('-j %s ',RoiFileIn);       % Roi file in (volume file)
if isempty(WarpField)
  command4='';
else  
  command4=sprintf('-f %s ',WarpField);       %Warp field (med -f parameter)
end  
command5=['-c ' sprintf('%f ',AirStruct.hdrO.siz(1:3)/10')]; %Output voxel size (in cm)
command6=['-z ' sprintf('%i ',AirStruct.hdrO.dim(1:3)')]; % Output volume dimension
command7=['-k ' sprintf('%i ',AirStruct.hdrI.dim(1:3)')]; % Template volume dimension
%command8=['-T ' sprintf('%i ',AirStruct.hdrO.origin')]; %Output volume origin
command8=['-T 1 1 1 ']; %Output volume origin
command9=sprintf('%s',RoiFileOut);          %Roi file out (volume file)
command=[command1 command2 command3 command4 command5 command6 command7 ...
         command8 command9];
[s,r]=unix(command);
%
pid=fopen('ResliceMR.txt','a');
fprintf(pid,'Call in CallWarpReslice (applyrois_reslice): %s\n',command);
fclose(pid);
%
if (s~=0)
  error(['Not able to execute warp_reslice command, error message: ' r]);
end  



function [tmpdir]=GetTmpDirName(basedir)
%
% Searches for the first available tmp dir name and creates the directory
%
Stop=0;
while Stop~=-1
   tmpdir=sprintf('%s%stmp_resl%02i',basedir,filesep,Stop);
   if (exist(tmpdir)==0)
      mkdir(tmpdir);
      Stop=-1;
   else
      Stop=Stop+1;
   end
end








