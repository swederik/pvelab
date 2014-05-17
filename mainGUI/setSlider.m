function setSlider(hSlide,hText)
% This function sets up the slider hSlide to fit the 
% text in hText, and creates a callback for the 
% slider that updates hText.
% 
% Command can be 'new' or 'update' (if text changes)
% 
% by TR140104

%break text to fit textfield and save in slider userdata
[ud.txt,ud.noLines,ud.Hight]=lineBreaks(hText);

%save texthandle
ud.hText=hText;        

%         ud.Hight
%         ud.noLines

%set the lines that are currently shown      
if (ud.noLines-ud.Hight)<=0
    set(hSlide,'enable','off');          
    ud.maxShow=2;
else
    set(hSlide,'enable','on');
    ud.maxShow=ud.noLines-ud.Hight+1;
end
ud.minShow=1;

%set slider min and max and step and value 
set(hSlide,'max',ud.maxShow,'min',1,'Value',ud.maxShow,'SliderStep',[1/ud.maxShow 1/ud.maxShow]);

%define slider callback        
set(hSlide,'callback',{@updateText_callback});

%Save all info in slider userdata
set(hSlide,'userdata',ud);        

%set text and disable if text is small
updateText_callback(hSlide);



function [TxtOut,noLines,fieldSize]=lineBreaks(hText)
set(hText,'visible','off');
%Get text and textfield size
Txt=get(hText,'string');
Pos=get(hText,'position');

TxtOut='';
noLines=1;
fieldSize=0;
for n=1:length(Txt)
    if double(Txt(n))==10, noLines=noLines+1; end;
    TxtOut=[TxtOut,Txt(n)];    
    set(hText,'string',TxtOut);    
    Ext=get(hText,'extent');
    if Ext(3)>Pos(3)
        
        Breaks=find(double(TxtOut)==10);
        if isempty(Breaks), Breaks=1; end
        spaceline=find(double(TxtOut(1:end-1))==32 | double(TxtOut(1:end-1))==45);%Find spaces and lines
        spaceline=spaceline(spaceline>Breaks(end));
        
        %insert linebreak
        if ~isempty(spaceline)
            TxtOut=[TxtOut(1:spaceline(end)),sprintf('\n'),TxtOut(spaceline(end)+1:end)]; %insert linebreak if length exceeds field bound
        else
            TxtOut=[TxtOut(1:end-1),sprintf('\n'),TxtOut(end)];
        end      
        noLines=noLines+1;
    end
    
    %Check field hight
    if ~fieldSize & Ext(4)>Pos(4)
        if isunix %OS problem in extent function
            fieldSize=noLines;
        else
            fieldSize=noLines-1;
        end
    end
end
if ~fieldSize, fieldSize=noLines; end
set(hText,'visible','on');

function updateText_callback(hSlide,varargin)
ud=get(hSlide,'userdata');
Val=(ud.maxShow-get(hSlide,'value'))+1;

if (ud.noLines-ud.Hight)<0
    set(ud.hText,'string',ud.txt);
else    
    ud.txt=sprintf(['\n',ud.txt,'\n']);
    lb=find(double(ud.txt)==10);
    p1=lb(round(Val))+1;
    p2=lb(round(Val+ud.Hight))-1;
    
    set(ud.hText,'string',ud.txt(p1:p2));
end


