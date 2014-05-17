function ROI=Voi2Roi(VOI,origin,siz,dim);
%
% function ROI=Voi2Roi(VOI,origin,siz,dim);
% 
% Calculate editroi ROI's from VOI.
% origin, siz, dim from analyze dataset.
% 
% All z-slices intersecting the VOI are given
% a ROI polygon.
%
% See Also CutVoi, Roi2Voi, RotVoi
%
  
  n=[0 0 1]; % We are only cutting in z-direction
  % z-coordinates and dimension:
  zdim=[1:dim(3)];
  z=siz(3)*(zdim-origin(3));
  verts=[];
  mode=[];
  region=[];
  slice=[];
  for j=1:length(VOI.FV)
    if not(isempty(VOI.FV{j}));
      zmin=min(VOI.FV{j}.vertices(:,3));
      zmax=max(VOI.FV{j}.vertices(:,3));
      % What indices is that?
      [tmp,minidx]=min(abs(z-zmin));
      [tmp,maxidx]=min(abs(z-zmax));
      minidx=max(minidx-1,1);
      maxidx=min(maxidx+1,dim(3));
      zcuts=siz(3)*([minidx:maxidx]-origin(3));
      if not(isfield(VOI,'rotated'))
	Slices=unique(VOI.myROI.relslice)*VOI.myROI.slicedist;
	for jj=1:length(Slices)
	  zcuts(zcuts==Slices(jj))=[];
	  
	end
      end
      % Run CutVoi:
      VOIj.FV{1}=VOI.FV{j};
      VOIj.ROIdat{1}=VOI.ROIdat{j};
      Rois=CutVoi(VOIj,n,zcuts);
      oldverts=verts;
      verts=cell(length(Rois.Contours)+length(verts),1);
      oldmode=mode;
      if not(isempty(oldverts))
	for jj=1:length(oldverts)
	  verts{jj}=oldverts{jj};
	  mode{jj}=oldmode{jj};
	end
	%[verts{1:length(oldverts)}]=deal(oldverts);
	%[mode{1:length(oldmode)}]=deal(oldmode);
      end
      for jj=1:length(Rois.Contours)
	verts{jj+length(oldverts)}=[Rois.Contours{jj}(:,1) Rois.Contours{jj}(:,2);...
		    Rois.Contours{jj}(1,1) Rois.Contours{jj}(1,2);];
	slice=[slice;Rois.Contours{jj}(1,3)/siz(3)];
	mode{jj+length(oldmode)}=VOI.ROIdat{j}.mode;
      end
      regname{j}=VOI.ROIdat{j}.regionname;
      region=[region;j*ones(length(Rois.Contours),1)];
    end
  end    
  if not(isfield(VOI,'rotated'))
    oldverts=verts;
    verts=cell(length(VOI.myROI.vertex)+length(verts),1);
    oldmode=mode;
    if not(isempty(oldverts))
      for jj=1:length(oldverts)
	verts{jj}=oldverts{jj};
	mode{jj}=oldmode{jj};
      end
    end
    for jj=1:length(VOI.myROI.vertex)
      verts{jj+length(oldverts)}=VOI.myROI.vertex{jj};
      mode{jj+length(oldmode)}=VOI.myROI.mode{jj};
    end
    region=[region;VOI.myROI.region];
    slice=[slice;round(VOI.myROI.relslice*VOI.myROI.slicedist/siz(3))];
  end
  ROI.vertex=verts;
  ROI.mode=reshape(mode,length(mode),1);
  ROI.region=region;
  ROI.relslice=slice;
  ROI.regionname=reshape(regname,length(regname),1);
  ROI.slicedist=siz(3);
  ROI.filetype='EditRoiFile';
  
  