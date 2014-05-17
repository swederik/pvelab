function att_length=calcAttEllipse(numberOfProjections, numberOfBins, PIXEL_SCALE, projection, PROJ_OFFSET, ELLIPSE )


att_length=zeros(1,numberOfBins);

%
% calculate angle:Structure ANGLE ,sine and cosine values for projection angles
%


angle=( projection - 1 + PROJ_OFFSET )*pi/numberOfProjections;
angleSIN = sin(angle);
angleCOS = cos(angle);



%
% Calculate angles
%

PROJANGLE = angle;
ELLANGLE = - (ELLIPSE.ANGLE*pi/180+PROJANGLE);
COSELL = cos(ELLANGLE);
SINELL = sin(ELLANGLE);

%
% Calculates coordinates for ellipse-centre in rotated coordinate-system
%

X = ELLIPSE.DX*angleCOS + ELLIPSE.DY*angleSIN;
Y = -ELLIPSE.DX*angleSIN + ELLIPSE.DY*angleCOS;

%
% Calculate attenuation-lengths
%

V_Ax2=ELLIPSE.VERAXIS*ELLIPSE.VERAXIS;
H_Ax2=ELLIPSE.HORAXIS*ELLIPSE.HORAXIS;
D1 = V_Ax2*SINELL*SINELL + H_Ax2*COSELL*COSELL;
mult=2.0 / (D1*10.0);

for MEMBER=1:numberOfBins
	POS = (MEMBER-(numberOfBins+1) / 2.0 ) * PIXEL_SCALE;
	C1 = POS*COSELL - X*COSELL - Y*SINELL;
	C2 = X*SINELL - Y*COSELL - POS*SINELL;
	
	D2 = V_Ax2*C1*SINELL +H_Ax2*C2*COSELL;
	D3 = V_Ax2*C1*C1 +H_Ax2*C2*C2 -H_Ax2*V_Ax2;
	DISCR = D2*D2 - D1*D3;
	if ( DISCR > 0 )
	    att_length(MEMBER) =  sqrt(DISCR) *mult;
	  else
	    att_length(MEMBER) = 0;
	end;

end;