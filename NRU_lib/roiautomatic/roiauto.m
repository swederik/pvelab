function roiauto(varargin)

% This graphical user interface has been specifically designed to the
% PE2I-vs-FPCIT SPECT-project running at NRU.
%
% The GUI enables a template-based automatic delineation of the following
% eight ROIs in a given SPECT image (Analyze format):
%     - Striatum dex/sin
%     - Caudatus dex/sin
%     - Putamen dex/sin
%     - Midbrain
%     - Cerebellum (reference)
% 
% The program uses a linear transformation procedure (12-parameter affine
% transformation estimated based on the mean of AIR and FLIRT) together
% with one of three different AIR cost functions in order to normalize the
% analyzed SPECT image to a normal healthy SPECT template. The FLIRT
% routine uses always "Normalized Correlation" as cost function, whereas
% the user can choose the AIR cost function to use. Note that the AIR
% routine estimates the transformation based on a thresholded version of
% the template and patient images (threshold set at median value of each
% image). The user should always check the result of the normalization
% procedure!!!
% After the normalization, the program reslices the normalized SPECT image
% to the template and transfers the selected ROIs from the template to the
% resliced image. During the transfer process the program uses a Gaussian
% filter with a FWHM of 6x6x6 mm to smooth the transferred ROIs in the
% resliced SPECT image.
% Eventually, the user can manually correct, inspect and draw
% analysis-relevant information from the automatically delineated ROIs in
% the resliced SPECT image.
%
% PJ, NRU, 15-04-2009
%
% Revision:
% PJ, NRU, 17-06-2009       - Enabling specific choice of ROIs to include.
% PJ, NRU, 04-08-2009       - Changed so that the image is normalized to
%                             the template instead of the other way around.
% PJ, NRU, 17-11-2009       - Implemented new template with ROIs.
% PJ, NRU, 11-01-2010       - Now only using one iteration in normaliztion.
% PJ, NRU, 12-01-2010       - Now estimating normalization based on a
%                             histogram-equalized (to the template) version
%                             of the analyzed SPECT image.
% PJ, NRU, 11-03-2010       - Implemented manual ROI correction step

currentdir = pwd;
global SPECTPIPELINE;

if nargin==0
    SetupGUI;    
    SPECTPIPELINE = 0;
