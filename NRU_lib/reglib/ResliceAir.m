function message=ResliceAir(Struct,method,sincparms);
%
% function ResliceAir(Struct,[method]);
%
%   Function to reslice an Analyze image using
%   affine 12-parameter transformation matrix
%   using Roger Woods Air 3.0 'reslice'. If reslice
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
%            'linear','nearest','sinc' When 'sinc' is specified,
%            the third input parameter 'sincparms' must also be
%            specified. sincparms is a Struct with member SincSize
%            - See 'reslice' (unix command)
%
%   Warning: Output is written to hdr0.name without checking.
%   Checking should be done beforehand, e.g. using uiputfile.
%   hdr.origin information is assumed correct.
%
%   Note: reslice supports more interpolation options than this
%   wrapper. To utilise these, write an Air file using SaveAir,
%   and run 'reslice/reslice.tcl' manual on this file.
%
%   PW, NRU, 2001
%
% RESLICEDESC reslice (Air 3.0)
%
% Updates:
% Temporary file writing changed (did not work properly under linux). 161203TR
% 4D-image handling fixed (.tim file, hdrI.path & hdrO.path taken into account). 171203TR

global DEF_ENDIAN;
global NRU_FORMAT;

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
% Is reslice somewhere on the path?
[stat,output]=unix('which reslice');
if not(stat==0)
    % Revert to simple matlab interp routine:
    disp(sprintf(['Warning: reslice is not present in your '...
        'unix path.\n Reverting to Reslice().\n']));
    if strcmp(method,'sinc')
        method=linear;
        disp(sprintf(['Warning: reslice is not present in your '...
            'unix path.\n Replacing ''sinc'' interpolation' ...
            ' by ''linear''.\n']));
    end
    message=Reslice(Struct,method)
else
    Dim=1;
    if length(Struct.hdrI.dim)==3 | ...
            (length(Struct.hdrI.dim)==4 & Struct.hdrI.dim<2)
        Struct.imgI=ReadAnalyzeImg(fullfile(Struct.hdrI.path,Struct.hdrI.name),'raw');
        Struct.imgI=reshape(Struct.imgI,Struct.hdrI.dim');
        Struct.imgI=permute(Struct.imgI,[2 1 3]);
        Dim=1;
    else
        Dim=Struct.hdrI.dim(4);
    end
    if Dim==1 % Simple, only one frame
        % We reslice by writing a temporary air file.
        % Minor adjustments must be made to hdr's:
        % Make sure that the filenames are given with path
        if isempty(strfind(Struct.hdrI.name),'/')
            Struct.hdrI.name=fullfile(Struct.hdrI.path,Struct.hdrI.name);
        end
        if isempty(strfind(Struct.hdrO.name,'/'))
            Struct.hdrO.name=fullfile(Struct.hdrO.path,Struct.hdrO.name);
        end
        if isempty(strfind(Struct.hdrI.name,'.'))
            Struct.hdrI.name=[Struct.hdrI.name '.img'];
        end
        if isempty(strfind(Struct.hdrO.name,'.'))
            Struct.hdrO.name=[Struct.hdrO.name '.img'];
        end
        Struct.descr='Called from ResliceAir';
        %This is where the endianness can optionally be controlled:
        if isempty(DEF_ENDIAN)
            Struct.endian='ieee-be';
        else
            Struct.endian=DEF_ENDIAN;
        end
        if isempty(NRU_FORMAT)
            Struct.nruformat=0;
        else
            Struct.nruformat=NRU_FORMAT;
        end
        %[stat,airfile]=unix('mktemp');
        [tmp,airfile]=fileparts(tempname);
        airfile=fullfile(TEMP_AREA,[airfile '.air']);
        SaveAir(airfile,Struct);
        
        % What interpolation method was specified?
        if strcmp(method,'sinc')
            if nargin==2
                error(['Wrong number of input parameters! When sinc interpolation is specified, a struct with' ...
                    ' sinc factors and sizes is needed! ']);
            else
                if isfield(sincparms,'SincSize')
                    SincSize=reshape(sincparms.SincSize,1,3);
                    IntString=[ ' 5 ' num2str(SincSize)];
                else
                    error(['sincparms struct is not correctly formatted! see help ResliceAir.']);
                end
            end
        elseif strcmp(method,'linear')
            IntString=' 1 ';
        elseif strcmp(method,'nearest');
            IntString=' 0 ';
        else
            error('Illegal interpolation method specified');
        end
        
        % Contruct a suitable unix command string:
        s = ['reslice ' airfile ' ' Struct.hdrO.name ' -k -n ' ...
            IntString ' -o'];
        [stat,output]=unix(s);
        if not(stat==0)
            error(sprintf(['Error during call to reslice: \n' output]));
            message='ResliceWarp terminated in error';
        else
            message=['Output written to ' Struct.hdrO.name];
            tmphdr1=ReadAnalyzeHdr(Struct.hdrO.name);
            tmphdr2=ReadAnalyzeHdr(Struct.hdrI.name);
            InStruct.hdrO.endian=tmphdr1.endian;
            InStruct.hdrO.scale=tmphdr2.scale;
            WriteAnalyzeHdr(InStruct.hdrO);
        end
        unix(['rm ' airfile]);
    else
        % Multi-frame data. Using Dyn2Frames / Frames2Dyn and recursive
        % calling of ResliceAir
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
            TmpStruct.hdrI.dim=TmpStruct.hdrI.dim(1:3);
            TmpStruct.hdrO.dim=TmpStruct.hdrO.dim(1:3);
            [tPath,tFile]=fileparts(File);
            for j=1:Dim
                jstr=sprintf('%02i',j);
                TmpStruct.hdrI.name=[tFile '_f' jstr];
                TmpStruct.hdrI.path=tPath;
                TmpStruct.hdrO.name=['r_' tFile '_f' jstr];
                TmpStruct.hdrO.path=tPath;
                disp(['Reslicing frame ' num2str(j) ' of ' num2str(Dim)]);
                ResliceAir(TmpStruct);
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
                %WriteAnalyzeHdr(InStruct.hdrO); %Hdr is written by convertFrames2Dyn 171203TR
            else
                error(['Final mv failed: ' output ' ' output1]);
            end
        else
            error(['Link creation failed: ' output ' ' output1]);
        end
    end
    
end
