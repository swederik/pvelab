function []=display_text(varargin)  
% simple GUI function that displays string inside results frame.  
% example: display_text('Hello user, problem may be:','1. tjeck method options?','2. OS must be linux?');
%
% Input:  
%   varargin    : Abitrary number of input strings,
%                 to be shown inside display frame                   
% Output:
%   none      
%
% Note
%   the text/string is cleared in taskGUI.m when the figure is resized or a
%   task button is pressed.
%____________________________________________
% M. Twardak 210903, NRU
%SW version: 010603TD

displayhandle=findobj('Tag','Result'); %get handle to Result axes

if(isempty(displayhandle))               %tjeck if handle and thereby Result axes exists   
    %crap=1
    return
end
cla(displayhandle);                      %clear axes before making text

for i=1:nargin                                             %loops for number of strings   
    if(ischar(varargin{i}))                                %tjeck if input is string
        displaysize=get(displayhandle,'position');         %get size of Result axes
        text('parent',displayhandle,...   
            'units','pixels',...
            'fontsize',12,...
            'fontname','Courier New',... 
            'position',[5 displaysize(4)-i*22],...        
            'HorizontalAlignment','left',... 
            'String',varargin{i},...
            'Interpreter','none',...
            'Clipping','on',...
            'FontWeight','bold',...
            'tag','display_text');  
    else
        return
    end
end