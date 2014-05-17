function [Min,Max,imgType]=findLim(Img,varargin)
% This function is used to find colorlimits in analyzeimages.
% Maximal contrast is the goal while trying to display as much information as possible.
% 
% Syntax:
% 
% [Min,Max,imgType]=findLim(Img) - uses default method
% 
% or
% 
% [Min,Max,imgType]=findLim(Img,Method)
% 
% where
% 
% imgType     = Imagetype ('MR' or 'PET') suggested by assuming that MR files have all positive values and PET/SPECT have not.
% Img         = Image-matrix with any dimension.
% Method      = 'raw': Simply return min and max of all values.
%               'fractile': Uses fractile function for Max. Min is set to
%               background and if this causes problem, fractile func. is
%               also used for Min. (default)
%
%                   Background dependent: (Min is set to BG = most abundant color)
%               'peak': Return values where Max is based on peaks in the information weighted histogram.
%               'ratio': Use weighted histogram to find Max color at a set ratio of the most abundant color.
%
%               For more information see explanation in code.
%               
% By Thomas Rask 050104
%

% Settings:
SegRoiLim=50; %Maximum number of colors for treating image as ROI-map or segmented image.
%


if nargin==1
    [Min,Max,imgType]=findLim(Img,'ratio'); %set default method
elseif nargin~=2
    error('Wrong number of input-arguments. Syntax: [Min,Max,imgType]=findLim(Img [,Method])');
elseif nargin==2
    
    Command=lower(varargin{1});
    imgType='';
    
    % Measure time
%     disp(['Start time for ',Command]);
%     TID = cputime; 
    
    %Check if it is a ROI-map or segmented file
    [fineN,fineX]=hist(double(Img(:)),500); %Create histogram with 1000 bins (N=number of elements in bin, X=value of bin)
    nBins=find(fineN~=0); %find non-empty bins
    if length(nBins)<=SegRoiLim  
        Command='raw';
        imgType='PET'; %if roi or seg, use non-gray colormap
    end
    
    %if imagetype has not yet been determined
    if isempty(imgType)
        imgType=ImgType(fineX);                
    end

    
    %____ Use the method selected
    switch Command
        case 'raw'
%             ------------------------------------------------------------------------------------------------------
%             In this method, Min and Max is respectively set to the biggest and smallest colorvalues in the image.
%             if the image is empty, it returns Min=0 and Max=1.
%             This method is crude but always works.
%             ------------------------------------------------------------------------------------------------------
            
            Max=round(max(double(Img(:))));
            Min=round(min(double(Img(:))));
            
            %if image is empty
            if Min==Max
                Min=0;
                Max=1;
            end      


        case 'fractile'
%             ----------------------------------------------------------------------------------------------------------
%             Max is set by the fractile method, that is, it cuts of a percentage of the highest color values.
%             Min is set to the most abundant color, and if this creates problems, Min is set also by the fractile way.
%             This method is pretty slow especially in windows.
%             ----------------------------------------------------------------------------------------------------------
  
            %_________Max value 
            Max=round(fractile(double(Img(:)),99)); %set Max to cut of 1% of the highest values                   
            
            %________Min value 
            [N,X]=hist(double(Img(:)),100); %Create histogram with 100 bins (N=number of elements in bin, X=value of bin)
            [BGvalue,BGindex]=max(N); %Assume background is biggest bin
            Min=round(X(BGindex)); %Set Min to background (=most abundant color)
            
            if Min>=Max
                Min=round(fractile(double(Img(:)),15)); %set Min to cut of 15% of the lowest values                   
            end
            
 
        case 'ratio'
%             ----------------------------------------------------------------------------------------------------
%             This method takes the weighted histogram and finds the first bin from the right that satisfies a 
%             userdefined Hight (a percentage of the highest bin) and sets it as Max
%             Minimum is set to most abundant color.
%             The ratio method creates darker pictures, but this can be regulated bu changing the Hight-variable.
%             This method is pretty fast, also in windows
%             -----------------------------------------------------------------------------------------------------

