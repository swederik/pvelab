function applymanualroicorr

% This function is used in the SPECTpipeline in order to apply the manual
% adjustment of the automatically delineated central Striatum ROIs on all
% the automatically delineated ROIs.
%
% Peter Steen Jensen
% NRU, 19/02-2010

Stri_dex_central_before = load('ROIStriatumdex_central.mat');
Stri_sin_central_before = load('ROIStriatumsin_central.mat');
Stri_central_corrected = load('ROIStriatum_central.mat');

% Quantify the manual striatum ROI adjustment based on size of movement of
% the ROI center
Stri_dex_x = Stri_dex_central_before.vertex{1}(:,1);
Stri_dex_y = Stri_dex_central_before.vertex{1}(:,2);
Stri_dex_geom = polygeom(Stri_dex_x,Stri_dex_y);
Stri_dex_center = Stri_dex_geom(2:3);

Stri_sin_x = Stri_sin_central_before.vertex{1}(:,1);
Stri_sin_y = Stri_sin_central_before.vertex{1}(:,2);
Stri_sin_geom = polygeom(Stri_sin_x,Stri_sin_y);
Stri_sin_center = Stri_sin_geom(2:3);

for i = 1:length(Stri_central_corrected.vertex)
    ROIname = Stri_central_corrected.regionname{Stri_central_corrected.region(i)};
    switch ROIname
        case 'Striatum dex'
            Stri_dex_corr_x = Stri_central_corrected.vertex{i}(:,1);
            Stri_dex_corr_y = Stri_central_corrected.vertex{i}(:,2);
            Stri_dex_corr_geom = polygeom(Stri_dex_corr_x,Stri_dex_corr_y);
            Stri_dex_corr_center = Stri_dex_corr_geom(2:3);
        case 'Striatum sin'
            Stri_sin_corr_x = Stri_central_corrected.vertex{i}(:,1);
            Stri_sin_corr_y = Stri_central_corrected.vertex{i}(:,2);
            Stri_sin_corr_geom = polygeom(Stri_sin_corr_x,Stri_sin_corr_y);
            Stri_sin_corr_center = Stri_sin_corr_geom(2:3);
    end
end

Stri_dex_move = Stri_dex_corr_center-Stri_dex_center;
Stri_sin_move = Stri_sin_corr_center-Stri_sin_center;

% Apply the manual adjustment to all the ROIs
AllROIs_before = load('AllROIs.mat');
AllROIs = AllROIs_before;

for i = 1:length(AllROIs.region)
    ROIname = AllROIs.regionname{AllROIs.region(i)};
    switch ROIname
        case {'Striatum dex','Caudatus dex','Putamen dex'}
            Stri_dex_move_rep = repmat(Stri_dex_move,length(AllROIs_before.vertex{i}),1);
            AllROIs.vertex{i} = AllROIs_before.vertex{i}+Stri_dex_move_rep;
        case {'Striatum sin','Caudatus sin','Putamen sin'}
            Stri_sin_move_rep = repmat(Stri_sin_move,length(AllROIs_before.vertex{i}),1);
            AllROIs.vertex{i} = AllROIs_before.vertex{i}+Stri_sin_move_rep;
    end
end
save AllROIs_corr.mat -struct AllROIs;

  

function [ geom, iner, cpmo ] = polygeom( x, y )
%POLYGEOM Geometry of a planar polygon
%
%   POLYGEOM( X, Y ) returns area, X centroid,
%   Y centroid and perimeter for the planar polygon
%   specified by vertices in vectors X and Y.
%
%   [ GEOM, INER, CPMO ] = POLYGEOM( X, Y ) returns
%   area, centroid, perimeter and area moments of
%   inertia for the polygon.
%   GEOM = [ area   X_cen  Y_cen  perimeter ]
%   INER = [ Ixx    Iyy    Ixy    Iuu    Ivv    Iuv ]
%     u,v are centroidal axes parallel to x,y axes.
%   CPMO = [ I1     ang1   I2     ang2   J ]
%     I1,I2 are centroidal principal moments about axes
%         at angles ang1,ang2.
%     ang1 and ang2 are in radians.
%     J is centroidal polar moment.  J = I1 + I2 = Iuu + Ivv

