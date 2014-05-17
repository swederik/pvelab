function [Result,RoiVolume,RoiDescription]=voxvoi2pve(voxvoiInFN,VolumeGmWmFN,VolumeOutFN)
%  
%  Convert a set of ROIs defined in a voxvoi file (1, 2, 3, 4, ...) into a volume of ROIs,
%  with thw ROI numbered as 10, 11, 12. Further if a GM_WM file is specified
%  only the GM voxels in each ROI will be given the values. Outside the ROIs
%  the voxels will be given the values 0 - BG, 1 - CSF, 2 - GM, 3 - WM, 4 -
%  Fat. 
%
%  [Result,RoiVolume,RoiDescription]=
%             voxvoi2pve([voxvoiInFN,VolumeInFN,VolumeGmWmFN,VolumeOutFN])
%
%    voxvoiInFN   - name of voxvoi file with definition of ROI's to create
%                    volume from (eventually this can be a ROI structure)
%    VolumeGmWmFN   - Name of the gray/white matter file (should have same
%                    size as VolumeIn. If emty no classification is used
%    VolumeOutFN  - Name of analyze file for writing the ROI volume into. A
%                    file with the name "<VolumeOutFN>.descr" is also
%                    created containing two columns (RoiNo, RoiName) (if not
%                    specified nothing is saved)
%
%    Result       - Error argument (1 for success, 0 for failure)
%    RoiVolume    - Volume with ROIs
%    RoiDescription - Cell aray with names of ROIs
%
% CS, 030224, Vers. 1
%
Result=1;
if (nargin ~= 0) && (nargin ~=3)
  error('editroi2pve function has to be called with either 0 or 4 right handside arguments');
end
if (nargout > 3)
  error('editroi2analyze function has to be called with 0 to 3 left handside arguments');
end
%
if (nargin == 0)
  [voxvoiInFN, voxvoiInPN] = ...
    uigetfile('*.img', 'Name of voxvoi file to transform');
  if (voxvoiInFN==0)
    error('voxvoi file has to be defined');
  end
  voxvoiInFN=[voxvoiInPN voxvoiInFN];
  [VolumeGmWmFN, VolumeGmWmPN] = ...
    uigetfile('*.img', 'Name of volume file with gray/white matter field');
  if (VolumeGmWmFN==0)
    VolumeGmWmFN=[];
  else  
    VolumeGmWmFN=[VolumeGmWmPN VolumeGmWmFN];
  end
  [VolumeOutFN, VolumeOutPN] = ...
    uiputfile('*.img', 'Name of file for saving output volume into');
  if (VolumeOutFN==0)
    VolumeOutFN=[];
  else  
    VolumeOutFN=[VolumeOutPN VolumeOutFN];
  end
end
%
[RoiVolume,RoiHdr]=ReadAnalyzeImg(voxvoiInFN);
pos=find(RoiVolume~=0);
RoiVolume(pos)=RoiVolume(pos)+9; % ROI values start at 10
%
if ~isempty(VolumeGmWmFN)
  [GmWmImg,GmWmHdr]=ReadAnalyzeImg(VolumeGmWmFN);
  RoiVolume((GmWmImg(:)==0)&(RoiVolume(:)~=0))=0;  % Set BG values to zero even
                                                   % if in ROI
  RoiVolume(GmWmImg==1)=1;                         % Set CSF voxels
  RoiVolume((GmWmImg(:)==2)&(RoiVolume(:)==0))=2;  % Gray matter and not a ROI
  RoiVolume(GmWmImg==3)=3;                         % Set White matter voxels
  RoiVolume(GmWmImg==4)=4;                         % Set Fat voxels
end  
%
RoiDescription=ReadRoiDescription(voxvoiInFN);
if isempty(RoiDescription)
    for i=1:max(RoiVolume(:))
        RoiDescription{i}=sprintf('ROI %i',i);
    end
end
%
if ~isempty(VolumeOutFN)
  [pn,fn,ex]=fileparts(VolumeOutFN);
  %  
  RoiHdr.name=fn;
  RoiHdr.path=pn;
  RoiHdr.pre=16;
  RoiHdr.lim=[32767 -32768];
  RoiHdr.scale=1;
  RoiHdr.offset=0;
  RoiHdr.dim=RoiHdr.dim(1:3);
  RoiHdr.descr='voxvoi2pve: Volume containing ROIs with values 10, 11, 12, BG-0, CSF-1, GM-2, WM-3';
  [result]=WriteAnalyzeImg(RoiHdr,RoiVolume);
  %
  pid=fopen(fullfile(pn,[fn '.descr']),'w');
  if (pid == -1)
    warning('voxvoi2pve: Not possible to write file with ROI description');
  else
    fprintf(pid,'%i, "%s"\n',0,'Background');
    fprintf(pid,'%i, "%s"\n',1,'CSF');
    fprintf(pid,'%i, "%s"\n',2,'Gray matter');
    fprintf(pid,'%i, "%s"\n',3,'White matter');
    fprintf(pid,'%i, "%s"\n',4,'Fat and other tissue');
    for i=1:length(RoiDescription)
      fprintf(pid,'%i, "%s"\n',i+9,RoiDescription{i});
    end
    fclose(pid);
  end
end;


function RoiDescription=ReadRoiDescription(FileName)
%
% Function that reads a simple text file with ROI names, if available
%  should have extension ".descr"
%
[pn,fn,ext]=fileparts(FileName);
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