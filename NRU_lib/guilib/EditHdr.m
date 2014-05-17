function varargout=EditHdr(varargin);
%
% EditHdr
% 
% Function to edit the contents of an Analyze HDR. 
%
% EditHdr()
%
% If no input argument is given, a hdr can be loaded from the 
% interface. 
%
% EditHdr('Input',hdr)
% 
% The program can also be used as a module to edit 
% an existing hdr, using the above call. On program
% exit, the edited hdr is returned to the calling program.
%
% EditHdr('Input',hdr,'Lock',buttonlist)
%
% The above "expanded" call can be used to disable editing of certain 
% hdr parameters within "module mode". Possible values of buttonlist
% are
% 
% 'Values'  - disables editing of scale, offset, precision, limits and time dimension
% 
% 'Name'    - disables editing of file / path parameters
%
% 'Access'  - disables access to open, save and apply apply buttons and the description 
%             parameter
%   
% 'Default' - 'Values' + 'Name' + 'Access'
%
% 'DefaultName' - 'Values' + 'Access' - file / path parameters enabled.
%


  if nargin==0
    varagout{1}=EditHdr('Input',[]);
  else
    task=varargin{1};
    switch task
     case 'Input'
      % Set up editable hdr pane
      fig=SetupWindow(varargin{2});
      if nargin>2
	if strcmp(varargin{3},'Lock')
	  Lock(fig,varargin{4});
	end
      end
      userdat=get(fig,'userdata');
      userdat.OrigHdr=userdat.hdr;
      set(fig,'userdata',userdat);
      uiwait(fig);
      userdat=get(fig,'userdata');
      delete(fig)
      varargout{1}=userdat.hdr;
     case 'Update'
      Update;
     case 'SetFileName'
      userdat=get(gcbf,'userdata');
      userdat.hdr.name=get(gcbo,'string');
      set(gcbf,'userdata',userdat);
     case 'SetPathName'    
      userdat=get(gcbf,'userdata');
      userdat.hdr.path=get(gcbo,'string');
      set(gcbf,'userdata',userdat);
     case 'ApplyToFiles'
      userdat=get(gcbf,'userdata');
      hdr=userdat.hdr;
      OrigHdr=userdat.OrigHdr;
      Changeable={'dim','siz','origin','scale','offset','pre','path'};
      [Change,ok]=listdlg('PromptString','Select fields to apply','ListString',Changeable);
      if ok==1
	ChangeString=[];
	for j=1:length(Change)
	  ChangeString=[ChangeString ' ' Changeable{Change(j)}];
	end
	disp(['Applying Fields: ' ChangeString]);
	CD=pwd;
	[files,result]=ui_choosefiles(CD,'*.hdr','Select files for application');
	cd(CD);
	if result==1
	  for j=1:length(files)
	    hdrj=ReadAnalyzeHdr(files{j});
	    disp(['Changing the fields: ' ChangeString ' in ' hdrj.name]);
	    for k=1:length(Change)
	      eval(['hdrj.' Changeable{Change(k)} '=[];']);
	      eval(['hdrj.' Changeable{Change(k)} '=hdr.' Changeable{Change(k)} ';']);
	    end
	    WriteAnalyzeHdr(hdrj);
	  end
	else
	  disp('Apply cancelled');
	end
      else
	disp('Apply cancelled');
      end
     case 'Save'
      userdat=get(gcbf,'userdata');
      if isstruct(userdat.hdr)
	hdr=userdat.hdr;
	[Path File Ext]=fileparts(hdr.name);
	if isempty(Path)
	  if not(isempty(hdr.path))
	    Filename=[hdr.path File '.hdr'];
	  else
	    Filename=[File '.hdr'];
	  end
	else
	  Filename=[Path '/' File '.hdr'];
	end
	Save=0;
	if exist(Filename)==2
	  answer=questdlg({'The file',Filename,'exists! - Overwrite?'});
	  if strcmp('Yes',answer)
	    Save=1;
	  else
	    disp('Save cancelled');
	  end
	else
	  Save=1;
	end
	if Save==1
	  WriteAnalyzeHdr(hdr);
	  disp(['Wrote ' hdr.path '/' hdr.name]);
	end
      else
	error('Data are missing. All fields must be filled in');
      end
     case 'Open'
      [File Path]=uigetfile('*.hdr','Select Analyze HDR');
      if not(File==0)
	hdr=ReadAnalyzeHdr([Path File]);
	userdat=get(gcbf,'userdata');
	userdat.hdr=hdr;
	FillHeader(gcbf,hdr);
      else
	disp('Load Cancelled');
      end
     case 'Cancel'
      userdat=get(gcbf,'userdata');
      userdat.hdr=[];
      set(gcbf,'userdata',userdat);
      close(gcbf);
     case 'Ok'
      close(gcbf);
     otherwise
      % Check if the given input is a filename
      [Path File]=fileparts(task);
      if isempty(Path)
	Path=pwd;
      end
      File=[Path '/' File '.hdr'];
      if exist(File)==2
	hdr=ReadAnalyzeHdr(File);
	varargout{1}=EditHdr('Input',hdr);
      else
	error(['The input parameter ' task ' is not understood.']);
      end
    end
  end

