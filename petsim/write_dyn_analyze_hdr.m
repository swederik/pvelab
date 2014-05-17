function [d]=write_dyn_analyze_hdr(d,machine_format, existtimeframe);

% Write Analyze Header from the structure d

d.file_name_hdr=[d.file_name(1:(length(d.file_name)-3)) 'hdr'];
fid   			= fopen([d.file_path d.file_name_hdr],'w',machine_format);

if fid > -1
   d.hdr.data_type 			= ['dsr      ' 0];
   d.hdr.db_name	  		= ['                 ' 0];
   if (isfield(d,'dim')&isfield(d,'parent'))
      d.hdr.dim    			= [4 1 1 1 1 0 0 0];d.hdr.dim(2:(1+length(d.dim(find(d.dim)))))= d.dim(find(d.dim));
   else
   	d.hdr.dim    			= [4 1 1 1 1 0 0 0];d.hdr.dim(2:(1+length(size(d.data))))   = size(d.data);
   end   
   d.hdr.pixdim 			= [4 0 0 0 0 0 0 0];d.hdr.pixdim(2:(1+length(d.vox))) = d.vox;
   d.hdr.vox_units			= [0 0 0 0];d.hdr.vox_units(1:min([3 length(d.vox_units)])) = d.vox_units(1:min([3 length(d.vox_units)]));
   d.hdr.vox_offset 		= d.vox_offset;
   d.hdr.calmin				= d.calib(1);
   d.hdr.calmax				= d.calib(2);
   switch d.precision
   case 'uint1'  % 1  bit
      d.hdr.datatype 		= 1;
      d.hdr.bitpix 			= 1;
      d.hdr.glmin			= 0;
      d.hdr.glmax 			= 1;
      d.hdr.funused1		= 1;   
   case 'uint8'  % 8  bit
      errordlg('You should write a float image','8 Bit Write Error');d=[];return;
   case 'int16'  % 16 bit
      d.hdr.datatype 		= 4;
      d.hdr.bitpix  		= 16;
      if abs(d.hdr.calmin)>abs(d.hdr.calmax)
         d.hdr.funused1  	= abs(d.hdr.calmin)/(2^15-1);
      else
         d.hdr.funused1	= abs(d.hdr.calmax)/(2^15-1);
      end
      d.hdr.glmin 			= round(d.hdr.funused1*d.hdr.calmin);
      d.hdr.glmax 			= round(d.hdr.funused1*d.hdr.calmax);
   case 'int32'  % 32 bit
      d.hdr.datatype 		= 8;
      d.hdr.bitpix  		= 32;
      if abs(d.hdr.calmin)>abs(d.hdr.calmax)
         d.hdr.funused1  	= abs(d.hdr.calmin)/(2^31-1);
      else
         d.hdr.funused1	= abs(d.hdr.calmax)/(2^31-1);
      end
      d.hdr.glmin 			= round(d.hdr.funused1*d.hdr.calmin);
      d.hdr.glmax 			= round(d.hdr.funused1*d.hdr.calmax);
   case 'float'  % float  (32 bit)
      d.hdr.datatype 		= 16;
      d.hdr.bitpix 	 		= 32;
      d.hdr.glmin 			= 0;
      d.hdr.glmax 			= 0;
      d.hdr.funused1 		= 1;
   case 'double' % double (64 bit) 
      d.hdr.datatype 		= 64;
      d.hdr.bitpix  		= 64;
      d.hdr.glmin 			= 0;
      d.hdr.glmax 			= 0;
      d.hdr.funused1 		= 1;
   otherwise
      errordlg('Unrecognised precision (d.type)','Write Error');d=[];return;
   end
   d.hdr.descrip 			= zeros(1,80);d.hdr.descrip(1:min([length(d.descrip) 79]))=d.descrip(1:min([length(d.descrip) 79]));
    if (existtimeframe)
       d.hdr.aux_file        	= ['exist-time-frames------' 0];    
   else
       d.hdr.aux_file           = ['none                   ' 0];
   end
   d.hdr.origin          	= [0 0 0 0 0];d.hdr.origin(1:length(d.origin))=d.origin;
   
   
   % write (struct) header_key
   %---------------------------------------------------------------------------
   fseek(fid,0,'bof');
   
   fwrite(fid,348,					'int32');
   fwrite(fid,d.hdr.data_type,	'char' );
   fwrite(fid,d.hdr.db_name,		'char' );
   fwrite(fid,0,					'int32');
   fwrite(fid,0,					'int16');
   fwrite(fid,'r',					'char' );
   fwrite(fid,'0',					'char' );
   
   
   % write (struct) image_dimension
   %---------------------------------------------------------------------------
   fseek(fid,40,'bof');
   
   fwrite(fid,d.hdr.dim,			'int16');
   fwrite(fid,d.hdr.vox_units,	'char' );
   fwrite(fid,zeros(1,8),			'char' );
   fwrite(fid,0,					'int16');
   fwrite(fid,d.hdr.datatype,	'int16');
   fwrite(fid,d.hdr.bitpix,		'int16');
   fwrite(fid,0,					'int16');
   fwrite(fid,d.hdr.pixdim,		'float');
   fwrite(fid,d.hdr.vox_offset,	'float');
   fwrite(fid,d.hdr.funused1,	'float');
   fwrite(fid,0,					'float');
   fwrite(fid,0,					'float');
   fwrite(fid,d.hdr.calmax,		'float');
   fwrite(fid,d.hdr.calmin,		'float');
   fwrite(fid,0,					'int32');
   fwrite(fid,0,					'int32');
   fwrite(fid,d.hdr.glmax,		'int32');
   fwrite(fid,d.hdr.glmin,		'int32');
   
   % write (struct) data_history
   %---------------------------------------------------------------------------
   fwrite(fid,d.hdr.descrip,		'char');
   fwrite(fid,d.hdr.aux_file,   	'char');
   fwrite(fid,0,           		'char');
   fwrite(fid,d.hdr.origin,     'uint16');
   fwrite(fid,zeros(1,85), 		'char');
   
   s   = ftell(fid);
   fclose(fid);
else
   errordlg('Cannot open file for writing  ','Write Error');d=[];return;
end


return;