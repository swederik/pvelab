function FixAnalyzeHdr(arg1)
%
% A program with a gui, which make it posible to read, write and
% fix analyze headers. 
%
%	function FixAnalyzeHdr
%
% cmm, 030200
%
% Added support for 4 diminsions: cmm 260500
% Added endian support: TR 191203
%

if nargin == 0
  scsize=get(0,'screensize');
  
  if isempty(findobj('tag','FixAnalyzeHdrFig'))
    f1 =figure('position',[.1*scsize(3) .3*scsize(4) 420 510],...
	       'tag','FixAnalyzeHdrFig',...
	       'CloseRequestFcn', 'FixAnalyzeHdr(''close'')',...
           'menubar','none',...
           'name','FixAnalyzeHdr',...
           'numberTitle','off',...
	       'Resize','Off'); 
    
    
    
    %
    % Offset to gui
    %  
    dimOffset = 380-70;
    sizeOffset = 330-70;
    originOffset = 280-70;
    scaleoffsetOffset = 230-70;
    limitOffset = 130-70;
    precissionOffset = 180-70;
    opencloseOffset = 490-70;
    
    
    %
    %
    %
    uicontrol('style','frame',...
	      'position',[20 opencloseOffset-50 380 110],...
	      'HorizontalAlignment','left',...
	      'string','filename',...
	      'backgroundcolor',[.7 .7 .7]);
    
    %
    % Open file
    %
    uicontrol('style','pushbutton',...
	      'callback','FixAnalyzeHdr(''openfile'')',...
	      'position',[30 opencloseOffset 80 40],...
	      'string','Open');
    
    %
    % New file
    %
    uicontrol('style','pushbutton',...
	      'callback','FixAnalyzeHdr(''newfile'')',...
	      'position',[120 opencloseOffset 80 40],...
	      'string','New');
    
    
    %
    % Save file
    %
    uicontrol('style','pushbutton',...
	      'enable','off',...
	      'enable','off',...
	      'tag','u15',...
	      'callback','FixAnalyzeHdr(''savefile'')',...
	      'position',[210 opencloseOffset 80 40],...
	      'string','Save');
    
    %
    % Apply to files
    %
    uicontrol('style','pushbutton',...
	      'tag','u16',...
	      'enable','off',...
	      'callback','FixAnalyzeHdr(''ApplyToFiles'')',...
	      'position',[300 opencloseOffset 80 40],...
	      'string','Apply to files');
    
    uicontrol('style','text',...
	      'position',[30 opencloseOffset-40 250 17],...
	      'HorizontalAlignment','left',...
	      'tag','t1',...
	      'string','filename',...
	      'backgroundcolor',[.8 .8 .8]);
    
    %
    % Diminsion
    %
    uicontrol('style','text',...
	      'position',[30 dimOffset+17 100 20],...
	      'HorizontalAlignment','left',...
	      'string','Diminsion',...
	      'backgroundcolor',[.8 .8 .8]);
    
    uicontrol('style','edit',...
	      'enable','off',...
	      'tag','u12',...
	      'callback','',...
	      'position',[50 dimOffset 50 20],...
	      'string','');
    uicontrol('style','text',...
	      'position',[30 dimOffset-3 20 20],...
	      'HorizontalAlignment','left',...
	      'string','x:',...
	      'backgroundcolor',[.8 .8 .8]);
    
    uicontrol('style','edit',...
	      'enable','off',...
	      'tag','u13',...
	      'enable','off',...
	      'callback','',...
	      'position',[150 dimOffset 50 20],...
	      'string','');
    uicontrol('style','text',...
	      'position',[130 dimOffset-3 20 20],...
	      'HorizontalAlignment','left',...
	      'string','y:',...
	      'backgroundcolor',[.8 .8 .8]);
    
    uicontrol('style','edit',...
	      'enable','off',...
	      'tag','u14',...
	      'callback','',...
	      'position',[250 dimOffset 50 20],...
	      'string','');
    uicontrol('style','text',...
	      'position',[230 dimOffset-3 20 20],...
	      'HorizontalAlignment','left',...
	      'string','z:',...
	      'backgroundcolor',[.8 .8 .8]);
    
    uicontrol('style','edit',...
	      'enable','off',...
	      'tag','u14a',...
	      'visible','off',...
	      'callback','',...
	      'position',[350 dimOffset 50 20],...
	      'string','');
    uicontrol('style','text',...
	      'position',[330 dimOffset-3 20 20],...
	      'HorizontalAlignment','left',...
	      'tag','u14b',...
	      'visible','off',...
	      'string','t:',...
	      'backgroundcolor',[.8 .8 .8]);
    
    
    %
    % Size
    %
    uicontrol('style','text',...
	      'position',[30 sizeOffset+17 100 20],...
	      'HorizontalAlignment','left',...
	      'string','Size',...
	      'backgroundcolor',[.8 .8 .8]);
    
    uicontrol('style','edit',...
	      'enable','off',...
	      'callback','',...
	      'tag','u9',...
	      'position',[50 sizeOffset 50 20],...
	      'string','');
    uicontrol('style','text',...
	      'position',[30 sizeOffset-3 20 20],...
	      'HorizontalAlignment','left',...
	      'string','x:',...
	      'backgroundcolor',[.8 .8 .8]);
    
    uicontrol('style','edit',...
	      'enable','off',...
	      'tag','u10',...
	      'callback','',...
	      'position',[150 sizeOffset 50 20],...
	      'string','');
    uicontrol('style','text',...
	      'position',[130 sizeOffset-3 20 20],...
	      'HorizontalAlignment','left',...
	      'string','y:',...
	      'backgroundcolor',[.8 .8 .8]);
    
    uicontrol('style','edit',...
	      'enable','off',...
	      'tag','u11',...
	      'callback','',...
	      'position',[250 sizeOffset 50 20],...
	      'string','');
	uicontrol('style','text',...
		'position',[230 sizeOffset-3 20 20],...
		'HorizontalAlignment','left',...
		'string','z:',...
		'backgroundcolor',[.8 .8 .8]);

	%
	% Origin
	%
	uicontrol('style','text',...
		'position',[30 originOffset+17 100 20],...
		'HorizontalAlignment','left',...
		'string','Origin',...
		'backgroundcolor',[.8 .8 .8]);

	uicontrol('style','edit',...
		'enable','off',...
		'callback','',...
	        'tag','u6',...
		'position',[50 originOffset 50 20],...
		'string','');
	uicontrol('style','text',...
		'position',[30 originOffset-3 20 20],...
		'HorizontalAlignment','left',...
		'string','x:',...
		'backgroundcolor',[.8 .8 .8]);

	uicontrol('style','edit',...
		'enable','off',...
		'callback','',...
	        'tag','u7',...
		'position',[150 originOffset 50 20],...
		'string','');
	uicontrol('style','text',...
		'position',[130 originOffset-3 20 20],...
		'HorizontalAlignment','left',...
		'string','y:',...
		'backgroundcolor',[.8 .8 .8]);

	uicontrol('style','edit',...
		'enable','off',...
	        'tag','u8',...
		'callback','',...
		'position',[250 originOffset 50 20],...
		'string','');
	uicontrol('style','text',...
		'position',[230 originOffset-3 20 20],...
		'HorizontalAlignment','left',...
		'string','z:',...
		'backgroundcolor',[.8 .8 .8]);



	%
	% scale offset
	%
	uicontrol('style','text',...
		'position',[30 scaleoffsetOffset+17 100 20],...
		'HorizontalAlignment','left',...
		'string','Scale',...
		'backgroundcolor',[.8 .8 .8]);

	uicontrol('style','text',...
		'position',[130 scaleoffsetOffset+17 100 20],...
		'HorizontalAlignment','left',...
		'string','Offset',...
		'backgroundcolor',[.8 .8 .8]);

	uicontrol('style','edit',...
		'enable','off',...
		'tag','u5',...
		'callback','',...
		'position',[30 scaleoffsetOffset 50 20],...
		'string','');

	uicontrol('style','edit',...
		'enable','off',...
		'callback','',...
		'tag','u4',...
		'position',[130 scaleoffsetOffset 50 20],...
		'string','');

	%
	% Limit
	%
	uicontrol('style','text',...
		'position',[30 limitOffset+17 100 20],...
		'HorizontalAlignment','left',...
		'string','Limit:',...
		'backgroundcolor',[.8 .8 .8]);

	uicontrol('style','edit',...
		'enable','off',...
		'callback','',...
		'tag','u3',...
		'position',[170 limitOffset 50 20],...
		'string','');
	uicontrol('style','text',...
		'position',[130 limitOffset-3 30 20],...
		'HorizontalAlignment','left',...
		'string','max:',...
		'backgroundcolor',[.8 .8 .8]);

	uicontrol('Parent',f1, ...
		'style','edit',...
		'enable','off',...
		'callback','',...
		'tag','u2',...
		'position',[70 limitOffset 50 20],...
		'string','');

	uicontrol('style','text',...
		'position',[30 limitOffset-3 30 20],...
		'HorizontalAlignment','left',...
		'string','min:',...
		'backgroundcolor',[.8 .8 .8]);



	%
	% Precission
	%
	uicontrol('style','text',...
		'position',[30 precissionOffset+17 100 20],...
		'HorizontalAlignment','left',...
		'string','Precission:',...
		'backgroundcolor',[.8 .8 .8]);

	uicontrol('Parent',f1, ...
		'callback','FixAnalyzeHdr(''precis'')',...
		'BackgroundColor',[0.8 0.8 0.8], ...
		'ListboxTop',0, ...
		'Max',2, ...
		'Min',1, ...
		'Tag','u1', ...
		'Enable', 'off',...
		'Position',[30 precissionOffset-10 100 20], ...
		'String',{'2 bit' '8 bit' '16 bit signed' '16 bit unsigned' '32 bit' '64 bit'}, ...
		'Style','popupmenu', ...
		'Value',1);

	%
	% Endian
	%
	uicontrol('style','text',...
		'position',[190 precissionOffset+17 100 20],...
		'HorizontalAlignment','left',...
		'string','Endian:',...
		'backgroundcolor',[.8 .8 .8]);

	uicontrol('Parent',f1, ...
		'BackgroundColor',[0.8 0.8 0.8], ...
		'ListboxTop',0, ...
		'Max',2, ...
		'Min',1, ...
		'Tag','UIendian', ...
		'Enable', 'off',...
		'Position',[190 precissionOffset-10 100 20], ...
		'String',{'ieee-be' 'ieee-le'}, ...
		'Style','popupmenu', ...
		'Value',1);
    
    
	%
	% Description
	%
	uicontrol('style','text',...
      		'position',[30 limitOffset+17-40 100 20],...
      		'HorizontalAlignment','left',...
      		'string','Description',...
      		'backgroundcolor',[.8 .8 .8]);

	uicontrol('style','edit',...
      		'enable','off',...
		'tag','descr',...
		'horizontalAlignment','left',...
		'callback','',...
		'position',[30 limitOffset-40 370 20],...
		'string','');


	
	if isempty(findobj('tag','FixAnalyzeHdrFig2'))
	  f2 = figure('position',[.1*scsize(3)+430 .3*scsize(4) 600 510],...
		      'tag','FixAnalyzeHdrFig2',...
		      'CloseRequestFcn','set(gcf,''visible'',''off'')',...
		      'visible','off',...	
              'menubar','none',...
              'name','FixAnalyzeHdr - multifile',...
              'numberTitle','off',...
		      'Resize','Off'); 
	  

	  %
	  % Offset to gui
	  %  
	  dimOffset = 370+60;
	  sizeOffset = 300+60;
	  originOffset = 230+60;
	  scaleoffsetOffset = 160+60;
	  limitOffset = 30+60;
	  precissionOffset = 120+60;
	  leftoffset = 0;
	  
	  
	  
	  %
	  % Choose files
	  %
	  h.u(61)=uicontrol('style','pushbutton',...
			    'tag','u61',...
			    'callback','FixAnalyzeHdr(''ReadFiles'')',...
			    'position',[320 20 100 40],...
			    'string','Choose Files ...');
	  
	  h.u(63)=uicontrol('style','pushbutton',...
			    'tag','u63',...
			    'enable','off',...
			    'callback','FixAnalyzeHdr(''applyChanges'')',...
			    'position',[420 20 100 40],...
			    'string','Apply to files ...');
	  
	  h.u(62) = uicontrol('Parent',f2, ...
			      'Position',[320 75 200 330], ...
			      'String', ' ', ...
			      'Style','listbox', ...
			      'Tag','u62', ...
			      'Value',1);
	  
	  %
	  % Diminsion
	  %
	  uicontrol('style','frame',...
		    'position',[leftoffset+20 dimOffset-13 290 60],...
		    'HorizontalAlignment','left');
	  
	  
	  h.u(150)=uicontrol('style','checkbox',...
			     'position',[leftoffset+30 dimOffset+17 100 20],...
			     'HorizontalAlignment','left',...
			     'string','Diminsion',...
			     'Tag','u150', ...
			     'backgroundcolor',[.8 .8 .8]);
	  
	  h.u(112)=uicontrol('style','edit',...
			     'enable','off',...
			     'callback','',...
			     'Tag','u112', ...
			     'position',[leftoffset+50 dimOffset-5 50 20],...
			     'string','');
	  uicontrol('style','text',...
		    'position',[leftoffset+30 dimOffset-3-5 20 20],...
		    'HorizontalAlignment','left',...
		    'string','x:',...
		    'backgroundcolor',[.8 .8 .8]);
	  
	  h.u(113)=uicontrol('style','edit',...
			     'enable','off',...
			     'callback','',...
			     'Tag','u113', ...
			     'position',[leftoffset+150 dimOffset-5 50 20],...
			     'string','');
	  uicontrol('style','text',...
		    'position',[leftoffset+130 dimOffset-3-5 20 20],...
		    'HorizontalAlignment','left',...
		    'string','y:',...
		    'backgroundcolor',[.8 .8 .8]);
	  
	  h.u(114)=uicontrol('style','edit',...
			     'enable','off',...
			     'callback','',...
			     'Tag','u114', ...
			     'position',[leftoffset+250 dimOffset-5 50 20],...
			     'string','');
	  uicontrol('style','text',...
		'position',[leftoffset+230 dimOffset-3-5 20 20],...
		    'HorizontalAlignment','left',...
		    'string','z:',...
		    'backgroundcolor',[.8 .8 .8]);
	  
	  
	  %
	  % Size
	  %
	  
	  uicontrol('style','frame',...
		    'position',[leftoffset+20 sizeOffset-13 290 60],...
		    'HorizontalAlignment','left');
	  
	  h.u(151)=uicontrol('style','checkbox',...
			     'position',[leftoffset+30 sizeOffset+17 100 20],...
			     'HorizontalAlignment','left',...
			     'string','Size',...
			     'Tag','u151', ...
			     'backgroundcolor',[.8 .8 .8]);
	  
	  h.u(109)=uicontrol('style','edit',...
			     'enable','off',...
			     'callback','',...
			     'Tag','u109', ...
			     'position',[leftoffset+50 sizeOffset-5 50 20],...
			     'string','');
	  uicontrol('style','text',...
		    'position',[leftoffset+30 sizeOffset-3-5 20 20],...
		    'HorizontalAlignment','left',...
		    'string','x:',...
		    'backgroundcolor',[.8 .8 .8]);
	  
	  h.u(110)=uicontrol('style','edit',...
			     'enable','off',...
			     'callback','',...
			     'Tag','u110', ...
			     'position',[leftoffset+150 sizeOffset 50-5 20],...
			     'string','');
	  uicontrol('style','text',...
		    'position',[leftoffset+130 sizeOffset-3 20-5 20],...
		    'HorizontalAlignment','left',...
		    'string','y:',...
		    'backgroundcolor',[.8 .8 .8]);
	  
	  h.u(111) = uicontrol('style','edit',...
			       'enable','off',...
			       'callback','',...
			       'Tag','u111', ...
			       'position',[leftoffset+250 sizeOffset 50-5 20],...
			       'string','');
	  uicontrol('style','text',...
		    'position',[leftoffset+230 sizeOffset-3 20-5 20],...
		    'HorizontalAlignment','left',...
		    'string','z:',...
		    'backgroundcolor',[.8 .8 .8]);
	  
	  %
	  % Origin
	  %
	  
	  uicontrol('style','frame',...
		    'position',[leftoffset+20 originOffset-13 290 60],...
		    'HorizontalAlignment','left');
	  
	  h.u(152)=uicontrol('style','checkbox',...
			     'position',[leftoffset+30 originOffset+17 100 20],...
			     'HorizontalAlignment','left',...
			     'callback','',...
			     'Tag','u152', ...
			     'string','Origin',...
			     'backgroundcolor',[.8 .8 .8]);
	  
	  h.u(106)=uicontrol('style','edit',...
			     'enable','off',...
			     'callback','',...
			     'Tag','u106', ...
			     'position',[leftoffset+50 originOffset-5 50 20],...
			     'string','');
	  uicontrol('style','text',...
		    'position',[leftoffset+30 originOffset-3-5 20 20],...
		    'HorizontalAlignment','left',...
		    'string','x:',...
		    'backgroundcolor',[.8 .8 .8]);
	  
	  h.u(107)=uicontrol('style','edit',... 
			     'Tag','u107', ...
			     'enable','off',...
			     'callback','',...
			     'position',[leftoffset+150 originOffset-5 50 20],...
			     'string','');
	  uicontrol('style','text',...
		    'position',[leftoffset+130 originOffset-3-5 20 20],...
		    'HorizontalAlignment','left',...
		    'string','y:',...
		    'backgroundcolor',[.8 .8 .8]);
	  
	  h.u(108) = uicontrol('style','edit',...
			       'Tag','u108', ...
			       'enable','off',...
			       'callback','',...
			       'position',[leftoffset+250 originOffset-5 50 20],...
			       'string','');
	  uicontrol('style','text',...
		'position',[leftoffset+230 originOffset-3-5 20 20],...
		'HorizontalAlignment','left',...
		'string','z:',...
		'backgroundcolor',[.8 .8 .8]);



	%
	% scale offset
	%

	uicontrol('style','frame',...
		'position',[leftoffset+20 scaleoffsetOffset-13 115 60],...
		'HorizontalAlignment','left');

	uicontrol('style','frame',...
		'position',[leftoffset+20+125 scaleoffsetOffset-13 115 60],...
		'HorizontalAlignment','left');

	h.u(153)=uicontrol('style','checkbox',...
		'position',[leftoffset+30 scaleoffsetOffset+17 100 20],...
		'HorizontalAlignment','left',...
		'Tag','u153', ...
		'string','Scale',...
		'backgroundcolor',[.8 .8 .8]);

	h.u(105)=uicontrol('style','edit',...
		'enable','off',...
		'tag','scale',...
		'Tag','u105', ...
		'callback','',...
		'position',[leftoffset+30 scaleoffsetOffset-3-5 50 20],...
		'string','');



	h.u(154)=uicontrol('style','checkbox',...
		'position',[leftoffset+130+20 scaleoffsetOffset+17 100 20],...
		'HorizontalAlignment','left',...
		'Tag','u154', ...
		'backgroundcolor',[.8 .8 .8],...
		'string','Offset');


	h.u(104)=uicontrol('style','edit',...
		'enable','off',...
		'callback','',...
		'Tag','u104', ...
		'position',[leftoffset+130+20 scaleoffsetOffset-8 50 20],...
		'string','');

	%
	% Limit
	%

	uicontrol('style','frame',...
		'position',[leftoffset+20 limitOffset-13 290 120],...
		'HorizontalAlignment','left');

	h.u(103)=uicontrol('style','edit',...
		'Tag','u103', ...
		'enable','off',...
		'callback','',...
		'position',[leftoffset+170 limitOffset 50 20],...
		'string','');
	uicontrol('style','text',...
		'position',[leftoffset+130 limitOffset-3 30 20],...
		'HorizontalAlignment','left',...
		'string','max:',...
		'backgroundcolor',[.8 .8 .8]);

	h.u(102)=uicontrol('style','edit',...
		'enable','off',...
		'callback','',...
		'Tag','u102', ...
		'position',[leftoffset+70 limitOffset 50 20],...
		'string','');
	uicontrol('style','text',...
		'position',[leftoffset+30 limitOffset-3 30 20],...
		'HorizontalAlignment','left',...
		'string','min:',...
		'backgroundcolor',[.8 .8 .8]);



	%
	% Precission
	%
	h.u(155)=uicontrol('style','checkbox',...
		'position',[leftoffset+30 precissionOffset-17 100 20],...
		'HorizontalAlignment','left',...
		'Tag','u155', ...
		'string','Precission:',...
		'backgroundcolor',[.8 .8 .8]);

	h.u(101) = uicontrol('Parent',f2, ...
		'Tag','u101', ...
		'callback','FixAnalyzeHdr_precis',...
		'BackgroundColor',[0.701960784313725 0.701960784313725 0.701960784313725], ...
		'ListboxTop',0, ...
		'Max',2, ...
		'Min',1, ...
		'Enable', 'off',...
		'Position',[leftoffset+30 precissionOffset-50 100 20], ...
		'String',{'2 bit' '8 bit' '16 bit signed' '16 bit unsigned' '32 bit' '64 bit'}, ...
		'Style','popupmenu', ...
		'Value',1);
	
	%
	% Description
	%

	uicontrol('style','frame',...
		'position',[leftoffset+20 limitOffset-75 290 55],...
		'HorizontalAlignment','left');

	uicontrol('style','checkbox',...
      		'position',[30 limitOffset+17-65 150 20],...
      		'HorizontalAlignment','left',...
		'tag','descrCheck',...
      		'string','Description',...
      		'backgroundcolor',[.8 .8 .8]);

	uicontrol('style','edit',...
      		'enable','off',...
		'horizontalAlignment','left',...
		'tag','descrFig2',...
		'callback','',...
		'position',[30 limitOffset-70 270 20],...
		'string','');
    
  	%
	% Endian
	%

	uicontrol('style','frame',...
		'position',[300+20 dimOffset-13 200 60],...
		'HorizontalAlignment','left');

	uicontrol('style','checkbox',...
      		'position',[330 dimOffset+19 150 20],...
      		'HorizontalAlignment','left',...
		'tag','endianCheck',...
      		'string','Endian',...
      		'backgroundcolor',[.8 .8 .8]);

    uicontrol('Parent',f2, ...
		'BackgroundColor',[0.701960784313725 0.701960784313725 0.701960784313725], ...
		'ListboxTop',0, ...
		'Max',2, ...
		'Min',1, ...
		'Tag','UIendianFig2', ...
		'Enable', 'off',...
		'Position',[330 dimOffset+19-23 150 20], ...
		'String',{'ieee-be' 'ieee-le'}, ...
		'Style','popupmenu', ...
		'Value',1);
  
	end
	
  end
