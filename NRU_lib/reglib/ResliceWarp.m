function message=ResliceWarp(Struct,method,sincparms);
%
% function ResliceWarp(Struct,[method]);
%
%   Function to reslice an Analyze image using
%   affine 12-parameter transformation matrix
%   using Ulrik Kjems' warp_reslice. If warp_reslice
%   is not found on path, the replacement routine
%   Reslice is called
%
% Inputs:
%
%   Struct has the fields
%   hdrI - input file Analyze header
%   hdrO - output file Analyze header
%   A - 12 parm. affine transformation matrix
%       for application xyzO=A*xyzI. A is in
%       real world (mm) coordinates.
%
%   method - defines what interpolation method to use. If none
%            is given, 'linear' is assumed. Allowed methods are
%            'linear','nearest','sinc'
%
%   sincparms - only used/needed in conjunction with method 'sinc'.
%               Struct with 2 members:
%               SincSize and SincFactor. For help - see
%               warp_reslice -h
%
%   Warning: Output is written to hdr0.name without checking.
%   Checking should be done beforehand, e.g. using uiputfile.
%   hdr.origin information is assumed correct. If method 'sinc' is
%   specified, and warp_reslice is not on your unix path, 'linear'
%   interpolation will be used during call to Reslice
%
%   PW, NRU, 2001
%
% RESLICEDESC warp_reslice (U. Kjems, DTU)
%
% Updates:
% Temporary file writing changed (did not work properly under linux). 161203TR
% 4D-image handling fixed (.tim file, hdrI.path & hdrO.path taken into account). 171203TR

TEMP_AREA=tempdir; %Get OS tempdir
if isempty(TEMP_AREA)
    TEMP_AREA=Struct.hdrO.path;
end
%Remove fileseperator in end of path
if strcmp(TEMP_AREA(end),filesep), TEMP_AREA=TEMP_AREA(1:(end-1)); end;

%Init error message
message='';

if nargin<1
    error('Incorrect number of input parameters');
