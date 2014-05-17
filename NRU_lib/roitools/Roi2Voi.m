function VOI=Roi2Voi(ROI);
% function VOI=Roi2Voi(ROI);
%
% Contstuct faces and vertices arrays of 3d-object
% from polygons of editroi ROI struct.
%
% ROI is editroi struct.
%
% VOI is a struct with members 
%   FV - cell array of stuct with members
%     faces
%     vertices
%   ROIdat - cell array of struct with original editroi
%        data, in members
%     mode 
%     slicedist
%     regionname
%   
% Arrays are accessed by use of eg.
% VOI.FV{j}.faces
% VOI.ROIdat{j}.regionname
%
% See Also CutVoi, Voi2Roi, RotVoi
%
% NOTE: to enshure conservation of ROI volume, ROI polygons
% of the first and last slice are repeated at half a slice
% below / above bottom / top of region.
%


% How many regions are available?
Regs=unique(ROI.region);

% Loop over each region:

FV=cell(length(Regs),1);
ROIdat=cell(length(Regs),1);
for j=1:length(Regs)
  % Determine index of current region number.
  CurrentRegs=ROI.region==Regs(j);
  RegNumbers=1:length(ROI.region);
  RegNumbers=RegNumbers(CurrentRegs);

  % Which Z-slices are there?
  Zslices=sort(unique(ROI.relslice(CurrentRegs)));
  Zslices=reshape(Zslices,length(Zslices),1);
%  keyboard
  Zslices=[Zslices(1)-0.5; Zslices; Zslices(length(Zslices))+0.5];
  % Add two "half-slice" regions:
  
  
  % Write file for use with nuages:
  
  % Open file:
  fid = fopen('nuages.tmp','w');
  fprintf(fid,'%s \n',['S ' num2str(length(unique(Zslices)))]); % Write number of slices
  for k=1:length(Zslices); % for each z-slice
    %disp(num2str(Zslices(k)*ROI.slicedist))
    if k==1 
      k1=k+1;
    elseif k==length(Zslices)
      k1=k-1;
    else
      k1=k;
    end
    % Which of the regions are in this slice?
    ThisSliceRegs=RegNumbers(ROI.relslice(RegNumbers)==Zslices(k1));
    % How many vertices in this slice?
    v=0;
    for l=1:length(ThisSliceRegs)
      VertSiz=size(ROI.vertex{ThisSliceRegs(l)});
      v=v+VertSiz(1);
      
    end
    fprintf(fid,'%s \n',['v ' num2str(v) ' z ' num2str(Zslices(k)* ...
						  ROI.slicedist)]); % Write number of vertices and z-value 
    for l=1:length(ThisSliceRegs)
      fprintf(fid,'%s \n','{'); % Write beginning '{'
      xy=ROI.vertex{ThisSliceRegs(l)};
      %dlmwrite('verts.tmp',xy,' ')
      %unix('cat verts.tmp >> nuages.tmp');
      SizXY=size(xy);
      xx=zeros(2*SizXY(1),1);
      xx(1:2:2*SizXY(1)-1)=xy(:,1);
      xx(2:2:2*SizXY(1))=xy(:,2);
      strarr=sprintf('%d %d \n ',xx);
      fprintf(fid,'%s\n',strarr);; % Write xy data points
      %for m=1:SizXY(1)
      %	fprintf(fid,'%s \n',[num2str(xy(m,1)) ' ' num2str(xy(m,2))]); % Write xy data point
      %end
      fprintf(fid,'%s \n','}'); % Write ending '{'
    end
  end;
  fclose(fid);

  % Run 'nuages' and read the off file:
  unix('nuages nuages.tmp -off -tri tmp.off');
  
  % Create VOI.FV struct
  disp(['Creating Face/Vertex data for region ' num2str(Regs(j)) ' of ' num2str(Regs(length(Regs)))]);
  FV{j}=ReadNuages('tmp.off');
  
  % Save EditROI data in ROIdat struct using
  % the first, current region.
  Rdat=struct('mode',ROI.mode(RegNumbers(1)),'slicedist',ROI.slicedist,'regionname',ROI.regionname(Regs(j)));
  ROIdat{j}=Rdat;
end
VOI.FV=FV;
VOI.ROIdat=ROIdat;
ROI.region=reshape(ROI.region,length(ROI.region),1);
ROI.vertex=reshape(ROI.vertex,length(ROI.vertex),1);
ROI.relslice=reshape(ROI.relslice,length(ROI.relslice),1);
ROI.mode=reshape(ROI.mode,length(ROI.mode),1);

VOI.myROI=ROI;
disp('Roi2Voi Done.')