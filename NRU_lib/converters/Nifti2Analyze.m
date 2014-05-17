function Nifti2Analyze(FileName,Pre)
%
% Nifti2Analyze([FileName,Pre])
%
% FileName - files that should be converted (if more files given as cell array)
% Pre      - Precision of output image ('16' (unsigned int) or '32' (single pre float))
%
% This converts af Nifti file (*.nii format) to analyze format
%  a dialog box opens asking for which files to convert
%
if nargin==0
    [fn1,pn1]=uigetfile('*.nii', 'Select the files to convert', 'multiselect','on');
    %
    ButtonName = questdlg('Precision of analyze output file?', ...
        'No of bits', ...
        '16 bit int', '32 bit float', '16 bit int');
    if ~iscell(fn1)
        fn{1}=fn1;
        pn{1}=pn1;
    else
        for i=1:length(fn1)
            fn{i}=fn1{i};
            pn{i}=pn1;
        end
    end
elseif nargin==2
    if isstr(FileName)
        [pn1,fn1,ext]=fileparts(FileName);
        fn{1}=[fn1 ext];
        pn{1}=pn1;
    elseif iscell(FileName)
        for i=1:length(FileName)
            [pn1,fn1,ext]=fileparts(FileName{i});
            fn{i}=[fn1 ext];
            pn{i}=pn1;
        end
    else
        warndlg('Files have to be specified in string or a cell array of strings','Nifti2Analyze');
    end
    if Pre==16
        ButtonName='16 bit int';
    elseif Pre==32
        ButtonName='32 bit float';
    else
        warndlg('Precision has to 16 or 32','Nifti2Analyze');
    end
else
    warndlg('No files specified for conversion','Nifti2Analyze');
end
%
for i=1:length(fn)
    niimg=load_nii(fullfile(pn{i},fn{i}));
    hdr=ReadAnalyzeHdr(fullfile(pn{i},fn{i}));
    hdr.origin=[0 0 0];
    hdr.path=pn{i};
    [pntmp,fntmp,ext]=fileparts(fn{i});
    hdr.name=fntmp;
    img=niimg.img;
    
    switch ButtonName,
        case '16 bit int',
            disp('Saved as 16 bit integer analyze file');
            if hdr.scale==0
                MaxAbs=double(max(abs(img(:))));
                img=double(img)/MaxAbs*32767;
                hdr.scale=MaxAbs/32767;
            else
                img=img*hdr.scale;
                MaxAbs=double(max(abs(img(:))));
                img=double(img)/MaxAbs*32767;
                hdr.scale=MaxAbs/32767;
            end
            hdr.lim=[32767 -32768];
            hdr.pre=16;
        case '32 bit float',
            disp('Saved as 32 bit float analyze file.');
            if hdr.scale~=0
                img=img*hdr.scale;
            end
            hdr.scale=1;
            hdr.lim=[0 0];
            hdr.pre=32;
        otherwise
            error('Undefined number of bits');
    end % switch
    
    WriteAnalyzeImg(hdr,img);
end
