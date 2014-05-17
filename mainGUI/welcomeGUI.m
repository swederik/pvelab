function welcomeGUI(figuresize)
%welcomeGUI function load and show a welcome image at startup.
%
% Input:
%   figurzsize : Size of mainGUI
%
% Output:
%
% Uses special functions:
%   detailsGUI
%____________________________________________
% M. Twadark and T. Dyrby, 300403, NRU
%SW version: 070403TD

% --- displays a nice welcome bitmap during program startup ----------
drawnow
welcomeFig=figure('resize','off',...
    'position',[figuresize(1)+figuresize(3)/2-155 figuresize(2)+figuresize(4)/2-220 310 420],...
    'MenuBar','none',...
    'NumberTitle','off');
axes('Units','pixels','position',[0 0 310 420]); 
temp=image(imread('welcome.bmp')); 
axis(gca,'off');
pause(2);
delete(welcomeFig);
drawnow
