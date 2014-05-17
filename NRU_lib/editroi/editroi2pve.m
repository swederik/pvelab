function [Result,RoiVolume,RoiDescription]=editroi2pve(EditroiInFN,VolumeInFN,VolumeGmWmFN,VolumeOutFN)
%  
%  Convert a set of ROIs defined in a editroi file into a volume of ROIs,
%  with thw ROI numbered as 10, 11, 12. Further if a GM_WM file is specified
%  only the GM voxels in each ROI will be given the values. Outside the ROIs
%  the voxels will be given the values 0 - BG, 1 - CSF, 2 - GM, 3 - WM, 4 -
%  Fat. 
%
%  [Result,RoiVolume,RoiDescription]=
%             editroi2pve([EditroiInFN,VolumeInFN,VolumeGmWmFN,VolumeOutFN])
%
%    EditroiInFN  - name of editroi file with definition of ROI's to create
%                    volume from (eventually this can be a ROI structure)
%    VolumeInFN   - Name of header file defining the size of the volume that
%                    should be created from the editroi file (could also be
%                    structure with the information (as returned by
%                    ReadAnalyzeHdr) 
%    VolumeGmWmFN   - Name of the gray/white matter file (should have same
%                    size as VolumeIn. If emty no classification is used
%    VolumeOutFN  - Name of analyze file for writing the ROI volume into. A
%                    file with the name "<VolumeOutFN>.descr" is also
%                    created containing two columns (RoiNo, RoiName) (if not
%                    specified nothing is saved)
%
%    Hdr          - If analyze structure header is used as input argument
%                    then the information in this is used for deciding
%                    size of volume created
%
%    Result       - Error argument (1 for success, 0 for failure)
%    RoiVolume    - Volume with ROIs
%    RoiDescription - Cell aray with names of ROIs
%
% CS, 030224, Vers. 1
%
Result=1;
if (nargin ~= 0) && (nargin ~=4)
  error('editroi2pve function has to be called with either 0 or 4 right handside arguments');
end
if (nargout > 3)
  error('editroi2analyze function has to be called with 0 to 3 left handside arguments');
end
%
if (nargin == 0)
  [EditroiInFN, EditroiInPN] = ...
    uigetfile('*.mat', 'Name of editroi file to transform');
  if (EditroiInFN==0)
    error('Editroi file has to be defined');
  end
  EditroiInFN=[EditroiInPN EditroiInFN];
  [VolumeInFN, VolumeInPN] = ...
    uigetfile('*.hdr', 'Header file defining size of output volume');
  if (VolumeInFN==0)
    error('Header file defining size of volume has to selected');
  end
  VolumeInFN=[VolumeInPN VolumeInFN];
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
[Result,RoiVolume,RoiDescription]=editroi2analyze(EditroiInFN,VolumeInFN);
pos=find(RoiVolume~=0);
RoiVolume(pos)=RoiVolume(pos)+9; % ROI values start at 10
%
if ~isempty(VolumeGmWmFN)
  [GmWmImg,GmWmHdr]=ReadAnalyzeImg(VolumeGmWmFN);
  pos=find((GmWmImg(:)==0)&(RoiVolume(:)~=0));  % Set BG values to zero even
                                                % if in ROI
  RoiVolume(pos)=0;
  pos=find(GmWmImg==1);                         % Set CSF voxels
  RoiVolume(pos)=1;
  pos=find((GmWmImg(:)==2)&(RoiVolume(:)==0));  % Gray matter and not a ROI
  RoiVolume(pos)=2;
  pos=find(GmWmImg==3);                         % Set White matter voxels
  RoiVolume(pos)=3;
  pos=find(GmWmImg==4);                         % Set Fat voxels
  RoiVolume(pos)=4;
end  
%
if ~isempty(VolumeOutFN)
  if (isstruct(VolumeInFN))
    RoiHdr=VolumeInFN;
  else  
    RoiHdr=ReadAnalyzeHdr(VolumeInFN);
  end
  %
  [pn,fn,ex]=fileparts(VolumeOutFN);
  if isempty(pn)
    pn='.';
  end  
  %  
  RoiHdr.name=fn;
  RoiHdr.path=pn;
  RoiHdr.pre=16;
  RoiHdr.lim=[32767 -32768];
  RoiHdr.scale=1;
  RoiHdr.offset=0;
  RoiHdr.dim=RoiHdr.dim(1:3);
  RoiHdr.descr='editroi2pve: Volume containing ROIs with values 10, 11, 12, BG-0, CSF-1, GM-2, WM-3';
  [result]=WriteAnalyzeImg(RoiHdr,RoiVolume);
  %
  pid=fopen([pn filesep fn '.descr'],'w');
  if (pid == -1)
    warning('Not possible to write file with ROI description');
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

















