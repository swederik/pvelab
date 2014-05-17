function [ROI,Message]=LoadRoi(filename,hdr);
% function [ROI,Message]=LoadRoi(filename,hdr)
% 
% Load Editroi ROI from filename into dataset with analyze 
% header hdr
%
% Message is a message string containing load messages.
%
  if nargin==2
    % load the original ROI:
    ROI=load(filename);
    if isfield(ROI,'filetype') & ...
	  strcmp(ROI.filetype,'EditRoiFile')
    
      % Check if the region is compatible:
      match=0;
      matches=zeros(length(ROI.region),1);
      if all(hdr.origin==0)
	hdr.origin=1+hdr.origin;
      end
      z=hdr.siz(3)*([1:hdr.dim(3)]-hdr.origin(3));
      for j=1:length(ROI.region);
        % Due to problem in AIR file the precision of the slicedist can not
	% be expected to be any better than 1e-4, therefore don't test for
	% exact precision
	matches(j)=min(abs(ROI.relslice(j)*ROI.slicedist-z))<1e-4;
      end
      % Did every region fit?
      if all(matches)
	match=1;
	Message=[filename ' loaded'];
      end
      % Non-matching region - reslice?
      if match==0
	Choice=questdlg('MR dataset and region incompatible. Reslice region?');
	% Reslice:
	if strcmp(Choice,'Yes')
	  match=1;
	  disp(['Reslicing ' filename ' - have patience...'])
	  VOI=Roi2Voi(ROI);
	  % Hack to enshure that the old slice polygons are not
	  % included in resulting ROI:
	  VOI.rotated=1;
	  ROI=Voi2Roi(VOI,hdr.origin,hdr.siz,hdr.dim);
	  Message=[filename ' resliced and loaded'];
	else;
	  % Don't reslice:
	  ROI=[];
	  Message=['Reslice of ' filename ' cancelled'];
	end
      end
    else
      % Not a valid Editroi ROI
      Message=[filename ' is not a valid EditROI file'];
      ROI=[];
    end
  else
    % Wrong # of parameters to LoadRoi
    Message='LoadRoi requres exactly two parameters, filename and hdr';
    ROI=[];
  end
