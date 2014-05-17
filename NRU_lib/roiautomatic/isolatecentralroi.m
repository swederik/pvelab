function isolatecentralroi

% This function is used in the SPECTpipeline in order to isolate the
% central ROI from the five adjacent striatum ROIs in the input file.
%
% Peter Steen Jensen
% NRU, 08/03-2010

[StridexROIfile,StridexROIpath] = fileparts('ROIStriatumdex.mat');
S1 = load(strcat(StridexROIpath, StridexROIfile));
S1_central = S1;

[StrisinROIfile,StrisinROIpath] = fileparts('ROIStriatumsin.mat');
S2 = load(strcat(StrisinROIpath, StrisinROIfile));
S2_central = S2;

S1_central.mode = S1.mode(3);
S1_central.region = S1.region(3);
S1_central.relslice = S1.relslice(3);
S1_central.vertex = S1.vertex(3);

S2_central.mode = S2.mode(3);
S2_central.region = S2.region(3);
S2_central.relslice = S2.relslice(3);
S2_central.vertex = S2.vertex(3);

StriROI_central.filetype = S1_central.filetype;
StriROI_central.mode = [S1_central.mode;S2_central.mode];
StriROI_central.region = [1;2];
StriROI_central.regionname = [S1_central.regionname;S2_central.regionname];
StriROI_central.relslice = [S1_central.relslice;S2_central.relslice];
StriROI_central.slicedist = S1_central.slicedist;
StriROI_central.vertex = [S1_central.vertex;S2_central.vertex];

save ROIStriatumdex_central.mat -struct S1_central;
save ROIStriatumsin_central.mat -struct S2_central;
save ROIStriatum_central.mat -struct StriROI_central;