else
    screensize=get(0,'ScreenSize');
    switch varargin{1}
        case 'DefineTemplate'
            if not(isempty(get(findobj(gcf,'tag','templatefile'),'string')))
                path_before = fileparts(get(findobj(gcf,'tag','templatefile'),'string'));
                cd(path_before)
            end
            [tempfile,temppath] = uigetfile('*.img','Choose the normal healthy SPECT template to use');
            if not(isequal(tempfile,0)) || not(isequal(temppath,0))
                set(findobj(gcf,'tag','templatefile'),'string',[temppath tempfile])
                AddMesg('New SPECT template was selected by the user.')
            end
            
        case 'DefineImage'
            if not(isempty(get(findobj(gcf,'tag','imagefile'),'string')))
                path_before = fileparts(get(findobj(gcf,'tag','imagefile'),'string'));
                cd(path_before)
            else
                cd(currentdir)
            end
            [imgfile,imgpath] = uigetfile('*.img','Choose the SPECT image to analyze');
            if not(isequal(imgfile,0)) || not(isequal(imgpath,0))
                set(findobj(gcf,'tag','imagefile'),'string',[imgpath imgfile])
                AddMesg('A SPECT image to analyze was selected by the user.')
                cd(imgpath)
            end
            set(findobj(gcf,'tag','Button1'),'Enable','on');
            
        case 'SpectPipeline'
            % Special use of roiauto under the SpectPipeline
            FileName = varargin{2};
            set(findobj(gcf,'tag','imagefile'),'string',FileName);
            set(findobj(gcf,'tag','selectall'),'Enable','off');
            set(findobj(gcf,'tag','deselectall'),'Enable','off');
            set(findobj(gcf,'tag','Button1'),'Enable','on');
            set(findobj(gcf,'tag','Putamendex'),'Enable','off');
            set(findobj(gcf,'tag','Putamensin'),'Enable','off');
            set(findobj(gcf,'tag','Caudatusdex'),'Enable','off');
            set(findobj(gcf,'tag','Caudatussin'),'Enable','off');
            set(findobj(gcf,'tag','Reference'),'Enable','off');
            % Make sure the cost function is set to:
            % "Least Squares with Intensity Rescaling"
            set(findobj(gcf,'tag','std'),'value',0)
            set(findobj(gcf,'tag','lsd'),'value',0)
            set(findobj(gcf,'tag','lsi'),'value',1)

            SPECTPIPELINE = 1;
            
        case 'select_all'
            % Check all ROIs for inclusion
            set(findobj(gcf,'tag','Putamensin'),'value',1)
            set(findobj(gcf,'tag','Putamendex'),'value',1)
            set(findobj(gcf,'tag','Caudatussin'),'value',1)
            set(findobj(gcf,'tag','Caudatusdex'),'value',1)
            set(findobj(gcf,'tag','Reference'),'value',1)
            
        case 'deselect_all'
            % Un-check all ROIs for inclusion
            set(findobj(gcf,'tag','Putamensin'),'value',0)
            set(findobj(gcf,'tag','Putamendex'),'value',0)
            set(findobj(gcf,'tag','Caudatussin'),'value',0)
            set(findobj(gcf,'tag','Caudatusdex'),'value',0)
            set(findobj(gcf,'tag','Reference'),'value',0)
            
        case 'std'
            % Change the cost function to:
            % "Standard Deviation of Ratio Image"
            set(findobj(gcf,'tag','std'),'value',1)
            set(findobj(gcf,'tag','lsd'),'value',0)
            set(findobj(gcf,'tag','lsi'),'value',0)
            
        case 'lsd'
            % Change the cost function to:
            % "Least Squares of Difference Image"
            set(findobj(gcf,'tag','std'),'value',0)
            set(findobj(gcf,'tag','lsd'),'value',1)
            set(findobj(gcf,'tag','lsi'),'value',0)
            
        case 'lsi'
            % Change the cost function to:
            % "Least Squares with Intensity Rescaling"
            set(findobj(gcf,'tag','std'),'value',0)
            set(findobj(gcf,'tag','lsd'),'value',0)
            set(findobj(gcf,'tag','lsi'),'value',1)
            
        case 'align'
            % Define template and image to analyze
            temp_file = get(findobj(gcf,'tag','templatefile'),'string');
            img_file = get(findobj(gcf,'tag','imagefile'),'string');
            if isempty(temp_file) || strcmp(img_file,'/')
                warndlg('You have to specify two input files to continue!',...
                    'Input file error')
                return
            end
            
            if exist([fileparts(img_file),'/AutoROIs/AllROIs.mat'],'file') && nargin<3
                answer = questdlg(...
                    'This image has been analyzed earlier. What will you do?','Overwrite last analysis?',...
                    'Perform new analysis','Inspect results from last analysis','Perform new analysis');
                if not(strcmp(answer,'Perform new analysis'))
                    DataStruct.imgPET = get(findobj(gcf,'tag','templatefile'),'string');
                    DataStruct.imgMR = [fileparts(img_file) '/AutoROIs/PatientInTemplateSpace.img'];
                    
                    % Close Alignment Inspection figure, if open
                    figs=findobj('type','figure','Name','Alignment Inspection');
                    delete(figs);
                    
                    nruinspect('loaddata',DataStruct);
                    set(findobj(gcf,'type','figure'),'Name','Alignment Inspection')
                    pos = [1/4*screensize(3) 1/4*screensize(4) screensize(3)/2 screensize(4)/2];
                    set(findobj(gcf,'type','figure'),'Position',pos);
                    
                    set(findobj(findobj('tag','roiautomainwin'),'tag','Button2'),'Enable','off');
                    set(findobj(findobj('tag','roiautomainwin'),'tag','Button3'),'Enable','on');
                    set(findobj(findobj('tag','roiautomainwin'),'tag','Button4'),'Enable','on');
                    return
                else
                    rmdir([fileparts(img_file),'/AutoROIs'],'s');
                    AddMesg('********************* New analysis *********************')
                    AddMesg('All analysis files from last analysis have been deleted!')
                    
                    mkdir(fileparts(img_file),'AutoROIs');
                end
            else
                mkdir(fileparts(img_file),'AutoROIs');
            end
            
            % Give the user information about the process progress
            if strcmp(varargin{2},'inspect')
                clc
                disp('Alignment Inspection has been initiated. Please wait!')
                disp('*****************************************************')
            elseif strcmp(varargin{2},'auto_roi_delineate')
                clc
                disp('Automatic ROI Delineation has been initiated. Please wait!')
                disp('**********************************************************')
            end
            
            % Make sure that the data precision of each image is 16
            % bits/pixel. If not, make a conversion
            ConvertPrecision(temp_file,img_file)
            temp_file = get(findobj(gcf,'tag','templatefile'),'string');
            img_file = get(findobj(gcf,'tag','imagefile'),'string');
            
            % Cost function:
            if findobj(gcf,'tag','std','value',1);
                x = '1';
            elseif findobj(gcf,'tag','lsd','value',1);
                x = '2';
            elseif findobj(gcf,'tag','lsi','value',1);
                x = '3';
            end
              
            % Smoothing:
            b1 = get(findobj(gcf,'tag','bx'),'string');
            b2 = get(findobj(gcf,'tag','by'),'string');
            b3 = get(findobj(gcf,'tag','bz'),'string');
            
            % Remove old transformation matrices if they exist
            cd([fileparts(img_file) '/AutoROIs'])
            if exist('AIRTransformation.air','file')
                delete('AIRTransformation.air')
            end
            if exist('FLIRTTransformation.air','file')
                delete('FLIRTTransformation.air')
            end
            if exist('AffineTransformation.air','file')
                delete('AffineTransformation.air')
            end      
            
            % Estimate two 12-parameter affine transformations (AIR and
            % FLIRT) that will normalize the SPECT image to the SPECT
            % template. The AIR routine estimates the transformation based
            % on a thresholded version of the template and patient images
            % (threshold set at median value of each image). The FLIRT
            % routine uses "Normalized Correlation" as cost function
            thr_temp = median(ReadAnalyzeImg(temp_file));
            thr_img = median(ReadAnalyzeImg(img_file));
            AIRfile = 'AIRTransformation.air';
            unix(sprintf('alignlinear %s %s %s -m 12 -t1 %d -t2 %d -x %s -b1 %d %d %d -b2 %d %d %d',...
                temp_file,img_file,AIRfile,thr_temp,thr_img,x,...
                str2double(b1),str2double(b2),str2double(b3),...
                str2double(b1),str2double(b2),str2double(b3)));
            
            FLIRTfile = [fileparts(img_file),'/AutoROIs/FLIRTTransformation.mat'];
            unix(sprintf('flirt -in %s -ref %s -omat %s -cost normcorr -interp trilinear',...
                 img_file,temp_file,FLIRTfile));

            % Use the mean of the two estimated transformations in order to
            % normalize the SPECT image to the SPECT template
            [AIRmat,AIRstruct] = ReadAir(AIRfile,'ieee-le');
            FLIRTmat = load(FLIRTfile,'-ASCII');
            MeanTransMat = (AIRmat+FLIRTmat)/2;
            AIRstruct.A = MeanTransMat;
            SaveAir('AffineTransformation.air',AIRstruct);
            TransformationFile = 'AffineTransformation.air';
                        
            % The normalized SPECT image is resliced to the SPECT template
            % using trilinear interpolation            
            unix(sprintf('reslice %s %s -k -o -n 1',...
                TransformationFile,'PatientInTemplateSpace'));
            
            switch varargin{2}
                case 'inspect'
                    DataStruct.imgPET = get(findobj(gcf,'tag','templatefile'),'string');
                    DataStruct.imgMR = [fileparts(img_file) '/AutoROIs/PatientInTemplateSpace.img'];
                    
                    % Close Alignment Inspection figure, if open
                    figs=findobj('type','figure','Name','Alignment Inspection');
                    delete(figs);
                   
                    nruinspect('loaddata',DataStruct);
                    set(findobj(gcf,'type','figure'),'Name','Alignment Inspection')
                    pos = [1/4*screensize(3) 1/4*screensize(4) screensize(3)/2 screensize(4)/2];
                    set(findobj(gcf,'type','figure'),'Position',pos);
                    
                    % Display message in GUI window
                    AddMesg('Alignment Inspection was initiated.');
                    
                    set(findobj(findobj('tag','roiautomainwin'),'tag','Button2'),'Enable','on');
                    set(findobj(findobj('tag','roiautomainwin'),'tag','Button3'),'Enable','off');
                    set(findobj(findobj('tag','roiautomainwin'),'tag','Button4'),'Enable','off');
                    
                case 'auto_roi_delineate'
                    % Close Alignment Inspection figure, if still open
                    TIfig=findobj('type','figure','Name','Alignment Inspection');
                    delete(TIfig);
                    
                    % The included ROI volumes (VOIs) from the normal
                    % healthy SPECT template are transfered to the
                    % normalized and resliced SPECT image. Afterwards, ROIs
                    % are constucted from the transfered VOIs
                    cd([fileparts(img_file) '/AutoROIs'])
                    NewRESFilelist = {...
                        'VOIStriatumdex',...
                        'VOIStriatumsin',...
                        'VOICaudatusdex',...
                        'VOICaudatussin',...
                        'VOIPutamendex',...
                        'VOIPutamensin',...
                        'VOIReference'};
                    ROIfilelist = {};
                    for fnum = 1:length(NewRESFilelist)
                        if findobj('tag',NewRESFilelist{fnum}(4:end),'value',1)
                            copyfile([fileparts(temp_file) '/' NewRESFilelist{fnum} '.*'])
                            % VOI to ROI transformation including use of
                            % Gaussian filter with a FWHM of 6x6x6 mm
                            analyze2editroi(...
                                [NewRESFilelist{fnum},'.hdr'],...
                                ['R' NewRESFilelist{fnum}(2:end)],[6 6 6],[]);
                            
                            % Create list of included ROIs
                            ROIfilelist{size(ROIfilelist,2)+1} = ['R' NewRESFilelist{fnum}(2:end) '.mat'];
                        end
                    end
                    
                    % Identify the slice number of that slice in the
                    % normalized and resliced SPECT image where the total
                    % mean activity in the two striatae is highest
                    SWMSA = FindCentralSliceWithMaxStriatumActivity([fileparts(img_file) '/AutoROIs/PatientInTemplateSpace.img']);
                    
                    % Use this slice number to isolate a series of five
                    % consequtive slices with ROIs
                    for ii = 1:length(ROIfilelist)
                        fname = ROIfilelist{ii};
                        if findobj(gcf,'tag',fname(4:end-4),'value',1)
                            mode = [];
                            load(fname);
                            if strcmp(regionname,'Reference')
                                % Isolate five consequtive slices with
                                % Reference ROIs
                                Mask = (relslice <= SWMSA-5 & relslice >= SWMSA-9);
                                vertex = vertex(Mask);
                                mode = mode(Mask);
                                region = region(Mask);
                                relslice = relslice(Mask);
                            else
                                % Isolate five consequtive slices with
                                % Striatum, Putamen, and Caudatus ROIs
                                Mask = (relslice<=SWMSA+2 & relslice>=SWMSA-2);
                                vertex = vertex(Mask);
                                mode = mode(Mask);
                                region = region(Mask);
                                relslice = relslice(Mask);
                                
                                % In the following it is guaranteed that we
                                % always get five consequtive slices with
                                % ROIs
                                MaskLen = length(find(Mask>0));
                                if MaskLen < 5
                                    if MaskLen == 4
                                        if relslice(2) == SWMSA
                                            relslice(2:5) = relslice;
                                            mode(2:5) = mode;
                                            region(2:5) = region;
                                            vertex(2:5) = vertex;
                                            relslice(1) = SWMSA-2;
                                            mode(1) = repmat(mode(2),1,1);
                                            region(1) = repmat(region(2),1,1);
                                            vertex(1) = repmat(vertex(2),1,1);
                                        elseif relslice(3) == SWMSA
                                            relslice(5) = SWMSA+2;
                                            mode(5) = repmat(mode(end),1,1);
                                            region(5) = repmat(region(end),1,1);
                                            vertex(5) = repmat(vertex(end),1,1);
                                        end
                                    elseif MaskLen == 3
                                        if relslice(1) == SWMSA
                                            relslice(3:5) = relslice;
                                            mode(3:5) = mode;
                                            region(3:5) = region;
                                            vertex(3:5) = vertex;
                                            relslice(1:2) = (SWMSA-2:SWMSA-1);
                                            mode(1:2) = repmat(mode(3),2,1);
                                            region(1:2) = repmat(region(3),2,1);
                                            vertex(1:2) = repmat(vertex(3),2,1);
                                        elseif relslice(2) == SWMSA
                                            relslice(2:4) = relslice;
                                            mode(2:4) = mode;
                                            region(2:4) = region;
                                            vertex(2:4) = vertex;
                                            relslice(1) = SWMSA-2;
                                            mode(1) = repmat(mode(2),1,1);
                                            region(1) = repmat(region(2),1,1);
                                            vertex(1) = repmat(vertex(2),1,1);
                                            relslice(5) = SWMSA+2;
                                            mode(5) = repmat(mode(4),1,1);
                                            region(5) = repmat(region(4),1,1);
                                            vertex(5) = repmat(vertex(4),1,1);
                                        elseif relslice(3) == SWMSA
                                            relslice(1:3) = relslice;
                                            mode(1:3) = mode;
                                            region(1:3) = region;
                                            vertex(1:3) = vertex;
                                            relslice(4:5) = (SWMSA+1:SWMSA+2);
                                            mode(4:5) = repmat(mode(3),2,1);
                                            region(4:5) = repmat(region(3),2,1);
                                            vertex(4:5) = repmat(vertex(3),2,1);
                                        end
                                    elseif MaskLen == 2
                                        if relslice(1) == SWMSA
                                            relslice(3:4) = relslice;
                                            mode(3:4) = mode;
                                            region(3:4) = region;
                                            vertex(3:4) = vertex;
                                            relslice(1:2) = (SWMSA-2:SWMSA-1);
                                            mode(1:2) = repmat(mode(3),2,1);
                                            region(1:2) = repmat(region(3),2,1);
                                            vertex(1:2) = repmat(vertex(3),2,1);
                                            relslice(5) = SWMSA+2;
                                            mode(5) = repmat(mode(4),1,1);
                                            region(5) = repmat(region(4),1,1);
                                            vertex(5) = repmat(vertex(4),1,1);
                                        elseif relslice(2) == SWMSA
                                            relslice(2:3) = relslice;
                                            mode(2:3) = mode;
                                            region(2:3) = region;
                                            vertex(2:3) = vertex;
                                            relslice(1) = SWMSA-2;
                                            mode(1) = repmat(mode(2),1,1);
                                            region(1) = repmat(region(2),1,1);
                                            vertex(1) = repmat(vertex(2),1,1);
                                            relslice(4:5) = (SWMSA+1:SWMSA+2);
                                            mode(4:5) = repmat(mode(3),2,1);
                                            region(4:5) = repmat(region(3),2,1);
                                            vertex(4:5) = repmat(vertex(3),2,1);
                                        elseif relslice(2) == SWMSA-1
                                            relslice(3:5) = (SWMSA:SWMSA+2);
                                            mode(3:5) = repmat(mode(2),3,1);
                                            region(3:5) = repmat(region(2),3,1);
                                            vertex(3:5) = repmat(vertex(2),3,1);
                                        elseif relslice(1) == SWMSA+1
                                            relslice(4:5) = relslice;
                                            mode(4:5) = mode;
                                            region(4:5) = region;
                                            vertex(4:5) = vertex;
                                            relslice(1:3) = (SWMSA-2:SWMSA);
                                            mode(1:3) = repmat(mode(4),3,1);
                                            region(1:3) = repmat(region(4),3,1);
                                            vertex(1:3) = repmat(vertex(4),3,1);
                                        end
                                    elseif MaskLen == 1
                                        relslice(1:5) = (SWMSA-2:SWMSA+2);
                                        mode(2:5) = repmat(mode(end),4,1);
                                        region(2:5) = repmat(region(end),4,1);
                                        vertex(2:5) = repmat(vertex(end),4,1);
                                    end
                                end
                            end
                            save(fname, 'filetype', 'mode', 'region', 'regionname', 'relslice', 'slicedist', 'vertex');
                        end
                    end
                                  
                    % Combining all the transfered ROIs in a single file
                    editroiCombine(ROIfilelist,'AllROIs.mat');
                    
                    % Display message in GUI window
                    AddMesg('Transformation procedure was successfully completed!')
                    AddMesg('A subdirectory called ''AutoROIs'' was created in the directory of the analyzed image file.')
                    AddMesg('The subdirectory contains the automatically delineated ROIs.')
                    
                    homefig = findobj('tag','roiautomainwin');
                    if findobj(homefig,'tag','Button3','Enable','off')
                        set(findobj(homefig,'tag','Button3'),'Enable','on')
                        set(findobj(homefig,'tag','Button4'),'Enable','off')
                    end
            end
            
        case 'correctrois'
            temp_file = get(findobj(gcf,'tag','templatefile'),'string');
            img_file = get(findobj(gcf,'tag','imagefile'),'string');
            if isempty(temp_file) || strcmp(img_file,'/')
                warndlg('You have to specify two input files to continue!',...
                    'Input file error!')
                return
            else
                % Close Alignment Inspection figure if it is still open
                TIfig=findobj('type','figure','Name','Alignment Inspection');
                delete(TIfig);
                
                % The inspection of the automatically delineated ROIs is
                % done via the editroi GUI
                img_file = get(findobj(gcf,'tag','imagefile'),'string');
                img_file = [fileparts(img_file) '/AutoROIs/PatientInTemplateSpace.img'];
                
                editroi
                cd(fileparts(img_file))
                editroi('loadimg',img_file);
                % Automatically move focus to slices with ROIs
                SWMSA = FindCentralSliceWithMaxStriatumActivity('PatientInTemplateSpace.img')+1;
                editroi('rslider',SWMSA-0.45)
                set(findobj('tag','Colorbar'),'XaxisLocation','bottom')
                
                if SPECTPIPELINE == 1
                    editroi('SpectPipeline')
                end
                
                % Make two ROI files containing only the striatae ROIs
                % from the central slice and load these into editroi
                isolatecentralroi;
                editroi('load','AutoROIs/ROIStriatum_central')
                ROIsfig=findobj('type','figure','Name','PatientInTemplateSpace');
                set(ROIsfig,'CloseRequestFcn','editroi(''SpectPipelineWarning'')')
                editroi('movenodes')
                editroifig=findobj('type','figure','Name','ROIStriatum_central');
                set(editroifig,'Visible','off')
                uiwait(ROIsfig);
                applymanualroicorr;
                
                homefig = findobj('tag','roiautomainwin');
                set(findobj(homefig,'tag','Button4'),'Enable','on')
            end
            
        case 'visualizerois'
            temp_file = get(findobj(gcf,'tag','templatefile'),'string');
            img_file = get(findobj(gcf,'tag','imagefile'),'string');
            if isempty(temp_file) || strcmp(img_file,'/')
                warndlg('You have to specify two input files to continue!',...
                    'Input file error!')
                return
            else
                % Close Alignment Inspection figure if it is still open
                TIfig=findobj('type','figure','Name','Alignment Inspection');
                delete(TIfig);
                
                % The inspection of the automatically delineated ROIs is
                % done via the editroi GUI
                img_file = get(findobj(gcf,'tag','imagefile'),'string');
                img_file = [fileparts(img_file) '/AutoROIs/PatientInTemplateSpace.img'];
                
                editroi
                cd(fileparts(img_file))
                editroi('loadimg',img_file);
                % Automatically move focus to slices with ROIs
                SWMSA = FindCentralSliceWithMaxStriatumActivity('PatientInTemplateSpace.img')+1;
                editroi('rslider',SWMSA-0.45)
                set(findobj('tag','Colorbar'),'XaxisLocation','bottom')
                if exist('AutoROIs/AllROIs_corr.mat','file')
                    editroi('load','AutoROIs/AllROIs_corr')
                    if SPECTPIPELINE == 1
                        ROIsfig=findobj('type','figure','Name','PatientInTemplateSpace');
                        editroifig=findobj('type','figure','Name','AllROIs_corr');
                        set(ROIsfig,'CloseRequestFcn','editroi(''SpectPipelineError'')')
                        set(editroifig,'CloseRequestFcn','editroi(''SpectPipelineError'')')
                    end
                else
                    editroi('load','AutoROIs/AllROIs')
                    if SPECTPIPELINE == 1
                        ROIsfig=findobj('type','figure','Name','PatientInTemplateSpace');
                        editroifig=findobj('type','figure','Name','AllROIs');
                        set(ROIsfig,'CloseRequestFcn','editroi(''SpectPipelineError'')')
                        set(editroifig,'CloseRequestFcn','editroi(''SpectPipelineError'')')
                    end
                end
                if SPECTPIPELINE == 1
                    editroi('SpectPipeline')
                end
            end
    end
