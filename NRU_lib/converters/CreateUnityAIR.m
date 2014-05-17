function []=CreateUnityAIR(Filename)
%
% []=CreateUnityAIR([Filename])
%
% Create and AIR with the unity transformation for a selected analyze file
%
%   Fielane - Analyze file for which to create the hopmogene unity
%   transformation - eye(4)
%
if nargin==0
    [fn,pn]=uigetfile('*.img','Select the analyze file?');
    if (fn==0)
        error('CreateUnityAIR: No analyze file selected');
    end
    Filename=[pn,fn];
end
%
hdr=ReadAnalyzeHdr(Filename);
strct.A=eye(4);
[pn,fn]=fileparts(Filename);
strct.descr=sprintf('Identify transformation for %s',fn);
if length(strct.descr)>80
    strct.descr=strct.descr(1:79);
end
strct.endian='ieee-le';
strct.nruformat=0;
strct.hdrI=hdr;
strct.hdrO=hdr;
SaveAir([fn '.air'],strct);
