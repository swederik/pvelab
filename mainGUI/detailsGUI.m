function detailsGUI(project,TaskIndex,MethodIndex,varargin)
% detailsGUI function lists the contents of 'project.taskDone{TaskIndex}'
%   in a new figure when 'details' buttom is pressed. 
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%   varargin    : Abitrary number of input arguments. (NOT USED)
%
% Output:
%
% Uses special functions:
%   struct2entries.m    
%____________________________________________
% M. Twardak, T. Dyrby and T. Rask 020903, NRU
%SW version: 111103MT,TD,TR
%
% Changes:
% 221203TR: Found smarter way for checking text-extent. (min + max added in listbox)

%____Init variables
linesize1=[1 1];
linesize2=[1 1];

%____ Make a figure centred on screen
resolution=get(0,'ScreenSize');    %returns [1 1 1024 768]
tag_name=['Tag_',project.taskDone{TaskIndex}.task];

%___ Check if Datails window already is open
if(isempty(findobj('tag',tag_name)))
    h_fig=figure('NumberTitle','off',...           
        'menubar','none',...
        'Position',[(resolution(3)-300)/2 (resolution(4)-400)/2 300+5 400+5],... %Initially create windowsize 300x400
        'Name',['Details - '  project.taskDone{TaskIndex}.task],...
        'Color',[192/255 192/255 192/255],...
        'Tag',tag_name,...
        'visible','off');  
else
    h_fig=findobj('tag',tag_name);
    figure(h_fig)
end

%____ Use struct2entries to read structure and return content
result=struct2entries('project.taskDone{TaskIndex}',project.taskDone{TaskIndex});