end

%*************************************
function SetupGUI

%
% This function sets up the GUI initially
%
close all
screensize=get(0,'ScreenSize');
figpos = round([1/10*screensize(3) 15/100*screensize(4) 4/5*screensize(3) 3/5*screensize(4)]);
figure('position',figpos,...
    'menubar','none',...
    'name','roiauto',...
    'tag','roiautomainwin',...
    'numbertitle','off');
framecolor = [.1 .4 .5];

%
% File handling
%
uicontrol('style','frame',...
    'units','normalized',...
    'backgroundcolor',framecolor,...
    'position',[0.03 0.72 .94 0.25])

uicontrol('style','text',...
    'units','normalized',...
    'position',[0.25 0.915 .5 0.035],...,
    'fontweight','bold',...
    'fontsize',12,...
    'String','Input files',...
    'backgroundcolor',[0 0.8 0.8]);

uicontrol('style','pushbutton',...
    'String','Normal healthy SPECT template:',...
    'callback','roiauto(''DefineTemplate'')',...
    'units','normalized',...
    'position',[0.08 0.84 .23 0.05])

uicontrol('style','text',...
    'units','normalized',...
    'position',[0.33 0.84 0.59 0.05],...
    'String','/usr/local/nru/nru_matlab/roiautomatic/TemplateFiles/Template.img',...
    'tag','templatefile',...
    'HorizontalAlignment','left',...
    'backgroundcolor',[1 1 1]);