%           _______________No reason to make histogram again_______________
%             bins=100;
%             %Select max value based upon histogram,
%             [N,X]=hist(double(Img(:)),bins); %Create histogram with 100 bins (N=number of elements in bin, X=value of bin)
%           _______________________________________________________________
            
            bins=100;
            %Select max value based upon histogram,
            [N,X]=hist(double(Img(:)),bins); %Create histogram with 100 bins (N=number of elements in bin, X=value of bin)
            
            [BGvalue,BGindex]=max(N); %Assume background is biggest bin

            %________Min value             
            Min=round(X(BGindex)); %set Min to background
            
            %_________Max value                
            Prod=X.*X.*N; %Weight by value^2 and occurence
            %                     Prod=X.*N; %Weight by value and occurence
            
            Hight=5;     %minimum peak hight (percentage of highest peak. The higher the brighter image.)
            Smooth=1;    %half smooth window (eg. Smooth=1 leads to window 3 bins wide)
            
            for i=1+Smooth:bins-Smooth
                Prod(i)=sum(Prod(i-Smooth:i+Smooth))/(Smooth*2+1);
            end 
            
            % show weighted histogram
            % h2=figure;
            % plot(Prod);
            
            %Find the highest colorvalue that satisfies Hight
            p=find(Prod>=max(Prod*(Hight/100)));
            Max=round(X(p(end)));
            
            % disp(['Required inf. level reached at ',num2str(p(end)),'% of color scale.']);
            
        case 'peak'
%             ------------------------------------------------------------------------------------------------
%             This method takes the weighted histogram and finds the rightmost peak, and sets it as maximum.
%             Minimum is set to most abundant color.
%             The peak method creates brght pictures.
%             ------------------------------------------------------------------------------------------------
            
            bins=100;
            %Select min and max value based upon histogram,
            [N,X]=hist(double(Img(:)),bins); %Create histogram with 100 bins (N=number of elements in bin, X=value of bin)  
            [BGvalue,BGindex]=max(N); %Assume background is biggest bin
            
            %________Min value                
            Min=round(X(BGindex));
        
            %_________Max value          
            Prod=X.*N; %Weight by value and occurence
            
            Length=2;               %number of sidecheck bins for peak-search
            Hight=1;     %minimum peak hight (percentage of highest peak. The higher the brighter image.)
            Smooth=1;    %half smooth window (eg. Smooth=1 leads to window 3 bins wide)
            
            for i=1+Smooth:bins-Smooth
                Prod(i)=sum(Prod(i-Smooth:i+Smooth))/(Smooth*2+1);
            end
            
            % show weighted histogram
            % h2=figure;
            % plot(Prod);
       
            Slope=diff(Prod); %find peaks
            
            Max=1;
            for b=bins-2-Length:-1:3+Length
                if Slope(b-Length+1:b-1)>0 & Slope(b+1:b+Length)<0 & Prod(b)>=max(Prod*(Hight/100))
                    Max=round(X(b));
                    %disp(['Peak found at ',num2str(b),'% of colorscale. Maximum is set to: ',num2str(Max)]);
                    break;
                end
            end 
            
            %Check if we missed any peaks
            if (Prod(b+1:bins-Smooth)>Prod(b)) | (isempty(Min) | isempty(Max) | (Min>=Max))
                disp('Peak not satisfactory, changing to default method...');
                [Min,Max,imgType]=findLim(Img,'fractile');
                return
            end
            
        otherwise
            error('Can not recognize second input-argument.');
    end
    
    %In case of problem just take min and max
    if (isempty(Min) | isempty(Max) | (Min>=Max))
        [Min,Max,imgType]=findLim(Img,'raw');
        return;
    end            
         
    %     disp([num2str(cputime-TID),' seconds for ', Command]);
    
end

function Type=ImgType(X)
if(min(X)>0)% Check if image is MR(bin always positive) or PET/SPECT
    % Typically a MR scan
    Type='MR';
else
    % PET or SPECT scan
    Type='PET';
end

