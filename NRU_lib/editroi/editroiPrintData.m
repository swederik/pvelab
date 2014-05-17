function Data=editroiPrintData(VolumeFile,VoiFile,VoiVolume,VoiDescription,NoVoiDescription,ResultsFile,GM_WM_File,Threshold,AbsThres)
%
% editroiPrintData(VolumeFile,VoiFile,VoiVolume,VoiDescription,NoVoiDescription,ResultsFile,GM_WM_File,Threshold,AbsThres)
%
% Function that extract data and prints results in a standardised way
%
% VolumeFile - Cell rray with name of files to extract data from
% VoiFile - Name of file where VOI's are coming from (only used for
%               documentation purposes
% VoiVolume  - Volume of same size as the ones in each VolumeFile with
%              labeling 1,2,3,... for each VOI
% VoiDescription - Cell array with name (text) for VOI's
% NoVoiDescription - Text that should be used for VOI voxels not included
%                in one of the VOI's
% ResultsFile - Txt file with result of VOI extraction, can be
%                  empty, then only results are returned
% GM_WM_File - Segmentation for each voxel (0 - none brain, 1 - CSF, 2 -GM,
%              3- WM, 4 - Fat)
% Threshold  - Fractile of voxel values where voxels below this value are
%               ignored when calculating mean (default is 0%)
% AbsThres   - Absolut threshold value. If this value is given then highest of this 
%               and Threshold is used
%
if ~isempty(ResultsFile)
    pid=fopen(ResultsFile,'w');
    if (pid==-1)
        error('Not possible to open results file');
    end
end
%
if ~iscell(VoiVolume)
    dd=VoiVolume;
    clear('VoiVolume');
    VoiVolume{1}=dd;
    clear('dd');