uicontrol('style','pushbutton',...
    'String','SPECT image to analyze:',...
    'callback','roiauto(''DefineImage'')',...
    'units','normalized',...
    'position',[0.08 0.76 .23 0.05]);

uicontrol('style','text',...
    'units','normalized',...
    'position',[0.33 0.76 0.59 0.05],...
    'String','',...
    'tag','imagefile',...
    'HorizontalAlignment','left',...
    'backgroundcolor',[1 1 1]);

%
% ROIs to delineate
%
uicontrol('style','frame',...
    'units','normalized',...
    'backgroundcolor',framecolor,...
    'position',[0.03 0.52 .94 0.18])

uicontrol('style','text',...
    'units','normalized',...
    'position',[0.25 0.65 .5 0.035],...,
    'fontweight','bold',...
    'fontsize',12,...
    'String','ROIs to delineate',...
    'backgroundcolor',[0 0.8 0.8]);

uicontrol('style','pushbutton',...
    'units','normalized',...
    'string','Select all',...
    'fontsize',11,...
    'fontweight','demi',...
    'callback','roiauto(''select_all'')',...
    'position',[0.1 0.59 .18 0.0425],...
    'tag','selectall');

uicontrol('style','pushbutton',...
    'units','normalized',...
    'string','Deselect all',...
    'fontsize',11,...
    'fontweight','demi',...
    'callback','roiauto(''deselect_all'')',...
    'position',[0.1 0.54 .18 0.0425],...
    'tag','deselectall');