end


if nargin == 1
  switch arg1
   case 'openfile' 
    openfile
   case 'newfile'
    newfile
   case 'savefile'
    savefile
   case 'ApplyToFiles'
    ApplyToFiles
   case 'precis'
    precis
   case 'ReadFiles'
    ReadFiles
   case 'applyChanges'
    applyChanges
   case 'close'
    closeWindow
  end;
end;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                    openfile                            %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function openfile(h)
	[fname,pname]=uigetfile('*.hdr','Open file');
	
	if fname == 0
 	 	'Please choose a file...';
	else

	  
	  [path,name,ext]=fileparts(fname);
	  
	  
	  if strcmp('',pname)
	    filename = name;
	  else
	    filename = strcat(pname,name);	
	  end
	  [hdr]=ReadAnalyzeHdr(filename);
	  
	  
	  %
	  % Set parametres enabled
	  %
	  set(findobj('tag','u1'),'enable','on');
	  set(findobj('tag','u2'),'enable','on');
	  set(findobj('Tag','u3'),'enable','on');
	  set(findobj('Tag','u4'),'enable','on');
	  set(findobj('Tag','u5'),'enable','on');
	  set(findobj('Tag','u6'),'enable','on');
	  set(findobj('Tag','u7'),'enable','on');
	  set(findobj('Tag','u8'),'enable','on');
	  set(findobj('Tag','u9'),'enable','on');
	  set(findobj('Tag','u10'),'enable','on');
	  set(findobj('Tag','u11'),'enable','on');
	  set(findobj('Tag','u12'),'enable','on');
	  set(findobj('Tag','u13'),'enable','on');
	  set(findobj('Tag','u14'),'enable','on');
	  set(findobj('Tag','u15'),'enable','on');
	  set(findobj('Tag','u16'),'enable','on');
  	  set(findobj('Tag','UIendian'),'enable','on');
	  set(findobj('Tag','descr'),'enable','on');
	  
	  if length(hdr.dim) == 4
	    set(findobj('Tag','u14a'),'enable','on');
	    set(findobj('Tag','u14b'),'visible','on');
	  else
	    set(findobj('Tag','u14a'),'enable','off','visible','off');
	    set(findobj('Tag','u14b'),'visible','off');
	  end;
	  
	  %
	  % Fill up
	  %
	  
	  set(findobj('Tag','t1'),'string', strcat(filename,'.hdr'));
	  
	  % limit
	  if length(hdr.lim) == 2
		set(findobj('Tag','u2'),'string', hdr.lim(2));
		set(findobj('Tag','u3'),'string', hdr.lim(1));
	else 
		set(findobj('Tag','u2'),'string', 0);
		set(findobj('Tag','u3'),'string', 0);
	end

	% offset
	set(findobj('Tag','u4'),'string', hdr.offset);

	% scale
	set(findobj('Tag','u5'),'string', hdr.scale);
	
	% origin
	if length(hdr.origin) == 3
		set(findobj('Tag','u6'),'string', hdr.origin(1));
		set(findobj('Tag','u7'),'string', hdr.origin(2));
		set(findobj('Tag','u8'),'string', hdr.origin(3));
	else	
		set(findobj('Tag','u6'),'string', 0);
		set(findobj('Tag','u7'),'string', 0);
		set(findobj('Tag','u8'),'string', 0);
	end

	% size
	if length(hdr.siz) == 3
		set(findobj('Tag','u9'),'string', hdr.siz(1));
		set(findobj('Tag','u10'),'string', hdr.siz(2));
		set(findobj('Tag','u11'),'string', hdr.siz(3));
	else	
		set(findobj('Tag','u9'),'string', 0);
		set(findobj('Tag','u10'),'string', 0);
		set(findobj('Tag','u11'),'string', 0);
	end
	
	% din
	if length(hdr.dim) >= 3
		set(findobj('Tag','u12'),'string', hdr.dim(1));
		set(findobj('Tag','u13'),'string', hdr.dim(2));
		set(findobj('Tag','u14'),'string', hdr.dim(3));
	else	
		set(findobj('Tag','u12'),'string', 0);
		set(findobj('Tag','u13'),'string', 0);
		set(findobj('Tag','u14'),'string', 0);
	end

	if length(hdr.dim) == 4
	  set(findobj('Tag','u14a'),'string', hdr.dim(4),'visible','on');
	else
	  set(findobj('Tag','u14a'),'string', '');
	end;

	% pre
	if hdr.pre == 1
		set(findobj('Tag','u1'),'value',1);
	elseif hdr.pre == 8
		set(findobj('Tag','u1'),'value',2);
	elseif hdr.pre == 16	
		if hdr.lim(1) == 0
			set(findobj('Tag','u1'),'value',4);
		else 
			set(findobj('Tag','u1'),'value',3);
		end
	elseif hdr.pre == 32
		set(findobj('Tag','u1'),'value',5);
	elseif hdr.pre == 64
		set(findobj('Tag','u1'),'value',6);
	end
    
	% endian
	if strcmp(hdr.endian,'ieee-be')
		set(findobj('Tag','UIendian'),'value',1);
	elseif strcmp(hdr.endian,'ieee-le')
		set(findobj('Tag','UIendian'),'value',2);
	end
        
	% descr
	set(findobj('Tag','descr'),'string', hdr.descr);
	end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                    newfile                             %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function newfile
	set(findobj('tag','u1'),'enable','on');
	set(findobj('tag','u2'),'enable','on');
	set(findobj('Tag','u3'),'enable','on');
	set(findobj('Tag','u4'),'enable','on');
	set(findobj('Tag','u5'),'enable','on');
	set(findobj('Tag','u6'),'enable','on');
	set(findobj('Tag','u7'),'enable','on');
	set(findobj('Tag','u8'),'enable','on');
	set(findobj('Tag','u9'),'enable','on');
	set(findobj('Tag','u10'),'enable','on');
	set(findobj('Tag','u11'),'enable','on');
	set(findobj('Tag','u12'),'enable','on');
	set(findobj('Tag','u13'),'enable','on');
	set(findobj('Tag','u14'),'enable','on');
	set(findobj('Tag','u14a'),'enable','on','visible','on');
	set(findobj('Tag','u14b'),'enable','on','visible','on');
	set(findobj('Tag','u15'),'enable','on');
	set(findobj('Tag','u16'),'enable','on');
	set(findobj('Tag','descr'),'enable','on');
    set(findobj('Tag','UIendian'),'enable','on');
    

	set(findobj('Tag','t1'),'string','');

	set(findobj('tag','u2'),'string','0')
	set(findobj('tag','u3'),'string','1')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                    savefile                            %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function savefile
	[fname, pname] = uiputfile(strcat('','.hdr'), 'Save file');

	% keyboard

	if (fname == 0)
 		errordlg('Please choose a file...')
		return
	end

	boo = 0;
	try 
	  if strcmp(get(findobj('tag','u14a'),'visible'),'on') & ~isempty(get(findobj('tag','u14a'),'string'))
		dim = [my_str2num(get(findobj('tag','u12'), 'string'),'dim: x'); my_str2num(get(findobj('tag','u13'),'string'),'dim: y'); my_str2num(get(findobj('tag','u14'),'string'),'dim: z'); my_str2num(get(findobj('tag','u14a'),'string'),'dim: t');];
	  else
		dim = [my_str2num(get(findobj('tag','u12'),'string'),'dim: x'); my_str2num(get(findobj('tag','u13'),'string'),'dim: y'); my_str2num(get(findobj('tag','u14'),'string'),'dim: z')];
	  end;
	catch
		boo = 1;
		errordlg('Either dim: x, y, z or t is not a number')
	end
	
	try
		siz = [my_str2num(get(findobj('tag','u9'),'string'),'size: x'); my_str2num(get(findobj('tag','u10'),'string'),'size: y'); my_str2num(get(findobj('tag','u11'),'string'),'size: z')];
	
	catch
		boo = 1;
		errordlg('Either size: x, y or z is not a number')
	end

        % endian
		tmp = get(findobj('tag','UIendian'),'value');
		if tmp == 1
            endian='ieee-be';
		end
	
		if tmp == 2
            endian='ieee-le';
		end

		% pre
		tmp = get(findobj('tag','u1'),'value');
		if tmp == 1
			pre = 1;
		end
	
		if tmp == 2
			pre = 8;
		end
	
		if tmp == 3
			pre = 16;
		end

		if tmp == 4
			pre = 16;
		end

		if tmp == 5
			pre = 32;
                end

		if tmp == 6
			pre = 64;
		end
	
	try
		lim = [my_str2num(get(findobj('tag','u3'),'string'),'Limit: max'); my_str2num(get(findobj('tag','u2'),'string'),'Limit: min'); ];
	
	catch
		boo = 1;
		errordlg('Either min or max is not a number')
	end
	
	try
		scale = my_str2num(get(findobj('tag','u5'),'string'),'scale ');
	catch
		boo = 1;
		errordlg('Scale is not af number')
	end
	
	try
		offset = my_str2num(get(findobj('tag','u4'),'string'),'offset ');
	catch
		boo = 1;
		errordlg('Scale is not af number')
	end	

	try
		origin = [my_str2num(get(findobj('tag','u6'),'string'),'origin: x'); my_str2num(get(findobj('tag','u7'),'string'),'origin: y'); my_str2num(get(findobj('tag','u8'),'string'),'origin: z')];
	
	catch
		boo = 1;
		errordlg('Either origin: x, y or z is not a number')
	end
		
	descr = get(findobj('tag','descr'),'string');
	
	if boo==0  
	  [path,name,ext]=fileparts(fname);
	  
	  
	  if strcmp('',pname)
	    filename = name;
	  else
	    filename = strcat(pname,name);	
	  end

      hdr.dim=dim;
      hdr.siz=siz;
      hdr.pre=pre;
      hdr.lim=lim;
      hdr.scale=scale;
      hdr.offset=offset;
      hdr.origin=origin;
      hdr.descr=descr;
      hdr.endian=endian;
      hdr.name=name;
      hdr.path=pname;
      
	  WriteAnalyzeHdr(hdr);
	end;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                    ApplyToFiles                        %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ApplyToFiles
	[pre,dim,siz,lim,scale,offset,origin,descr,endian]=getAnalyzeData;

	f = findobj('tag','FixAnalyzeHdrFig2');

	set(findobj('tag','FixAnalyzeHdrFig2'),'visible','on');

	set(findobj(f,'tag','u101'),'enable','inactive');
	set(findobj('tag','u102'),'enable','inactive');
	set(findobj('Tag','u103'),'enable','inactive');
	set(findobj('Tag','u104'),'enable','inactive');
	set(findobj('Tag','u105'),'enable','inactive');
	set(findobj('Tag','u106'),'enable','inactive');
	set(findobj('Tag','u107'),'enable','inactive');
	set(findobj('Tag','u108'),'enable','inactive');
	set(findobj('Tag','u109'),'enable','inactive');
	set(findobj('Tag','u110'),'enable','inactive');
	set(findobj('Tag','u111'),'enable','inactive');
	set(findobj('Tag','u112'),'enable','inactive');
	set(findobj('Tag','u113'),'enable','inactive');
	set(findobj('Tag','u114'),'enable','inactive');
	set(findobj('Tag','u115'),'enable','inactive');
	set(findobj('Tag','u116'),'enable','inactive');
	set(findobj('Tag','descrFig2'),'enable','inactive');
    set(findobj('Tag','UIendianFig2'),'enable','inactive');

	%
	% Fill up
	%
	if length(lim) == 2
		set(findobj('Tag','u102'),'string', lim(2));
		set(findobj('Tag','u103'),'string', lim(1));
	else 
		set(findobj('Tag','u102'),'string', 0);
		set(findobj('Tag','u103'),'string', 0);
	end	

	% offset
	set(findobj('Tag','u104'),'string', offset);
	
	% scale
	set(findobj('Tag','u105'),'string', scale);

	% origin
	if length(origin) == 3
		set(findobj('Tag','u106'),'string', origin(1));
		set(findobj('Tag','u107'),'string', origin(2));
		set(findobj('Tag','u108'),'string', origin(3));
	else
		set(findobj('Tag','u106'),'string', 0);
		set(findobj('Tag','u107'),'string', 0);
		set(findobj('Tag','u108'),'string', 0);	
	end

	% size
	if length(siz) == 3
		set(findobj('Tag','u109'),'string', siz(1));
		set(findobj('Tag','u110'),'string', siz(2));
		set(findobj('Tag','u111'),'string', siz(3));
	else	
		set(findobj('Tag','u109'),'string', 0);
		set(findobj('Tag','u110'),'string', 0);
		set(findobj('Tag','u111'),'string', 0);
	end

	% dim
	if length(dim) == 3
		set(findobj('Tag','u112'),'string', dim(1));
		set(findobj('Tag','u113'),'string', dim(2));
		set(findobj('Tag','u114'),'string', dim(3));
	else	
		set(findobj('Tag','u112'),'string', 0);
		set(findobj('Tag','u113'),'string', 0);
		set(findobj('Tag','u114'),'string', 0);
	end


    % pre
	if strcmp(endian,'ieee-be')
		set(findobj('Tag','UIendianFig2'),'value',1);
	else
		set(findobj('Tag','UIendianFig2'),'value',2);
    end
    
	% pre
	if pre == 1
		set(findobj(f,'Tag','u101'),'value',1);
	elseif pre == 8
		set(findobj(f,'Tag','u101'),'value',2);
	elseif pre == 16	
		if lim(1) == 0
			set(findobj(f,'Tag','u101'),'value',4);
		else 
			set(findobj(f,'Tag','u101'),'value',3);
		end
	elseif pre == 32
		set(findobj(f,'Tag','u101'),'value',5);
	elseif pre == 64
		set(findobj(f,'Tag','u101'),'value',6);
	end

	set(findobj(f,'tag','descrFig2'),'string',descr)
		

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                    getAnalyzeData                      %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [pre,dim,siz,lim,scale,offset,origin,descr,endian] = getAnalyzeData

	try 	
		dim = [my_str2num(get(findobj('tag','u12'),'string'),'dim: x'); my_str2num(get(findobj('tag','u13'),'string'),'dim: y'); my_str2num(get(findobj('tag','u14'),'string'),'dim: z')];

	catch
		boo = 1;
		errordlg('Either dim: x, y or z is not a number')
	end
	
	try
		siz = [my_str2num(get(findobj('tag','u9'),'string'),'size: x'); my_str2num(get(findobj('tag','u10'),'string'),'size: y'); my_str2num(get(findobj('tag','u11'),'string'),'size: z')];
	
	catch
		boo = 1;
		errordlg('Either size: x, y or z is not a number')
	end
	
        % endian
		tmp = get(findobj('tag','UIendian'),'value');
		if tmp == 1
            endian='ieee-be';
		end
	
		if tmp == 2
            endian='ieee-le';
		end

		% pre
		tmp = get(findobj('tag','u1'),'value');
		if tmp == 1
			pre = 1;
		end
	
		if tmp == 2
			pre = 8;
		end
	
		if tmp == 3
			pre = 16;
		end

		if tmp == 4
			pre = 16;
		end

		if tmp == 5
			pre = 32;
		end
	
		if tmp == 6
			pre = 64;
		end
	
	try
		lim = [my_str2num(get(findobj('tag','u3'),'string'),'Limit: max'); my_str2num(get(findobj('tag','u2'),'string'),'Limit: min'); ];
	
	catch
		boo = 1;
		errordlg('Either min or max is not a number')
	end
	
	try
		scale = my_str2num(get(findobj('tag','u5'),'string'),'scale ');
	catch
		boo = 1;
		errordlg('Scale is not af number')
	end
	
	try
		offset = my_str2num(get(findobj('tag','u4'),'string'),'offset ');
	catch
		boo = 1;
		errordlg('Scale is not af number')
	end	

	try
		origin = [my_str2num(get(findobj('tag','u6'),'string'),'origin: x'); my_str2num(get(findobj('tag','u7'),'string'),'origin: y'); my_str2num(get(findobj('tag','u8'),'string'),'origin: z')];
	
	catch
		boo = 1;
		errordlg('Either origin: x, y or z is not a number')
	end

	descr = get(findobj('tag','descr'),'string');
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                    precis                              %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function precis
	tmp = get(findobj('tag','u1'),'value');

	if tmp == 1
		set(findobj('tag','u2'),'string', '0');
		set(findobj('tag','u3'),'string', '1');
	end
	if tmp == 2
		set(findobj('tag','u2'),'string', '0');
		set(findobj('tag','u3'),'string', '255');
	end
	
	if tmp == 3
		set(findobj('tag','u2'),'string', '-32768');
		set(findobj('tag','u3'),'string', '32767');
	end
	
	if tmp == 4
		set(findobj('tag','u2'),'string', '0');
		set(findobj('tag','u3'),'string', '65535');
	end
	
	if tmp == 5
		set(findobj('tag','u2'),'string', '0');
		set(findobj('tag','u3'),'string', '0');
	end

	if tmp == 6
		set(findobj('tag','u2'),'string', '0');
		set(findobj('tag','u3'),'string', '0');
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                    ReadFiles                           %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ReadFiles
	global files;

	[files,result]=ui_choosefiles('.','*.hdr');

	j=1;
	listFiles={};
	for i=1:length(files)
		listFiles(j)=cellstr(files{i});
      		j=j+1;
	end

	if result ~= -1
		set(findobj('tag','u62'), 'value', 1)
		set(findobj('tag','u62'), 'string', listFiles)
		set(findobj('tag','u63'), 'enable', 'on')	
	end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%                    ReadFiles                           %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function applyChanges

	global files;

	str = cell(1,5);
	cellCounter = 1;


	tmp = get(findobj('tag','u150'),'value');
	if (tmp==1)
		str{cellCounter} = 'diminsion';
		cellCounter = cellCounter+1;
	end;


	tmp = get(findobj('tag','u151'),'value');
	if (tmp==1)
		str{cellCounter} = 'size';
		cellCounter = cellCounter+1;
	end;

	tmp = get(findobj('tag','u152'),'value');
	if (tmp==1)
		str{cellCounter} = 'origin';
		cellCounter = cellCounter+1;
	end;
	
	tmp = get(findobj('tag','u153'),'value');
	if (tmp==1)
		str{cellCounter} = 'scale';
		cellCounter = cellCounter+1;
	end;

	tmp = get(findobj('tag','u154'),'value');
	if (tmp==1)
		str{cellCounter} = 'offset';
		cellCounter = cellCounter+1;
	end;

	tmp = get(findobj('tag','u155'),'value');
	if (tmp==1)
		str{cellCounter} = 'precission';
		cellCounter = cellCounter+1;
	end;

	tmp = get(findobj('tag','descrCheck'),'value');
	if (tmp==1)
		str{cellCounter} = 'description';
		cellCounter = cellCounter+1;
	end;
    
    tmp = get(findobj('tag','endianCheck'),'value');
	if (tmp==1)
		str{cellCounter} = 'endian';
		cellCounter = cellCounter+1;
	end;



	result = FixAnalyzeHdr_OC('Fix:', 'In', str, files);

	if result

		j=1;
		for i=1:length(files)		
			[path,name,ext]=fileparts(files{i});
        		%[pre,dim,siz,lim,scale,offset,origin,descr]=ReadAnalyzeHdr(strcat(path,'/', name));
            hdr=ReadAnalyzeHdr(strcat(path,'/', name));
			    
			tmp = get(findobj('tag','u150'),'value');
			if (tmp==1)
		 		hdr.dim = [str2num(get(findobj('tag','u112'),'string')); str2num(get(findobj('tag','u113'),'string')); str2num(get(findobj('tag','u114'),'string'))];
	
			end;

			tmp = get(findobj('tag','u151'),'value');
			if (tmp==1)
				hdr.siz = [str2num(get(findobj('tag', 'u109'),'string'));str2num(get(findobj('tag','u110'),'string')); str2num(get(findobj('tag','u111'),'string'))];				
				cellCounter = cellCounter+1;
			end;

			tmp = get(findobj('tag','u152'),'value');
			if (tmp==1)
				hdr.origin = [str2num(get(findobj('tag','u106'),'string'));str2num(get(findobj('tag','u107'),'string')); str2num(get(findobj('tag','u108'),'string'))];
			end;
	
			tmp = get(findobj('tag','u153'),'value');
			if (tmp==1)
				hdr.scale = str2num(get(findobj('tag','u105'),'string'));

			end;
	
			tmp = get(findobj('tag','u154'),'value');
			if (tmp==1)
				hdr.offset = str2num(get(findobj('tag','u104'),'string'));
			end;

			tmp = get(findobj('tag','u155'),'value');
			if (tmp==1)
				% pre
				tmp = get(findobj('tag','u101'),'value');
		
				if tmp == 1
					hdr.pre = 1;
				end
		
				if tmp == 2
					hdr.pre = 8;
				end		

				if tmp == 3
					hdr.pre = 16;
				end	

				if tmp == 4
					hdr.pre = 16;
				end
	
				if tmp == 5
					hdr.pre = 32;
				end

				if tmp == 6
					hdr.pre = 64;
				end

				hdr.lim = [str2num(get(findobj('tag','u103'),'string')); str2num(get(findobj('tag','u102'),'string')) ];
			end

			tmp = get(findobj('tag','descrCheck'),'value');		
			if (tmp==1)
			  hdr.descr  = get(findobj('tag','descrFig2'),'string');					
			end;
            
   			tmp = get(findobj('tag','endianCheck'),'value');		
			if (tmp==1)
                if  get(findobj('tag','UIendianFig2'),'value')==1
                    hdr.endian = 'ieee-be';
                else
                    hdr.endian = 'ieee-le';
                end                
			end;

			%WriteAnalyzeHdr(strcat(path,'/', name),dim,siz,pre,lim,scale,offset,origin,descr);
            hdr.name=name;
            hdr.path=path;
			WriteAnalyzeHdr(hdr);
			

        		j=j+1;
		end;
	end;


function [num] = my_str2num(arg,str)
if (isempty(str2num(arg)))    
	error(str)
	return;
else		
	num = str2num(arg);
end

function closeWindow
  f1 = findobj('tag','FixAnalyzeHdrFig');
  f2 = findobj('tag','FixAnalyzeHdrFig2');
  set(f1,'CloseRequestFcn','closereq');
  set(f2,'CloseRequestFcn','closereq');
  delete(f1);
  delete(f2);
  
