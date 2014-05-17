function ReturnCoreg(varargin)
% Save returned data in AIR file
%
%
% Uses function:
%   SaveAir

userdat=get(gcbf,'userdata');

%______________________________________________________________________________
% Save registration matrix in air-format, 110203TD
% If a air filename is given
if(~isempty(userdat) & isfield(userdat,'files') & isfield(userdat.files,'AIR'))  ;        
    Struct.hdrO=ReadAnalyzeHdr(userdat.files.STD);
    Struct.hdrI=ReadAnalyzeHdr(userdat.files.RES{1});
    if(isempty(userdat.A))%No co-registration!!
        Struct.A=eye(4,4);
    else
        Struct.A=userdat.A{1};
    end

    Struct.descr='';

    message=SaveAir(userdat.files.AIR,Struct);
end
%______________________________________________________________________________