uicontrol('style','checkbox',...
    'enable','off',...
    'units','normalized',...
    'position',[0.32 0.59 .13 0.03],...
    'tag','Striatumsin',...
    'value',1,...
    'callback','roiauto(''striatum_sin'')',...
    'string','   Striatum sin',...
    'fontsize',11)

uicontrol('style','checkbox',...
    'enable','off',...
    'units','normalized',...
    'position',[0.32 0.5525 .13 0.03],...
    'tag','Striatumdex',...
    'value',1,...
    'callback','roiauto(''striatum_dex'')',...
    'userdata','1',...
    'string','   Striatum dex',...
    'fontsize',11)

uicontrol('style','checkbox',...
    'units','normalized',...
    'position',[0.47 0.59 .13 0.03],...
    'tag','Putamensin',...
    'value',1,...
    'callback','roiauto(''putamen_sin'')',...
    'userdata','1',...
    'string','   Putamen sin',...
    'fontsize',11)

uicontrol('style','checkbox',...
    'units','normalized',...
    'position',[0.47 0.5525 .13 0.03],...
    'tag','Putamendex',...
    'value',1,...
    'callback','roiauto(''putamen_dex'')',...
    'userdata','1',...
    'string','   Putamen dex',...
    'fontsize',11)

uicontrol('style','checkbox',...
    'units','normalized',...
    'position',[0.62 0.59 .13 0.03],...
    'tag','Caudatussin',...
    'value',1,...
    'callback','roiauto(''caudatus_sin'')',...
    'userdata','1',...
    'string','   Caudatus sin',...
    'fontsize',11)

