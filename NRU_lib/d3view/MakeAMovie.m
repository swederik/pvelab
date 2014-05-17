function MakeAMovie1(filename,N)
%
% function MakeAMovie(filename,N)
%
% Creates an .avi movie from current plot axis by a full rotation 
% in \theta, followed by a full rotation in \phi
%
% Copyright PW, NRU, 2001
%
%  There is some problems in keeping the center of ration constant and it 
%  requires some manual editing. A way to do this is to decide where the center of the brain are
%  and then use that as center of the axis. The size in each direction has to be the same, else
%  the display will change when rotated. An example of doing this is given below. Original the
%  axes was:
%   
%   Xlim=[-128 127]
%   Ylim=[-128 127]
%   Zlim=[-160 100]
%
%  Manual rotation of the image along the axis's then shows that the brain direction having largest lenght
%  is the Y direction (approx 160) Therefore it was decided to have 180 along each axes. It is then decided
%  where the center for each axis should be and the 180 is then distributed around these values. In this 
%  example as:
%
%   Xlim=[-132 58]
%   Ylim=[-115 75]
%   Zlim=[-98 82]
%
%  CS, 21-11-2002
%

if nargin==2
    
    set(gca,'CameraViewAngleMode','manual');
    %lights=findobj(gcf,'type','light');
    %states=get(lights,'visible');
    %set(lights,'visible','off');
    FPS=10;   % Frames pr. sec.
    dtheta=360/(N-1)
    dphi=360/(N-1)
    M=moviein(2*N-1);
    %camlight headlight
    %camlight headlight
    set(gca,'cameratargetmode','manual');
    figsiz=get(gcf,'position');
    figsiz(3:4)=ceil(figsiz(3:4)/8)*8;
    set(gcf,'position',figsiz);   % AVI previewers often require that the
                                  % frame size is multiplum of 8
    figsiz=get(gcf,'position');
    figsiz(1:2)=1;
    h=gcf;
    %h=gca;
    %ViewSize=[-64 -64 128 128];
    %    vu=get(uh1,'vertices');
    %    vu(:,3)=vu(:,3)-2*N;
    %    vd1=get(dh1,'vertices');
    %    vd1(:,3)=vd1(:,3)+2*N;
    %    vd2=get(dh2,'vertices');
    %    vd2(:,3)=vd2(:,3)+2*N;
    %    set(uh1,'vertices',vu);
    %    set(dh1,'vertices',vd1);
    %    set(dh2,'vertices',vd2);
    %    for j=1:2*N
    %      vu=get(uh1,'vertices');
    %      vu(:,3)=vu(:,3)+1;
    %      vd1=get(dh1,'vertices');
    %      vd1(:,3)=vd1(:,3)-1;
    %      vd2=get(dh2,'vertices');
    %      vd2(:,3)=vd2(:,3)-1;
    %      set(uh1,'vertices',vu);
    %      set(dh1,'vertices',vd1);
    %      set(dh2,'vertices',vd2);
    %      M(:,j)=getframe(h,figsiz);
    %    end
    [Path File]=fileparts(filename);
    if strncmp(computer,'PCWIN',5)
%        mov=avifile([fullfile(Path,File) '.avi'],'compression','indeo5','fps',FPS);
        mov=avifile([fullfile(Path,File) '.avi'],'fps',FPS);
    else   
        mov=avifile([fullfile(Path,File) '.avi'],'fps',FPS);
    end
    for j=1:N-1
        camorbit(dtheta,0,'camera');
        camlight headlight
        %camlight headlight
        M=getframe(h,figsiz);
        mov=addframe(mov,M);
        delete(findobj('type','light','tag',''))
    end
    for j=1:N-1
        camorbit(0,dphi,'camera');
        camlight headlight
        %camlight headlight
        M=getframe(h,figsiz);
        mov=addframe(mov,M);
        delete(findobj('type','light','tag',''))
    end
    mov=close(mov);
    disp('done');
else
    error(['Please give me a filename to save the movie to, and a' ...
            ' number of movie frames to do the rotiations in!']);
end