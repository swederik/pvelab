function [files,result,filter_out,hout] = ui_choosefiles_real(path, filter, header, hin)

global SelectedFiles;
global FinalResult;
global FinalFilter;
global CloseChooseFiles;

if nargin==1,
 % disp(path);
  switch(path)
    case 'CBDir',
      ChangeDir(gcbf);
    
    case 'CBEditFilter',
      RefreshListboxes(gcbf);
      
    case 'Ok'
      hLBFiles=findobj(gcbf,'Tag','ListboxFiles');
      value=get(hLBFiles, 'Value');
      string=get(hLBFiles, 'String');
      SelectedFiles={};
      if length(string)>0,
        for i=1:length(value),
          SelectedFiles(i)=cellstr(strcat(cd,'/',char(string(value(i))) ));
        end
      end
      FinalResult=1;
      hEditFilter=findobj(gcbf,'Tag','EditFilter');  
      FinalFilter = get(hEditFilter, 'String');
      if CloseChooseFiles
        close(gcbf);
      else
        uiresume(gcbf);
      end
    
    case 'Cancel'
      SelectedFiles={};
      hEditFilter=findobj(gcbf,'Tag','EditFilter');  
      FinalFilter = get(hEditFilter, 'String');
      FinalResult=-1;
      if CloseChooseFiles
        close(gcbf);
      else
        uiresume(gcbf);
      end
        
  end
else
  if nargin==4
    if strcmp(get(hin,'Tag'),'ChooseFigure')
      figure(hin);
    else
      ui_choosefileswindow;
      hin=gcf;
    end
  else
    ui_choosefileswindow;
    hin=gcf;
  end
  if nargout==4
    CloseChooseFiles=0;
  else
    CloseChooseFiles=1;
  end
  if nargin>1
    cd(path);
    RefreshEditFilter(filter);
  else
    RefreshEditFilter('*.*');
  end
  if nargin>2
    SetTitle(header);
  else
    SetTitle('Choose files');
  end
  RefreshPathLabel(gcf);
  RefreshListboxes(gcf);

  uiwait;
  if isempty(FinalResult)
    FinalResult=-1;
  end
  files=SelectedFiles;
  filter_out=FinalFilter;
  result=FinalResult;  
  hout=hin;
  clear global SelectedFiles FinalResult FinalFilter;
end  


function RefreshListboxes(handle)
  % Fill listboxes

  % Read dir info for directories
  d=dir('.');
  dstr = {d.name};
  ddir = {d.isdir};
  s=char(dstr);
  [s i]=sortrows(s);
  dstr=dstr(i);
  ddir=ddir(i);


  % Get listbox handles
  hLBFiles=findobj(handle,'Tag','ListboxFiles');
  hLBDir=findobj(handle,'Tag','ListboxDir');
  hEditFilter=findobj(handle,'Tag','EditFilter');  

  filt = get(hEditFilter, 'String');
    
  % Read dir info for files
  d=dir(filt);
  nstr = {d.name};
  s=char(nstr);
  [s i]=sortrows(s);
  nstr=nstr(i);
  
  
  % Dir names
  dj=1;
  dstrings={};
  for i=1:length(dstr),
    sd=ddir(i);
    snd=dstr(i);
    if (sd{1}==1),
      dstrings(dj)=cellstr(snd{1});
      dj=dj+1;
    end
  end

  % File names
  fj=1;
  fstrings={};
  for i=1:length(nstr),
    sn=nstr(i);
    fstrings(fj)=cellstr(sn{1});
    fj=fj+1;
  end

  % Insert dir and file names
  set(hLBFiles,'Value',1);
  set(hLBDir,'Value',1);
  set(hLBFiles,'String',fstrings);
  set(hLBDir,'String',dstrings);
  

function RefreshPathLabel(handle)
  % Set path
  hLPath=findobj(handle,'Tag','Path');
  path=cd;
  set(hLPath,'String',path)


function RefreshEditFilter(filter)
  % Set Filter
  hLPath=findobj('Tag','EditFilter');
  set(hLPath,'String',filter)


function ChangeDir(handle)
  global dValueOld;

  hLBFiles=findobj(handle,'Tag','ListboxFiles');
  hLBDir=findobj(handle,'Tag','ListboxDir');
 
  dValue=get(hLBDir,'Value');

  if strcmp(get(handle,'SelectionType'),'open')
%    d=dir;
%    dstr = {d.name};
%    ddir = {d.isdir};
  
    dString=get(hLBDir,'String');
    cd(char(dString(dValue)));
  
    RefreshPathLabel(handle);
    RefreshListboxes(handle);
  else
    dValueOld=dValue;
  end

function SetTitle(title)
  % Set figure title
  hFigure=findobj('Tag','ChooseFigure');
  set(hFigure,'Name',title)
