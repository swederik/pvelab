function	[d]=write_dyn_analyze(d, frame_times);

% Write Analyze format Image Volumes
%
% Usage
%
% write_dyn_analyze(d);
% 
% Writes image data and attributes from the structure d.
% The following fields are required from d. 
%
% d.file_path: 'path'
% d.file_name: 'filename'
% d.data: [128x128x31 double]
% d.vox: [2.0900 2.0900 3.4200]
% d.vox_units: 'mm'
% d.vox_offset: 0
% d.calib_units: 'min^-1'
% d.origin: [0 0 0];
% d.descrip: 'descr'
%
% All other information is generated automatically.

machine_format ='b';


if (length(frame_times)~=0 )
    existframetimes=true;
    % write frame times
    save([d.file_name '.tim'], 'frame_times' , '-ASCII');
else
    existframetimes=false;
end;
    

lefn=length(d.file_name);
if ~strcmp(d.file_name((lefn-3):lefn),'.img')
    d.file_name=[d.file_name '.img'];
end

if length(size(d.data))<5&size(d.data,1)>1&size(d.data,2)>1&length(d.origin)<4
   
   d.calib = double([min(min(min(min(d.data)))) max(max(max(max(d.data))))]);d.precision='int32';  
   
   % Write Header
   if nargin==2
      [d]=write_dyn_analyze_hdr(d,machine_format,existframetimes);
   end
   % Write Image 
   
   if nargin==2
      if ~isempty(d)
         
         fid = fopen([d.file_path d.file_name],'w',machine_format);
         if fid > -1
            
            for t=1:d.hdr.dim(5)
               for z=1:d.hdr.dim(4)
                  fwrite(fid,int32(double(d.data(:,:,z,t))/d.hdr.funused1),d.precision);
               end
            end
            
            fclose (fid);
            
         else
            errordlg('Cannot open file for writing  ','Write Error');d=[];return;
            
         end
      end
 
    else
       errordlg('Incompatible data structure: Check dimension and Origin  ','Write Error'); 
    end
end

return;
