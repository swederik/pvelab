function [img,hdr]=LoadAnalyze(varargin)
%
% function [img,hdr]=LoadAnalyze([name],['single'])
%
% Wrapper for ReadAnalyze routines, with checking for 4d datasets, etc.
% img is always loaded in 'raw' format if matlab version is above
% 6. hdr is a standard analyze header, exept that origin, scale and  
% offset are fixed, and that hdr.name is the full filename
% including path. If called without input  parameters, uigetfile is 
% called for selection. 
%  
% The output parameters are hdr (Analyze header struct) and img,
% the image data. If the datafile is 4-dimensional, the user is
% prompted to load either 
%
% 1) One frame
% 2) All frames (img becomes a cell array)
% 3) Mean of frames within an interval.
% 
% If 'single' was specified during the call, option 2) is NOT used.
%
% PW, NRU, 2001
%
% 181203TR: Added support for 8bit and 32bit files
% 221203TR: Hdr.dim output is consistently delivered in output image dimensions. 

if nargin==0
    % No filename given - select an Analyze file!
    [img,hdr]=LoadAnalyze('select');
else
    % Task is always first parameter:
    task=varargin{1};
    if ischar(task)
        switch task
            case 'single'
                % Single frame - no filename given
                [img,hdr]=LoadAnalyze('select','single');
            case 'select'
                % Selection needed.
                [File Path]=uigetfile('*.hdr','Select Analyze header');
                if File==0
                    disp('Load Cancelled');
                    img=[];
                    hdr=[];
                    return;
                else
                    % Is a second parameter given?
                    single='';
                    if nargin==2
                        single=varargin{2};
                    end
                    [img,hdr]=LoadAnalyze([Path File],single);
                end
            otherwise
                % Task not parsable, must be a filename
                [Path File Ext]=fileparts(task);
                task=[Path '/' File '.hdr'];
                if exist(task)==2
                    % A valid filename!
                    [Path File Ext]=fileparts(task);
                    if isempty(Path)
                        Path=pwd;
                    end
                    hdrfile=[Path '/' File '.hdr'];
                    imgfile=[Path '/' File '.img'];
                    if exist(hdrfile)==2
                        if exist(imgfile)==2
                            % Were more parameters given?
                            single='';
                            if nargin==2
                                single=varargin{2};
                            end
                            [img,hdr]=LoadData(hdrfile,single);
                        else
                            error([imgfile ' does not exist!']);
                        end
                    else
                        error([hdrfile ' does not exist!']);
                    end
                else
                    error(['Input parameter ' task ' not understood, or not a filename']);
                end
        end
    else
        % First parm not a string!
        error('First input parameter should always be a string!');
    end
end

function [img,hdr]=LoadData(valid_file,single)
% Loads the actual data
[Path File Ext]=fileparts(valid_file);
hdr=ReadAnalyzeHdr(valid_file);
% Fix filename:
hdr.name=[Path '/' File];
% Do some error checking on the header:
if all(hdr.origin==0) % Not SPM Analyze
    hdr.origin=hdr.origin+1;
end
if hdr.scale==0 % No scale in header, set no scaling (1)
    hdr.scale=1;
end
mv=version;
if str2num(mv(1))<6
    RawFlag=0;
else
    RawFlag=1;
end
if length(hdr.dim)==4 & hdr.dim(4)>1 % Multi-frame 
    % Do selection of single frame / sum of frames / all frames
    if strcmp(single,'all')
      Ok=1;
      Choice=1;   %All frames
      lc=hdr.dim(4)+1;
    else
      Choices=cell(2+hdr.dim(4),1);
      lc=length(Choices);
      Choices{1}='Mean from frame N to M';
      Choices{lc}='All frames (cell array)';
      Choices(2:length(Choices)-1)=num2cell(1:hdr.dim(4));
      if strcmp(single,'single')
        Choices=Choices(1:lc-1);
      end
      for j=2:lc-1
        Choices{j}=['Frame no. ' num2str(Choices{j})];
      end
      [Choice,Ok]=listdlg('PromptString','Frame Selection:','SelectionMode','single','ListString',Choices);
    end
    if Ok==0
        disp('4D Load Cancelled');
        img=[];
        hdr=[];
    else
        if Choice>1 & Choice < lc
            if RawFlag==1
                img=ReadAnalyzeImg([Path '/' File],[':' num2str(Choice-1)],'raw');
            else
                img=ReadAnalyzeImg([Path '/' File],[':' num2str(Choice-1)]);
            end
            hdr.dim=hdr.dim(1:3);
        elseif Choice==lc
            for j=1:hdr.dim(4)
                if RawFlag==1
                    img{j}=ReadAnalyzeImg([Path '/' File],[':' num2str(j)],'raw');
                else
                    img{j}=ReadAnalyzeImg([Path '/' File],[':' num2str(j)]);
                end
            end
            hdr.dim=hdr.dim(1:3);
        elseif Choice==1
            if not(hdr.pre==16 | hdr.pre==8 | hdr.pre==32)
                error('Can only handle 8 bit, 16 bit signed and 32 bit data');
            else
                if strcmp(single,'all')
                  range(1)=1;
                  range(2)=hdr.dim(4);
                else
                  prompt={'Enter first frame:','Enter last frame:'};
                  def={'1',num2str(hdr.dim(4))};
                  dlgTitle='Mean of frames ';
                  lineNo=1;
                  answer=inputdlg(prompt,dlgTitle,lineNo,def);
                  if isempty(answer)
                    answer=def;
                  end
                  range(1)=str2num(answer{1});
                  range(2)=str2num(answer{2});
                  if isempty(range(1))
                    range(1)=1;
                  end
                  if isempty(range(2))
                    range(2)=hdr.dim(4);
                  end
                end
                NumberOfFrames=range(2)-range(1)+1;
                for j=range(1):range(2)
                    disp(['Working on frame: ' num2str(j)]);
                    if j==range(1);
                        img=double(ReadAnalyzeImg([Path '/' File],[':' num2str(j)]));
                    else
                        img=img+double(ReadAnalyzeImg([Path '/' File],[':' num2str(j)]));
                    end  
                end;	  
                if (hdr.pre==16)
                    MaxImg=max(img(:));
                    img=img*32767/MaxImg;
                    img=int16(img);
                    hdr.scale=hdr.scale*MaxImg/32767;
                    hdr.lim=[32767 -32768];
                    hdr.pre=16;
                    hdr.dim=hdr.dim(1:3);
                elseif (hdr.pre==8)
                    MaxImg=max(img(:));
                    img=img*255/MaxImg;
                    img=int8(img);
                    hdr.scale=hdr.scale*MaxImg/255;
                    
                    hdr.lim=[255 0];
                    hdr.pre=8;
                    hdr.dim=hdr.dim(1:3);
                elseif (hdr.pre==32)                    
                    img=img/NumberOfFrames;
                    img=int32(img);
                    
                    hdr.lim=[0 0];
                    hdr.pre=32;
                    hdr.dim=hdr.dim(1:3);
                end
            end
        end
    end
else % Just do raw reading of the file:
    if RawFlag==1
        img=ReadAnalyzeImg([Path '/' File],'raw');
    else
        img=ReadAnalyzeImg([Path '/' File]);
    end
end