function Lock(fig,taglist)
% Lock non-spatial uicontrols
  if iscell(taglist)
    for j=1:length(taglist)
      set(findobj(fig,'tag',taglist{j}),'enable','off');
    end
  elseif ischar(taglist) & strcmp(taglist,'Values')
    taglist={'Scale','Offset','Pre','Lim_1','Lim_2','Dim_t'};
    Lock(fig,taglist);
  elseif ischar(taglist) & strcmp(taglist,'Name')  
    taglist={'Name','Path'};
    Lock(fig,taglist);
  elseif ischar(taglist) & strcmp(taglist,'Access')  
    taglist={'Open','New','Save','Apply','Desc'};
    Lock(fig,taglist);
  elseif ischar(taglist) & strcmp(taglist,'Default')  
    Lock(fig,'Name');
    Lock(fig,'Values');
    Lock(fig,'Access');
  elseif ischar(taglist) & strcmp(taglist,'DefaultName')  
    Lock(fig,'Values');
    Lock(fig,'Access');
  end
  
  
function Update
% Does online updating of Analyze HDR
  userdat=get(gcbf,'userdata');
  hdr=userdat.hdr;
  % Who is calling us?
  task=get(gcbo,'tag');
  switch task
   case 'Dim_x'
    val=str2num(get(gcbo,'string'));
    hdr.dim(1)=CheckVal(val,hdr.dim(1));
   case 'Dim_y'
    val=str2num(get(gcbo,'string'));
    hdr.dim(2)=CheckVal(val,hdr.dim(2));
   case 'Dim_z'
    val=str2num(get(gcbo,'string'));
    hdr.dim(3)=CheckVal(val,hdr.dim(3));
   case 'Dim_t'
    val=str2num(get(gcbo,'string'));
    dim=hdr.dim;
    if length(dim==3)
      dim(4)=0;
    end
    hdr.dim(4)=CheckVal(val,dim(4));
   case 'Siz_x'
    val=str2num(get(gcbo,'string'));
    hdr.siz(1)=CheckVal(val,hdr.siz(1));
   case 'Siz_y'
    val=str2num(get(gcbo,'string'));
    hdr.siz(2)=CheckVal(val,hdr.siz(2));
   case 'Siz_z'
    val=str2num(get(gcbo,'string'));
    hdr.siz(3)=CheckVal(val,hdr.siz(3));
   case 'Orig_x'
    val=str2num(get(gcbo,'string'));
    hdr.origin(1)=CheckVal(val,hdr.origin(1));
   case 'Orig_y'
    val=str2num(get(gcbo,'string'));
    hdr.origin(2)=CheckVal(val,hdr.origin(2));
   case 'Orig_z'
    val=str2num(get(gcbo,'string'));
    hdr.origin(3)=CheckVal(val,hdr.origin(3));
   case 'Pre'
    val=get(gcbo,'value')
    switch val
     case 1
      hdr.pre=2;
      hdr.lim(1)=(2^hdr.pre)-1;
      hdr.lim(2)=0;
     case 2
      hdr.pre=8;
      hdr.lim(1)=(2^hdr.pre)-1;
      hdr.lim(2)=0;
     case 3
      hdr.pre=16;
      hdr.lim(1)=(2^hdr.pre/2)-1;
      hdr.lim(2)=-(2^hdr.pre);
     case 4
      hdr.pre=16;
      hdr.lim(1)=(2^hdr.pre)-1;
      hdr.lim(2)=0;
     case 5
      hdr.pre=32;
      hdr.lim(1)=(2^hdr.pre)-1;
      hdr.lim(2)=0;
    end
   case 'Desc'
    hdr.descr=get(gcbo,'string');
   case 'Name'
    hdr.name=get(gcbo,'string');
   case 'Path'
    hdr.path=get(gcbo,'string');
   otherwise
    error(['The task ' task ' is not understood']);
  end
  FillHeader(gcbf,hdr);
  
