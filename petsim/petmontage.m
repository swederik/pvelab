function h = petmontage(a,handle)
%MONTAGE Display multiple image frames as rectangular montage.
%   MONTAGE displays all the frames of a multiframe image array
%   in a single image object, arranging the frames so that they
%   roughly form a square.
%
%   MONTAGE(XP) displays the K frames of the indexed image
%   array X. X is M-by-N-by-K.
%
%   H = MONTAGE(...) returns the handle to the image object.
%
%   Class support
%   -------------
%   The input image can be logical, uint8, uint16, or double.  The map must
%   be double.  The output is a handle to the graphics objects produced by
%   this function.
%

%   Copyright 1993-2003 The MathWorks, Inc.  
%   $Revision: 5.20 $  $Date: 2003/01/17 16:27:47 $




siz = [size(a,1) size(a,2) size(a,3)];
nn = sqrt(prod(siz))/siz(2);
mm = siz(3)/nn;
if (ceil(nn)-nn) < (ceil(mm)-mm),
  nn = ceil(nn); mm = ceil(siz(3)/nn);
else
  mm = ceil(mm); nn = ceil(siz(3)/mm);
end

b = a(1,1); % to inherit type 
b(1,1) = 0; % from a
b = repmat(b, [mm*siz(1), nn*siz(2), 1]);

rows = 1:siz(1); cols = 1:siz(2);
for i=0:mm-1,
  for j=0:nn-1,
    k = j+i*nn+1;
      if k<=siz(3),
         b(rows+i*siz(1),cols+j*siz(2)) = a(:,:,k);
        end;
    end
end


if handle==-1
      h=imagesc(b);
else
   set(handle,'CData', b );
   h=handle;
end;