elseif nargin==1 % no interpolation method specified, using linear
    method='linear';
    % Is this actually a call to determine interpolation methods
    % available?
    if ischar(Struct)
        if strcmp(Struct,'init');
            message={'linear','nearest','sinc'};
            return
        else
            error(['Input argument ''' Struct ''' not understood!']);
        end
    end
end
InStruct=Struct;
% Is warp_reslice somewhere on the path?
[stat,output]=unix('which warp_reslice');
if not(stat==0)
    % Revert to simple matlab interp routine:
    disp(sprintf(['Warning: warp_reslice is not present in your '...
        'unix path.\n Reverting to Reslice().\n']));
    if strcmp(method,'sinc')
        method=linear;
        disp(sprintf(['Warning: warp_reslice is not present in your '...
            'unix path.\n Replacing ''sinc'' interpolation' ...
            ' by ''linear''.\n']));
    end
    message=Reslice(Struct,method)
else
    Dim=1;
    if all(Struct.hdrI.origin==0)
        Struct.hdrI.origin=Struct.hdrI.origin+1;
    end
    if all(Struct.hdrO.origin==0)
        Struct.hdrO.origin=Struct.hdrO.origin+1;
    end
    % warp_reslice uses c-style indices in 'origin' field, and uses
    % inverse, voxel coordinate system.
    Struct.hdrI.origin=Struct.hdrI.origin-1;
    Struct.hdrO.origin=Struct.hdrO.origin-1;
    A=inv(tala2voxa(Struct.A,Struct.hdrI,Struct.hdrO));
    
    % What interpolation method was specified?
    if strcmp(method,'sinc')
        if nargin==2
            error(['Wrong number of input parameters! When sinc interpolation is specified, a struct with' ...
                ' sinc factors and sizes is needed! ']);
        else
            if isfield(sincparms,'SincFac') & isfield(sincparms,'SincSize')
                SincFac=reshape(sincparms.SincFac,1,3);
                SincSize=reshape(sincparms.SincSize,1,3);
                IntString=[' -q ' num2str(SincFac) ' ' num2str(SincSize)];
            else
                error(['sincparms struct is not correctly formatted! see help ResliceWarp.']);
            end
        end
    elseif strcmp(method,'linear')
        IntString=' -l ';
    elseif strcmp(method,'nearest');
        IntString=' -n ';
    else
        error('Illegal interpolation method specified');
    end
    if length(Struct.hdrI.dim)==3 | ...
            (length(Struct.hdrI.dim)==4 & Struct.hdrI.dim<2)
        Struct.imgI=ReadAnalyzeImg(Struct.hdrI.name,'raw');
        Struct.imgI=reshape(Struct.imgI,Struct.hdrI.dim');
        Struct.imgI=permute(Struct.imgI,[2 1 3]);
        Dim=1;
    else
        Dim=Struct.hdrI.dim(4);
    end
    
    if Dim==1 % Simple, only one frame
        % Make sure that the filenames are given with path
        if isempty(strfind(Struct.hdrI.name,'/'))
            Struct.hdrI.name=fullfile(Struct.hdrI.path,Struct.hdrI.name);
        end
        if isempty(strfind(Struct.hdrO.name,'/'))
            Struct.hdrO.name=fullfile(Struct.hdrO.path,Struct.hdrO.name);
        end
        % Contruct a suitable unix command string:
        % Note: warp_reslice needs hdr info in CM not MM
        s = ['warp_reslice -i std -j ' Struct.hdrI.name ' ' IntString ' -z ' num2str(Struct.hdrO.dim(1)) ' ' ...
            num2str(Struct.hdrO.dim(2)) ' ' num2str(Struct.hdrO.dim(3)) ...
            ' -c ' num2str(Struct.hdrO.siz(1)/10) ' ' num2str(Struct.hdrO.siz(2)/10) ' '...
            num2str(Struct.hdrO.siz(3)/10) ' -T ' num2str(Struct.hdrO.origin(1)) ' ' ...
            num2str(Struct.hdrO.origin(2)) ' ' num2str(Struct.hdrO.origin(3)) ];
        
        s = [s  ' -g ''' num2str(A(1,:)) ' ' num2str(A(2,:)) ' ' ...
            num2str(A(3,:)) ' ' num2str(A(4,:)) '''' ' ' Struct.hdrO.name];
        
        [stat,output]=unix(s);
        
        if not(stat==0)
            error(sprintf(['Error during call to warp_reslice: \n' output]));
            message='ResliceWarp terminated in error';
        else
            message=['Output written to ' Struct.hdrO.name];
            WriteAnalyzeHdr(InStruct.hdrO);
        end
    else
        % Multi-frame data. Using Dyn2Frames / Frames2Dyn and recursive
        % calling of ResliceWarp
        TmpStruct=Struct;
        File=tempname;
        [tmp,File]=fileparts(File);
        File=[TEMP_AREA '/' File];
        
        %Changed to copy in case TEMP_AREA=hdrI.path=hdrO.path
        [status,output]=unix(['cp ' fullfile(Struct.hdrI.path,[Struct.hdrI.name '.hdr ']) File '.hdr']);
        [status1,output1]=unix(['cp ' fullfile(Struct.hdrI.path,[Struct.hdrI.name '.img ']) File '.img']);
        if status==0 & status1==0
            PW=pwd;
            cd(TEMP_AREA);
            disp('Splitting the data into frames...');
            ConvertDyn2Frames(File)
            TmpStruct.hdrI.dim(4)=[];
            TmpStruct.hdrO.dim(4)=[];
            [tPath,tFile]=fileparts(File);
            for j=1:Dim
                if j<10
                    jstr=['0' num2str(j)];
                else
                    jstr=num2str(j);
                end
                TmpStruct.hdrI.name=[File '_f' jstr];
                TmpStruct.hdrO.name=[tPath '/r_' tFile '_f' jstr];
                disp(['Reslicing frame ' num2str(j) ' of ' num2str(Dim)]);
                ResliceWarp(TmpStruct);
            end
            [tPath,tFile]=fileparts(File);
            disp('Collecting the resliced frames...');
            ConvertFrames2Dyn(['r_' tFile '_f01']);
            % Move the resulting file to original, wanted place
            cd(PW);
            Name=Struct.hdrO.name;
            Path=Struct.hdrO.path;
            [status,output]=unix(['mv ' TEMP_AREA '/r_' tFile '.hdr ' ...
                fullfile(Path,Name) '.hdr']);
            [status1,output1]=unix(['mv ' TEMP_AREA '/r_' tFile '.img ' ...
                fullfile(Path,Name) '.img']);
            if status==0 & status1==0
                %Also copy NRU timefile if exist
                if exist(fullfile(Struct.hdrI.path,[Struct.hdrI.name,'.tim']))
                    [status2,output2]=copyfile(fullfile(Struct.hdrI.path,[Struct.hdrI.name,'.tim']), fullfile(Path,[Name,'.tim']),'f');
                end
                
                % Do cleanup
                unix(['rm ' File '_f*']);
                unix(['rm ' TEMP_AREA '/r_' tFile '*']);
                unix(['rm ' File '*']);
                %WriteAnalyzeHdr(InStruct.hdrO); Hdr is written by convertFrames2Dyn. 171203TR
            else
                error(['Final mv failed: ' output ' ' output1]);
            end
        else
            error(['Link creation failed: ' output ' ' output1]);
        end
    end
end
