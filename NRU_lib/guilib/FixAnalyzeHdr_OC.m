function result=FixAnalyzeHdr_OkCancel(str1, str2, list1, list2)
%
% Open a window with a Ok button and a Cancel button, Too listboxes and
% and too textfields. It stop further execution of matlab, until either the OK
% button og the Cancel button is pressed. 
%
%	function result=OkCancelBox_With2Str2List(str1, str2, list1, list2)
%
%	str1	- Text over the first listbox
%	str2	- Text over the second listbox
%	list1	- Content for the first listbox
% 	list2	_ content for the second listbox
%	result	- is set to 1 if OK button is pressed	
%		  is set to 0 if cancel button is pressed
%
% cmm, 030200
%
global FinalResult;

scsize=get(0,'screensize');
h.f(1)=figure('position',[.2*scsize(3) .3*scsize(4) 400 300],...
      'tag','MovieFig',...
      'visible','on',...
      'Resize','Off');

%
% Ok
%
h.u(1)=uicontrol('style','pushbutton',...
      'callback','FixAnalyzeHdr_OCReturn(0)',...
      'position',[110 20 60 30],...
      'string','Cancel');


%
% Cancel
%
h.u(2)=uicontrol('style','pushbutton',...
      'callback','FixAnalyzeHdr_OCReturn(1)',...
      'position',[30 20 60 30],...
      'string','Ok');

%
% Text1
%
h.t(1)=uicontrol('style','text',...
      'callback',' ',...
      'position',[10 280 60 13],...
      'horizontalAlignment','left',...
      'string', str1);

h.t(2)=uicontrol('style','text',...
      'callback',' ',...
      'position',[10 155 60 13],...
      'horizontalAlignment','left',...
      'string', str2);

%
% Cancel
%
h.u(3)=uicontrol('style','listbox',...
      'callback',' ',...
      'position',[30 60 350 90],...
      'string',' ');

h.u(4)=uicontrol('style','listbox',...
      'callback',' ',...
      'position',[30 180 350 90],...
      'string',' ');


listFiles={};
j=1;
for i=1:length(list2)
        listFiles(j)=cellstr(list2{i});
        j=j+1;
end
set(h.u(3), 'string', listFiles)


listFiles={};
j=1;
for i=1:length(list1)

warning off;
if (~isempty(list1{i}));
        listFiles(j)=cellstr(list1{i});
end;
       j=j+1;
end

warning on;
set(h.u(4), 'string', listFiles)
uiwait(gcf)
result = FinalResult;
close(gcf);



