function OutputImage=spatialResolution(input_Image, resolution_Values_mm, resolution_Radius_Vector_mm, pixel_Size )

[m,n]=size( input_Image );
OutputImage=zeros(m,n);

% fit the curve ( the FWHM values )
fittedCurve = polyfit( resolution_Radius_Vector_mm, resolution_Values_mm, 2 );

xCenter=m/2;
yCenter=n/2;

for x=1:m
    dx2 = (x-xCenter)^2;
    for y=1:n
        voxel=input_Image( x,y);
        if ( voxel ~= 0 )
        r=sqrt( dx2+(y-yCenter)^2  )*pixel_Size;
        fwhm = r^2*fittedCurve(1)+fittedCurve(2)*r+fittedCurve(3);
     
        [convKernel,kernelSize]=gausskernel(fwhm);
        trg=conv2(voxel,convKernel,'full');

        hks=round(kernelSize/2);
        sx=x-hks;
        ex=x+hks;
        sy=y-hks;
        ey=y+hks;
        a=1;
        for i=sx:ex
           b=1;
           for j=sy:ey
             if ( (i >0) && ( j>0 ) && ( i<=m ) && ( j<=n ) && (a<=kernelSize ) && (b<=kernelSize) )
                OutputImage( i,j )=OutputImage( i,j )+trg( a,b);
             end;
             b=b+1;
           end;
           a=a+1;
        end;
    end;
  end;
end;