function val=CheckVal(val,backup)
  if isempty(val)
    val=backup
  end
    
  
  
function fig=SetupWindow(hdr)
% Set up GUI
  fig=figure('numbertitle','off','menubar','none','name',['Edit - ' hdr.name],...
	     'units','normalized','position',[0.6 0.25 1/3 1/2],'closerequestfcn','uiresume');

  
  BH=0.08;
  bh=BH/2;
  BW=0.2;
  bw=BW/2;
  delt=0.5*BW/5;
  BW1=0.95*4.5*BW/5;
  
  delt1=BW/4+0.025*4.5*BW;
  
  %
  %
  %
  uicontrol('units','normalized','style','frame','position',[BW/4 1-3.5*BH 4.5*BW 3*BH],'HorizontalAlignment','left','string','filename','backgroundcolor',[.7 .7 .7]);
  
  %
  % Open file
  %
  uicontrol('units','normalized','style','pushbutton',...
	    'callback','EditHdr(''Open'')',...
	    'position',[delt1 1-1.5*BH-delt BW1 BH],...
	    'string','Open','tag','Open');
  
  %
  % New file
  %
  %uicontrol('units','normalized','style','pushbutton',...
  %	    'callback','EditHdr(''New'')',...
  %	    'position',[BW/4+2*delt+BW 1-1.5*BH-delt BW BH],...
  %           'string','New','tag','New');
  
  
  %
  % Save file
  %
  uicontrol('units','normalized','style','pushbutton',...
	    'callback','EditHdr(''Save'')',...
	    'position',[delt1+BW1 1-1.5*BH-delt BW1 BH],...
	    'string','Save','tag','Save');
  
  %
  % Apply to files
  %
  uicontrol('units','normalized','style','pushbutton',...
	    'tag','u16',...
	    'callback','EditHdr(''ApplyToFiles'')',...
	    'position',[delt1+2*BW1 1-1.5*BH-delt BW1 BH],...
	    'string','Apply to files','tag','Apply');
  
  %
  % 'Ok' button
  %
  uicontrol('units','normalized','style','pushbutton',...
	    'callback','EditHdr(''Ok'')',...
	    'position',[delt1+3*BW1 1-1.5*BH-delt BW1 BH],...
	    'string','Ok','tag','Ok');
  

  
  %
  % Cancel
  %
  uicontrol('units','normalized','style','pushbutton',...
	    'callback','EditHdr(''Cancel'')',...
	    'position',[delt1+4*BW1 1-1.5*BH-delt BW1 BH],...
	    'string','Cancel','tag','Cancel');
  
  
  
  
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-1.5*BH-bh-2*delt BW bh],...
	    'HorizontalAlignment','left',...
	    'string','Filename:',...
	    'backgroundcolor',[.7 .7 .7]);
  
  uicontrol('units','normalized','style','edit',...
	    'position',[BW/4+2*delt+BW 1-1.5*BH-bh-2*delt 3*BW+2*delt bh],...
	    'HorizontalAlignment','left',...
	    'tag','Name',...
	    'string','filename',...
	    'backgroundcolor',[.8 .8 .8],'callback','EditHdr(''SetFileName'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-1.5*BH-2*bh-3*delt BW bh],...
	    'HorizontalAlignment','left',...
	    'string','Path:',...
	    'backgroundcolor',[.7 .7 .7]);
  
  uicontrol('units','normalized','style','edit',...
	    'position',[BW/4+2*delt+BW 1-1.5*BH-2*bh-3*delt 3*BW+2*delt bh],...
	    'HorizontalAlignment','left',...
	    'tag','Path',...
	    'string','path',...
	    'backgroundcolor',[.8 .8 .8],'callback','EditHdr(''SetPathName'')');
  
  %
  % Dimension
  %
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-4*BH-delt BW bh],...
	    'HorizontalAlignment','left',...
	    'string','Dimension',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Dim_x',...
	    'position',[BW/4+delt+bw 1-4.5*BH-delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-4.5*BH-delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','x:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Dim_y',...
	    'position',[BW/4+2*delt+3*bw 1-4.5*BH-delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+2*delt+2*bw 1-4.5*BH-delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','y:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Dim_z',...
	    'position',[BW/4+3*delt+5*bw 1-4.5*BH-delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+3*delt+4*bw 1-4.5*BH-delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','z:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Dim_t',...
	    'position',[BW/4+4*delt+7*bw 1-4.5*BH-delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+4*delt+6*bw 1-4.5*BH-delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','t:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-5*BH-2*delt BW bh],...
	    'HorizontalAlignment','left',...
	    'string','Size',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Siz_x',...
	    'position',[BW/4+delt+bw 1-5.5*BH-2*delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-5.5*BH-2*delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','x:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Siz_y',...
	    'position',[BW/4+2*delt+3*bw 1-5.5*BH-2*delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+2*delt+2*bw 1-5.5*BH-2*delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','y:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Siz_z',...
	    'position',[BW/4+3*delt+5*bw 1-5.5*BH-2*delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+3*delt+4*bw 1-5.5*BH-2*delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','z:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-6*BH-3*delt BW bh],...
	    'HorizontalAlignment','left',...
	    'string','Origin',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Orig_x',...
	    'position',[BW/4+delt+bw 1-6.5*BH-3*delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-6.5*BH-3*delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','x:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Orig_y',...
	    'position',[BW/4+2*delt+3*bw 1-6.5*BH-3*delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+2*delt+2*bw 1-6.5*BH-3*delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','y:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Orig_z',...
	    'position',[BW/4+3*delt+5*bw 1-6.5*BH-3*delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+3*delt+4*bw 1-6.5*BH-3*delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','z:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-7*BH-4*delt bw bh],...
	    'HorizontalAlignment','left',...
	    'string','Scale:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Scale',...
	    'position',[BW/4+delt+bw 1-7.5*BH-4*delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+2*delt+2*bw 1-7*BH-4*delt bw bh],...
	    'HorizontalAlignment','left',...
	    'string','Offset:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Offset',...
	    'position',[BW/4+2*delt+3*bw 1-7.5*BH-4*delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-8*BH-5*delt BW bh],...
	    'HorizontalAlignment','left',...
	    'string','Precision:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','Parent',fig, ...
	    'BackgroundColor',[.8 .8 .8], ...
	    'ListboxTop',0, ...
	    'Max',2, ...
	    'Min',1, ...
	    'Tag','Pre', ...
	    'Position',[BW/4+delt 1-8.5*BH-5*delt 2*bw bh], ...
	    'String',{'2 bit int' '8 bit int' '16 bit int' '16 bit uint' '32 bit'}, ...
	    'Style','popupmenu', ...
	    'Value',3,'Callback','EditHdr(''Update'')');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-9*BH-6*delt BW bh],...
	      'HorizontalAlignment','left',...
	    'string','Limits:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+delt 1-9.5*BH-6*delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','min:',...
	    'backgroundcolor',[.8 .8 .8]);
  
  uicontrol('units','normalized','style','edit',...
	    'tag','Lim_1',...
	    'position',[BW/4+delt+bw 1-9.5*BH-6*delt bw bh],...
	    'string','','Callback','EditHdr(''Update'')','enable','inactive');
  
  uicontrol('units','normalized','style','text',...
	    'position',[BW/4+2*delt+2*bw 1-9.5*BH-6*delt bw bh],...
	    'HorizontalAlignment','center',...
	    'string','max:',...
	    'backgroundcolor',[.8 .8 .8]);
  
    uicontrol('units','normalized','style','edit',...
	      'tag','Lim_2',...
	      'position',[BW/4+2*delt+3*bw 1-9.5*BH-6*delt bw bh],...
	      'string','','Callback','EditHdr(''Update'')','enable','inactive');
    
    uicontrol('units','normalized','style','text',...
	      'position',[BW/4+delt 1-10*BH-7*delt BW bh],...
	      'HorizontalAlignment','left',...
	      'string','Description:',...
	      'backgroundcolor',[.8 .8 .8]);
    
    uicontrol('units','normalized','style','edit',...
	      'position',[BW/4+delt 1-10.5*BH-7*delt 1-BW/2-2*delt bh],...
	      'HorizontalAlignment','left',...
	      'string','',...
	      'backgroundcolor',[.7 .7 .7],...
	      'tag','Desc','Callback','EditHdr(''Update'')');
    
    
    FillHeader(fig,hdr);
    
function FillHeader(fig,hdr);
%
  userdat=get(fig,'userdata');
  if not(isempty(hdr))
    set(findobj(fig,'tag','Name'),'string',hdr.name);
    set(findobj(fig,'tag','Path'),'string',hdr.path);
    set(findobj(fig,'tag','Dim_x'),'string',num2str(hdr.dim(1)));
    set(findobj(fig,'tag','Dim_y'),'string',num2str(hdr.dim(2)));
    set(findobj(fig,'tag','Dim_z'),'string',num2str(hdr.dim(3)));
    if length(hdr.dim)>3 & not(hdr.dim(4)==0)
      set(findobj(fig,'tag','Dim_t'),'string',num2str(hdr.dim(4)));
    else
      set(findobj(fig,'tag','Dim_t'),'string','');
    end
    set(findobj(fig,'tag','Siz_x'),'string',num2str(hdr.siz(1)));
    set(findobj(fig,'tag','Siz_y'),'string',num2str(hdr.siz(2)));
    set(findobj(fig,'tag','Siz_z'),'string',num2str(hdr.siz(3))); 
    if all(hdr.origin==0)
      hdr.origin(:)=1;
    end
    set(findobj(fig,'tag','Orig_x'),'string',num2str(hdr.origin(1)));
    set(findobj(fig,'tag','Orig_y'),'string',num2str(hdr.origin(2)));
    set(findobj(fig,'tag','Orig_z'),'string',num2str(hdr.origin(3)));
    set(findobj(fig,'tag','Scale'),'string',num2str(hdr.scale));
    set(findobj(fig,'tag','Offset'),'string',num2str(hdr.offset));
    set(findobj(fig,'tag','Lim_1'),'string',num2str(hdr.lim(2)))
    set(findobj(fig,'tag','Lim_2'),'string',num2str(hdr.lim(1)))
    set(findobj(fig,'tag','Desc'),'string',hdr.descr)
    if hdr.pre==2
      set(findobj(fig,'tag','Pre'),'value',1)
    elseif hdr.pre==8
      set(findobj(fig,'tag','Pre'),'value',2)
    elseif hdr.pre==16
      if hdr.lim(2)<0
	set(findobj(fig,'tag','Pre'),'value',4)
      else
	set(findobj(fig,'tag','Pre'),'value',3)
      end
    elseif hdr.pre==32
      set(findobj(fig,'tag','Pre'),'value',5)
    elseif hdr.pre==64
      set(findobj(fig,'tag','Pre'),'value',6)
    else
      error(['The given precision ' num2str(hdr.pre) ' is not defined!']);
    end
  end
  userdat.hdr=hdr;
  set(fig,'userdata',userdat);
    
    