uicontrol('style','checkbox',...
    'units','normalized',...
    'position',[0.62 0.5525 .13 0.03],...
    'tag','Caudatusdex',...
    'value',1,...
    'callback','roiauto(''caudatus_dex'')',...
    'userdata','1',...
    'string','   Caudatus dex',...
    'fontsize',11)

uicontrol('style','checkbox',...
    'units','normalized',...
    'position',[0.77 0.59 .15 0.03],...
    'tag','Reference',...
    'value',1,...
    'callback','roiauto(''reference'')',...
    'userdata','1',...
    'string','   Reference',...
    'fontsize',11)

%
% Cost Function
%
uicontrol('style','frame',...
    'units','normalized',...
    'backgroundcolor',framecolor,...
    'position',[0.03 0.23 .36 0.27])

uicontrol('style','text',...
    'units','normalized',...
    'position',[0.1 .445 .22 .035],...
    'fontweight','bold',...
    'fontsize',12,...
    'string','Cost Function for Alignment (AIR)',...
    'backgroundcolor',[0 0.8 0.8])

uicontrol('style','radiobutton',...
    'units','normalized',...
    'position',[0.07 .37 .28 .05],...
    'tag','std',...
    'callback','roiauto(''std'')',...
    'userdata','1',...
    'string','Standard Deviation of Ratio Image')