end
%
for m=1:length(VolumeFile)
    fprintf('Extracting data from: %s\n',VolumeFile{m});
    vv=version;
    if (str2num(vv(1))>6)  % Version 7 or more
       [img,hdr]=ReadAnalyzeImg(VolumeFile{m},'raw');
       if isinteger(img)
          img=single(img);
       end
    else
       [img,hdr]=ReadAnalyzeImg(VolumeFile{m});
    end
    img=(img-hdr.offset)*hdr.scale;
    img=reshape(img,hdr.dim');
    %
    % Calculate fractile for PET images
    %
    if (ndims(img)==4)
        imgTmp=sum(img,4);
    else
        imgTmp=img;
    end
    %
    if (Threshold==0)&&(AbsThres==-Inf)
        PETlim=min(imgTmp(:))-1;
        fprintf(' No threshold used for PET image\n');
    else
        PETlim=max([fractile(imgTmp(:),Threshold) AbsThres]);
        fprintf(' Threshold used for mean PET image: %e\n',PETlim);
    end
    %
    if ~isempty(GM_WM_File)
        [GM_WM_img,GM_WM_hdr]=ReadAnalyzeImg(GM_WM_File);
        GM_WM_img(GM_WM_img>=10)=2;
        MaxClass=6;
    else
        MaxClass=1;
    end
    %
    Txt{1}='Total VOI voxels value:';
    Txt{2}='Gray matter (GM) VOI voxels value:';
    Txt{3}='White matter (WM) VOI voxels value:';
    Txt{4}='Cerebrospinal fluid (CSF) VOI voxels value:';
    Txt{5}='Background VOI voxels value:';
    Txt{6}='Fat VOI voxels value:';
    %
    for i=1:length(VoiDescription)+1
        if (i>length(VoiDescription))
            BitVol=ones(size(VoiVolume{1}(:)));
        else
            no=ceil(double(i)/64);
            bit=rem(double(i-1),64)+1;
            BitVol=bitget(VoiVolume{no}(:),bit);
        end
        for j=1:MaxClass
            switch j
                case 1   % All ROI voxels
                    pos=find(BitVol&(imgTmp(:)>PETlim));
                case 2   % Gray matter ROI voxels
                    pos=find(BitVol&(GM_WM_img(:)==2)&(imgTmp(:)>PETlim));
                case 3   % White matter ROI voxels
                    pos=find(BitVol&(GM_WM_img(:)==3)&(imgTmp(:)>PETlim));
                case 4   % CSF ROI voxels
                    pos=find(BitVol&(GM_WM_img(:)==1)&(imgTmp(:)>PETlim));
                case 5   % Background ROI voxels
                    pos=find(BitVol&(GM_WM_img(:)==0)&(imgTmp(:)>PETlim));
                case 6   % Fat ROI voxels
                    pos=find(BitVol&(GM_WM_img(:)==4)&(imgTmp(:)>PETlim));
                otherwise
                    disp('Undefined data');
            end
            for k=1:size(img,4)
                if ~isempty(pos)
                    imgTmpFr=img(:,:,:,k);
                    if (i>length(VoiDescription))
                        DataTmp{m}(i,j).Name=NoVoiDescription;
                    else
                        DataTmp{m}(i,j).Name=VoiDescription{i};
                    end
                    DataTmp{m}(i,j).NoOfVoxels=length(pos);
                    DataTmp{m}(i,j).Volume=length(pos)*prod(hdr.siz(1:3))/1000; %Calculated in cc
                    DataTmp{m}(i,j).Mean(k)=mean(imgTmpFr(pos));
                    DataTmp{m}(i,j).Std(k)=std(imgTmpFr(pos));
                    DataTmp{m}(i,j).Median(k)=median(imgTmpFr(pos));
                    DataTmp{m}(i,j).Min(k)=min(imgTmpFr(pos));
                    DataTmp{m}(i,j).Max(k)=max(imgTmpFr(pos));
                else
                    if (i>length(VoiDescription))
                        DataTmp{m}(i,j).Name=NoVoiDescription;
                    else
                        DataTmp{m}(i,j).Name=VoiDescription{i};
                    end
                    DataTmp{m}(i,j).NoOfVoxels=0;
                    DataTmp{m}(i,j).Volume=0;
                    DataTmp{m}(i,j).Mean(k)=0;
                    DataTmp{m}(i,j).Std(k)=0;
                    DataTmp{m}(i,j).Median(k)=0;
                    DataTmp{m}(i,j).Min(k)=0;
                    DataTmp{m}(i,j).Max(k)=0;
                end
            end
        end
    end
    %
    if exist('pid','var') && ~(pid==-1)
        %
        fprintf(pid,'#Date: %s\n',datestr(clock));
        if ispc
            fprintf(pid,'#User: %s\n',getenv('USERNAME'));
            fprintf(pid,'#Host: %s\n',getenv('COMPUTERNAME'));
        else
            fprintf(pid,'#User: %s\n',getenv('USER'));
            fprintf(pid,'#Host: %s\n',getenv('HOST'));
        end
        fprintf(pid,'#Comp: %s\n',computer);
        fprintf(pid,'\n');
        %
        fprintf(pid,'Data extracted from file: %s\n',VolumeFile{m});
        fprintf(pid,'using ROI definition: %s\n',VoiFile);
        if ~isempty(GM_WM_File)
            fprintf(pid,'and GM/WM segmentation from: %s\n',GM_WM_File);
        end
        if Threshold==0
            fprintf(pid,'No threshold used at PET voxels\n');
        else
            fprintf(pid,'A (%3.2f%%) threshold of %f used at PET voxels\n',Threshold,PETlim);
        end
        %
        NoOfFrames=length(DataTmp{m}(1,1).Mean);
        %
        for j=1:MaxClass
            if ~isempty(Txt{j})
                fprintf(pid,'\n\n\n%s\n\n',Txt{j});
                fprintf(pid,'\t');
                for i=1:size(DataTmp{m},1)
                    fprintf(pid,'%s\t',DataTmp{m}(i,j).Name);
                end
                fprintf(pid,'\n');
                %
                for l=1:length(fieldnames(DataTmp{m}))-2
                    switch l
                        case 1,
                            fprintf(pid,'Volume (cc)\t');
                        case 2,
                            fprintf(pid,'Mean\t');
                        case 3,
                            fprintf(pid,'Std\t');
                        case 4,
                            fprintf(pid,'Median\t');
                        case 5,
                            fprintf(pid,'Min\t');
                        case 6,
                            fprintf(pid,'Max\t');
                        otherwise
                            error('Too many different classes');
                    end
                    if (NoOfFrames~=1) && (l~=1)
                        fprintf(pid,'\n');
                    end
                    for k=1:NoOfFrames   % Loop over frames
                        if (NoOfFrames~=1) && (l~=1)
                            fprintf(pid,'frame %i:\t',k);
                        end
                        for i=1:size(DataTmp{m},1)
                            switch l
                                case 1,
                                    if (k==1)
                                        fprintf(pid,'%i\t',DataTmp{m}(i,j).Volume(k));
                                    end
                                case 2,
                                    fprintf(pid,'%i\t',DataTmp{m}(i,j).Mean(k));
                                case 3,
                                    fprintf(pid,'%i\t',DataTmp{m}(i,j).Std(k));
                                case 4,
                                    fprintf(pid,'%i\t',DataTmp{m}(i,j).Median(k));
                                case 5,
                                    fprintf(pid,'%i\t',DataTmp{m}(i,j).Min(k));
                                case 6,
                                    fprintf(pid,'%i\t',DataTmp{m}(i,j).Max(k));
                                otherwise
                                    error('Two many different classes');
                            end
                        end
                        if (l~=1)||((l==1)&&(k==1))
                            fprintf(pid,'\n');
                        end
                    end
                end
                %
            end
        end
    end
end
%
if exist('pid','var') && ~(pid==-1)
    %
    fclose(pid);
    %
end
%
if (length(DataTmp)==1)
    Data=DataTmp{1};
else
    Data=DataTmp;
end
    