%____ Store the results in string array that is displayed later 
i_loops=size(result);                                                        %size returns [1 12] for example
for(i=1:i_loops(2))                                                            %number of items in structure is read into string array
    StringC1{i}=(result{i}.entry);                                           %items read into string array
    if strncmpi(StringC1{i},'project.taskDone{TaskIndex}.',28)               %remove the "project.taskDone{TaskIndex}." part
        StringC1{i}=strrep(StringC1{i},'project.taskDone{TaskIndex}.','');   %only if true, and the 28 characters actually exist
    end 
     
    try     
        %______ If field is logical
        if islogical(eval(result{i}.entry))
            if eval(result{i}.entry)
                StringC2{i}='[true]';
            else
                StringC2{i}='[false]';
            end
        else
            
            %____ If field is numeric
            if isnumeric(eval(result{i}.entry))
                StringC2{i}=[];           
                number=eval(result{i}.entry);
                howbig=size(number);
                for(iRow=1:howbig(1))
                    %add Row vector
                    numberSTR=num2str(number(iRow,1),3);
                    for(iCol=2:howbig(2))
                        numberSTR=[numberSTR,',',num2str(number(iRow,iCol),3)];
                    end          
                    StringC2{i}=strcat(StringC2{i}, ['[',numberSTR,']']);                            
                end %iRow
            else
                
                %____field should be character array (string)
                
                StringC2{i}=eval(result{i}.entry);
                
                %____If string is padded character array matrix, then write it in one
                %____line.                               
                str=size(StringC2{i});
                if (str(1)>1)
                    matr=cellstr(StringC2{i});
                    outString='[';
                    for (r=1:str(1))
                        outString=[outString,'''',matr{r},''';'];
                    end
                    outString(end)=']';
                    StringC2{i}=outString;
                end 
            end %isnumeric
        end %islogical
    catch 
        StringC2{i}='Can not show value.';
    end
  
    %____ mark empty spaces in string, because we want to remove them
    i_loops2=length(StringC2{i});
    if (i_loops2>1)
        for k=1:i_loops2-1             
            if StringC2{i}(k)==' '
                if StringC2{i}(k+1)==' '
                    StringC2{i}(k)='$'; %mark spaces to be removed
                end
            end  
        end
        %_____ Remove the marked $ spaces
        StringC2{i}=strrep(StringC2{i},'$','');   
    else
        if isempty(StringC2{i}), StringC2{i}='[empty]';, end;
        if (StringC2{i}(1)==' '), StringC2{i}='[empty]';, end;
    end %end for loop2
   
    %_____ Add : in end of StringC1
    StringC1{i}=[StringC1{i} ' : '];
    
    %_____ Put everything into StringC1
    StringC1{i}=[StringC1{i} StringC2{i}];   
    
    %_____ Save length of line, if it is the longest
    linesize1=size(StringC1{i});
    linesize1=linesize1(2); %we need the x size
    if linesize1>linesize2
        linesize2=linesize1; %linesize2 will show length of longest string
    else
        %the string is shorter and we are not interested
    end 
end

%_____ If similar names occur in start of strings, make a group
for(i=1:i_loops(2)-1) %i_loops runs through the rows of StringC1
    
    delimiter=['{' '.'];
    token=strtok(StringC1{i},delimiter);  
    
    %___see if we may remove this entry 
    if( strncmp(StringC1{i},StringC1{i+1},length(token)) )
        replace{i+1,2}=1; 
    else
        replace{i+1,2}=0;    
    end
    replace{i,1}=length(token); 
    replace{i+1,1}=length(token); 
end

%now the replace array contains the length of similar parts
%and we must replace them with spaces, if they are not the first entry. 
for(i=2:i_loops(2))
    if(replace{i,2}==1)
        for(k=1:replace{i-1,1})
            StringC1{i}(k)=' ';    
        end
    end  
end %_If similar names occur in start of strings, make a group

%textsize found in smarter way... 221203TR
% temp_text=uicontrol('parent',h_fig,...
%     'style','text',...
%     'tag','temptext',...
%     'string',StringC1,...
%     'units','pixels',...
%     'position',[0 0 1 1],...
%     'fontsize',10,...
%     'fontname','Courier New');
% positiontext=get(temp_text,'extent');  %returns [left,bottom,width,height]
% delete(temp_text);              %clean up after text 'extent' mission


%____ Display strings in listbox (because it has scroll)
text1_h=uicontrol('parent',h_fig,...
    'style','listbox',...
    'units','pixels',...  
    'position',[3 3 100 100],...
    'fontsize',10,...
    'fontname','Courier New',...   %fixedwidth
    'String',StringC1,...
    'tag','text_string',...
    'min',0,...
    'max',length(StringC1),...
    'BackgroundColor',[252/255 252/255 254/255]);

%___ we need to know the size of the string, so get 'extent' in pixels 
positiontext=get(text1_h,'extent'); %returns [left,bottom,width,height]

%___ make a little extra space
positiontext(3)=positiontext(3)+30;
positiontext(4)=positiontext(4)+30; 

%___ unix is strange...
%___ add 2 pixels per line (space between lines)
if isunix
    positiontext(4)=positiontext(4)+2*length(StringC1); 
end

%____ Tjeck is text is larger than screen, and adjust if it is larger
if positiontext(3)>resolution(3)
    positiontext(3)=resolution(3)-100;
end
if positiontext(4)>resolution(4)
    positiontext(4)=resolution(4)-200;
end

%____ set proper size for listbox
set(text1_h,'position',positiontext);

%____ Update figure size and position at centre of the screen
%set(h_fig,'resize','on');
set(h_fig,'units','pixels',... 
     'visible','on',...
     'Position',[(resolution(3)-positiontext(3))/2 (resolution(4)-positiontext(4))/2 positiontext(3) positiontext(4)],...
     'ResizeFcn',{@Resize_Callback});


 refresh(h_fig);

%--------------------------------------------------------------------
function Resize_Callback(h, eventdata)
figuresize=get(h,'position');  %returns position & size [x y 400 300]   
set(findobj(h,'tag','text_string'),'position',[3 3 figuresize(3)-5 figuresize(4)-5]);