uicontrol('style','radiobutton',...
    'units','normalized',...
    'position',[0.07 .32 .28 .05],...
    'tag','lsd',...
    'callback','roiauto(''lsd'')',...
    'userdata','2',...
    'string', 'Least Squares of Difference Image')

uicontrol('style','radiobutton',...
    'units','normalized',...
    'position',[.07 .27 .28 .05],...
    'tag','lsi',...
    'value',1,...
    'callback','roiauto(''lsi'')',...
    'userdata','3',...
    'string', 'Least Squares with Intensity Rescaling')


%
% Smoothing in alignment step
%
uicontrol('style','frame',...
    'units','normalized',...
    'backgroundcolor',framecolor,...
    'position',[0.41 0.23 .23 0.27])

uicontrol('style','text',...
    'units','normalized',...
    'position',[.43 .445 .19 .035],...
    'fontweight','bold',...
    'fontsize',12,...
    'string','Smoothing (FWHM in mm)',...
    'backgroundcolor',[0 0.8 0.8])

uicontrol('style','text',...
    'units','normalized',...
    'position',[.45 .38 .04 .033],...
    'string','x:')

uicontrol('style','edit',...
    'units','normalized',...
    'position',[.52 .38 .07 .033],...
    'tag','bx',...
    'string','12',...
    'backgroundcolor',[1 1 1])

