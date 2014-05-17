function outsino=ScatterCorrGE4096( insino , DIAM, camera)


% ALNFLG always true on the GE4096 scanner!
ALNFLG = true;


%
% camera parameters
%

PC384_SCALE=camera.scatterscale; % from REC_SCATTER_PARAMETERS.DEF
FOV=camera.FOV/10; % Filed of View of the camera


PROJ_OFFSET=camera.projectionOffset;      % from the PC_PAR:PCAM_*.par

%
% other important parameters:
%


PIXEL_SCALE = camera.pixelSize;    % the mm/pixel ratio from the reconstruction program

%
%	The ellipse structure :
%

ELLIPSE = struct( 'ANGLE', 0, 'DX',0, 'DY', 0, 'HORAXIS', 0, 'VERAXIS', 0);
ELLIPSE.HORAXIS=100; % half width of the horizontal axis in mm ( 100 )
ELLIPSE.VERAXIS=100; % half width of the vertical axis in mm ( 100 )

%
% scatter & camera parameters:
%

A1 = camera.A1;
A2 = camera.A2;
A3 = camera.A3;
A4 = camera.A4;
A5 = camera.A5;
A6 = camera.A6;
A7 = camera.A7;
A8 = camera.A8;
A10 = camera.A10;
A11 = camera.A11;
A12 = camera.A12;
A13 = camera.A13;
A14 = camera.A14;
A15 = camera.A15;
A16 = camera.A16;
A18 = camera.A18;
A21 = camera.A21;



%
% local variables:
%


pixel_ratio=PIXEL_SCALE / PC384_SCALE;

numberOfBins = size(insino, 1 );
numberOfProjections=size(insino, 2);

outsino=zeros(size(insino));

idx=[1:numberOfBins]+numberOfBins;

for projection=1:numberOfProjections


	%
	% calclate attenuation for ellipse
	%

	ATT_LENGTH=calcAttEllipse( numberOfProjections, numberOfBins, PIXEL_SCALE, projection, PROJ_OFFSET,  ELLIPSE);


	%
	% calculate center:
	%

	ATTSUM=0;
	MOMSUM=0;
	MOMSUM=sum(ATT_LENGTH.*[1:numberOfBins]);
	ATTSUM=sum(ATT_LENGTH);
	if (ATTSUM~=0) 
	  CENTRE=MOMSUM/ATTSUM;
	else
	  CENTRE = numberOfBins+1/2.0;
	end;

	%
	% Calculate scatter factors
	%

    for member=1:numberOfBins
		  POS = ( abs(CENTRE-member) + 0.5 ) * pixel_ratio;


		FACT1(member)=A1 * (A2-A3*POS)*(A7-A8*exp(-0.1*POS))*(A10-A11);

	    FACT2(member)=A12*POS*(1-A13*POS)*(1-A15*exp(-POS*A16));
	    FACT3(member)=A5*(1+A6*POS);
	
		if ( DIAM~=200 )
	    	FACT1(member)=FACT1(member)*(A4-(A4-1)*exp((DIAM-200)*A18));
		    FACT2(member)=FACT2(member)*(1-A14*(200-DIAM));
		    FACT3(member)=FACT3(member)*(1-A21*(200-DIAM));
		end;
	end;

	%
	% Compensate for pixel size
	%
	
	FACT1 = FACT1 * pixel_ratio;
	FACT2 = FACT2 * pixel_ratio;
	FACT3 = FACT3 * pixel_ratio;

	%
	% Do the exponentiation once and for all
	%
	
	if (ALNFLG==true)
		FACT3=exp(-FACT3);
	end;	



	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  SCATTER CORRECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%
	% Clear scatter array
	%
	SCATTER=zeros(numberOfBins,1);	

	%
	% Definition of convolution function
	%

	CONV=zeros(numberOfBins*2,1);

    for member=1:numberOfBins
        CONV(numberOfBins)=1.0;
        TEMP=1;
 		for i=1:numberOfBins-1;
 		  TEMP=FACT3(member)*TEMP;
 		  CONV(numberOfBins+i)=TEMP;
 		  CONV(numberOfBins-i)=TEMP;
        end;
        
        
		%     
		% Calculate scatter for current member
		%
	
		f1=FACT1(member)*insino(member, projection);
		f2=FACT2(member)*insino(member, projection);

        SCATTER=SCATTER+CONV(idx-member).*f1;

        for scatmem=1:numberOfBins
             if ( (scatmem<member && member<=CENTRE) || (scatmem>member && member>=CENTRE+1 ))
 				 SCATTER(scatmem)=SCATTER(scatmem)+f2;
             end;
         end;
     end;

	outsino(:,projection)=SCATTER;

end;
