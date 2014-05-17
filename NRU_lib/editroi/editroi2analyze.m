function [Result,RoiVolume,RoiDescription]=editroi2analyze(EditroiInFN,VolumeInFN,VolumeOutFN,BitVol)
%
%  Convert a set of ROIs defined in a editroi file into a volume of ROIs,
%  with thw ROI numbered as 1, 2, 3, etc. and background the value 0.
%
%  [Result,RoiVolume,RoiDescription]=
%             editroi2analyze([EditroiInFN,VolumeInFN[,VolumeOutFN[,
%             BitVol]]])
%
%  [Result,RoiVolume,RoiDescription]=
%             editroi2analyze([EditroiInFN,Hdr])
%
%    EditroiInFN  - name of editroi file with definition of ROI's to create
%                    volume from (eventually this can be a ROI structure)
%    VolumeInFN   - Name of header file defining the size of the volume that
%                    should be created from the editroi file
%    VolumeOutFN  - Name of analyze file for writing the ROI volume into. A
%                    file with the name "<VolumeOutFN>.descr" is also
%                    created containing two columns (RoiNo, RoiName) (if not
%                    specified nothing is saved)
%
%    Hdr          - If analyze structure header is used as input argument
%                    then the information in this is used for deciding
%                    size of volume created
%    BitVol       - Logical variable that defines if volume should
%                    be written in bit format (Bit 1 - ROI 1, Bit 2
%                    - Roi 2)
%
%    Result       - Error argument (1 for success, 0 for failure)
%    RoiVolume    - Volume with ROIs
%    RoiDescription - Cell aray with names of ROIs
%
% CS, 021017, Vers. 1
%
Result=1;
if (nargin ~= 0) && (nargin ~=2) && (nargin ~=3) && (nargin ~=4)
    error('editroi2analyze function has to be called with either 0, 2, 3 or 4 right handside arguments');
end
if (nargout > 4)
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
    [VolumeOutFN, VolumeOutPN] = ...
        uiputfile('*.img', 'Name of file for saving output volume into');
    if (VolumeOutFN==0)
        VolumeOutFN=[];
    else
        VolumeOutFN=[VolumeOutPN VolumeOutFN];
    end
    BitVol=0;
elseif (nargin == 2)
    VolumeOutFN=[];
    BitVol=0;
end
%
if (isstruct(VolumeInFN))
    Hdr=VolumeInFN;
else
    Hdr=ReadAnalyzeHdr(VolumeInFN);
end
%
if (ischar(EditroiInFN))
    [Roi,Message]=LoadRoi(EditroiInFN,Hdr);
else
    Roi=EditroiInFN;
end
%
% Take care of 4 dimensionel headers, ignore time dimension
%
Hdr.dim=Hdr.dim(1:3);
%
[RoiVolume,RoiDescription]=Editroi2Volume(Roi,Hdr,BitVol);
%
if ~isempty(VolumeOutFN)
    [pn,fn,ex]=fileparts(VolumeOutFN);
    if isempty(pn)
        pn='.';
    end
    %
    RoiHdr=Hdr;
    RoiHdr.name=fn;
    RoiHdr.path=pn;
    if (BitVol==0)
        RoiHdr.pre=16;
        RoiHdr.lim=[32767 -32768];
    else
        RoiHdr.pre=64;
        RoiHdr.lim=[1 0];
    end
    RoiHdr.scale=1;
    RoiHdr.offset=0;
    RoiHdr.descr='Editroi2Volume: Volume containing ROIs with values 1, 2, 3';
    [result]=WriteAnalyzeImg(RoiHdr,RoiVolume);
    %
    pid=fopen([pn filesep fn '.descr'],'w');
    if (pid == -1)
        warning('Not possible to write file with ROI description');
    else
        for i=1:length(RoiDescription)
            fprintf(pid,'%i, "%s"\n',i,RoiDescription{i});
        end
        fclose(pid);
    end
end;


function [RoiVolume,RoiDescription]=Editroi2Volume(Roi,Hdr,BitVol)
%
% Function that converts an  editroi set to a volume with size as specificed in
% analyze header and same ROI values (1, 2, 3, ,4) as in editroi
% it could also be bit 1, 2, 3 ....)
%
if all(Hdr.origin==0)
    Hdr.origin=Hdr.origin+1;
end
%
RoiDescription=Roi.regionname;
%
if BitVol==0
    RoiVolume=zeros(Hdr.dim','uint32');
else
    RoiVolume=zeros(Hdr.dim','uint64');
end
%
Xaxis=((1:Hdr.dim(1))-Hdr.origin(1))*Hdr.siz(1);
Yaxis=((1:Hdr.dim(2))-Hdr.origin(2))*Hdr.siz(2);
%
if (BitVol==1)&&(length(unique(Roi.region))>64)
    error('editroi2analyze: This function can only handle files with up to 63 different ROIs for bitvol');
end
%
for i=1:length(Roi.region)
    if isempty(which('roipoly'))
        if i==1
            fprintf('Uses own 30 times slower implementation of roipoly\n');
        end
        [BW]=roipoly2(Yaxis,Xaxis,Roi.vertex{i}(:,2),Roi.vertex{i}(:,1));
    else
        if i==1
            ZeroImg=zeros(Hdr.dim(1),Hdr.dim(2));
        end
        [BW]=roipoly(Yaxis,Xaxis,ZeroImg,...
            Roi.vertex{i}(:,2),Roi.vertex{i}(:,1));
    end
    pos=find(BW~=0)+Hdr.dim(1)*Hdr.dim(2)*(Roi.relslice(i)+Hdr.origin(3)-1);
    if (BitVol==0)
        RoiVolume(pos)=Roi.region(i);
    else
        RoiVolume(pos)=bitset(RoiVolume(pos),Roi.region(i));
    end
end