uicontrol('style','text',...
    'units','normalized',...
    'position',[.45 .325 .04 .033],...
    'string','y:')

uicontrol('style','edit',...
    'units','normalized',...
    'position',[.52 .325 .07 .033],...
    'tag','by',...
    'string','12',...
    'backgroundcolor',[1 1 1])

uicontrol('style','text',...
    'units','normalized',...
    'position',[.45 .27 .04 .033],...
    'string','z:')

uicontrol('style','edit',...
    'units','normalized',...
    'position',[.52 .27 .07 .033],...
    'tag','bz',...
    'string','12',...
    'backgroundcolor',[1 1 1])

%
% Execution buttons
%
uicontrol('style','frame',...
    'units','normalized',...
    'backgroundcolor',framecolor,...
    'position',[0.66 0.23 .31 0.27])

uicontrol('style','pushbutton',...
    'units','normalized',...
    'string','Align & Inspect',...
    'fontsize',11,...
    'fontweight','demi',...
    'callback','roiauto(''align'',''inspect'')',...
    'position',[0.7 0.42 .23 0.05],...
    'tag','Button1',...
    'enable','off');

uicontrol('style','pushbutton',...
    'units','normalized',...
    'string','Automatic ROI Delineation',...
    'fontsize',11,...
    'fontweight','demi',...
    'callback','roiauto(''align'',''auto_roi_delineate'')',...
    'position',[0.7 0.37 .23 0.05],...
    'tag','Button2',...
    'enable','off');

uicontrol('style','pushbutton',...
    'units','normalized',...
    'string','Manual ROI correction',...
    'fontsize',11,...
    'fontweight','demi',...
    'callback','roiauto(''correctrois'')',...
    'position',[0.7 0.32 .23 0.05],...
    'tag','Button3',...
    'enable','off');

uicontrol('style','pushbutton',...
    'units','normalized',...
    'string','Visualize ROIs',...
    'fontsize',11,...
    'fontweight','demi',...
    'callback','roiauto(''visualizerois'')',...
    'position',[0.7 0.27 .23 0.05],...
    'tag','Button4',...
    'enable','off');

%
% Message Window
%
uicontrol('style','listbox',...
    'units','normalized',...
    'position', [0.03 0.03 0.94 0.17],...
    'String',[tstr ' - The program was started.'],...
    'tag','msgbox')


%*************************************
function AddMesg(str)

% This simple function is used to add messages to the GUI's history dialog

fig=findobj('tag','roiautomainwin');
box=findobj(fig,'tag','msgbox');
curlist=get(box,'string');
if not(iscell(curlist))
    newlist=cell(2,1);
    newlist{1}=curlist;
    newlist{2}=[tstr ' - ' str];
else
    newlist=cell(length(curlist)+1,1);
    for j=1:length(curlist)
        newlist{j}=curlist{j};
    end
    newlist{j+1}=[tstr ' - ' str];
end
set(box,'string',newlist,'value',length(newlist));