% H.J. Sommer III - 02.05.14 - tested under MATLAB v5.2
%
% sample data
% x = [ 2.000  0.500  4.830  6.330 ]';
% y = [ 4.000  6.598  9.098  6.500 ]';
% 3x5 test rectangle with long axis at 30 degrees
% area=15, x_cen=3.415, y_cen=6.549, perimeter=16
% Ixx=659.561, Iyy=201.173, Ixy=344.117
% Iuu=16.249, Ivv=26.247, Iuv=8.660
% I1=11.249, ang1=30deg, I2=31.247, ang2=120deg, J=42.496
%
% H.J. Sommer III, Ph.D., Professor of Mechanical Engineering, 337 Leonhard Bldg
% The Pennsylvania State University, University Park, PA  16802
% (814)863-8997  FAX (814)865-9693  hjs1@psu.edu  www.me.psu.edu/sommer/

% begin function POLYGEOM

% check if inputs are same size
if ~isequal( size(x), size(y) ),
    error( 'X and Y must be the same size');
end

% number of vertices
[ x, ns ] = shiftdim( x );
[ y, ns ] = shiftdim( y );
[ n, c ] = size( x );

% temporarily shift data to mean of vertices for improved accuracy
xm = mean(x);
ym = mean(y);
x = x - xm*ones(n,1);
y = y - ym*ones(n,1);

% delta x and delta y
dx = x( [ 2:n 1 ] ) - x;
dy = y( [ 2:n 1 ] ) - y;

% summations for CW boundary integrals
A = sum( y.*dx - x.*dy )/2;
Axc = sum( 6*x.*y.*dx -3*x.*x.*dy +3*y.*dx.*dx +dx.*dx.*dy )/12;
Ayc = sum( 3*y.*y.*dx -6*x.*y.*dy -3*x.*dy.*dy -dx.*dy.*dy )/12;
Ixx = sum( 2*y.*y.*y.*dx -6*x.*y.*y.*dy -6*x.*y.*dy.*dy ...
    -2*x.*dy.*dy.*dy -2*y.*dx.*dy.*dy -dx.*dy.*dy.*dy )/12;
Iyy = sum( 6*x.*x.*y.*dx -2*x.*x.*x.*dy +6*x.*y.*dx.*dx ...
    +2*y.*dx.*dx.*dx +2*x.*dx.*dx.*dy +dx.*dx.*dx.*dy )/12;
Ixy = sum( 6*x.*y.*y.*dx -6*x.*x.*y.*dy +3*y.*y.*dx.*dx ...
    -3*x.*x.*dy.*dy +2*y.*dx.*dx.*dy -2*x.*dx.*dy.*dy )/24;
P = sum( sqrt( dx.*dx +dy.*dy ) );

% check for CCW versus CW boundary
if A < 0,
    A = -A;
    Axc = -Axc;
    Ayc = -Ayc;
    Ixx = -Ixx;
    Iyy = -Iyy;
    Ixy = -Ixy;
end

% centroidal moments
xc = Axc / A;
yc = Ayc / A;
Iuu = Ixx - A*yc*yc;
Ivv = Iyy - A*xc*xc;
Iuv = Ixy - A*xc*yc;
J = Iuu + Ivv;

% replace mean of vertices
x_cen = xc + xm;
y_cen = yc + ym;
Ixx = Iuu + A*y_cen*y_cen;
Iyy = Ivv + A*x_cen*x_cen;
Ixy = Iuv + A*x_cen*y_cen;

% principal moments and orientation
I = [ Iuu  -Iuv ;
    -Iuv   Ivv ];
[ eig_vec, eig_val ] = eig(I);
I1 = eig_val(1,1);
I2 = eig_val(2,2);
ang1 = atan2( eig_vec(2,1), eig_vec(1,1) );
ang2 = atan2( eig_vec(2,2), eig_vec(1,2) );

% return values
geom = [ A  x_cen  y_cen  P ];
iner = [ Ixx  Iyy  Ixy  Iuu  Ivv  Iuv ];
cpmo = [ I1  ang1  I2  ang2  J ];

% end of function POLYGEOM