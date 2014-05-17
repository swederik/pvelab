function Addfieldnames=struct2entries(name_base,s_base)
% Recursive function that return a structure of strings of all possible
%   entries in a given structure and/or cell array.
%
% Input:
%   names_base: name(string) of given structure/cell array
%   s_base    : structure/cell array where all entries are like to be found
%
% Output:
%   Addfieldnames{n}: String structure of all possible entriens of a given
%                        structure (s_base).
%        Fields of Addfieldnames{n}
%           Addfieldnames{n}.entry: An (string)entry of structure s_base. 
%           Addfieldnames{n}.size: Dimension of variable in given entry
%           Addfieldnames{n}.bytes: Number of bytes of variable in given entry
%           Addfieldnames{n}.class: Type of variable in given entry                           
%       Example:
%            Read variable of given entry using 'eval()':
%               A=eval(Addfieldnames{n}.entry)
%
%   Uses:
%       logProject
%____________________________________________
%SW version: 190303TD, T. Dyrby, 190303, NRU
%

% % Structure ONLY for test
%   s_base.wQ{1}.a=[1,2];
%   s_base.wQ{2}.a=[3,4];
%   s_base.wQ{3}.a=[5,6];
%   s_base.wQ{4}.a=[7,8];
%   s_base.a.q='test1';
%   s_base.b.q='test2';
%   s_base.c.q=[7,8];
%    name_base='s_base';
 

%__________ Check for valid input
if(~iscell(s_base) & ~isstruct(s_base))
    Addfieldnames=[];
    return
end

%__________ Get all fields of s_base
[Addfieldnames_tmp,AddDatatypeInfo]=entries_rec(s_base);

%__________ Add name and collect given structure w. fileds:entry, size, name and class
for(i=1:length(Addfieldnames_tmp))
    if(iscell(s_base))
        Add2fieldnames=[name_base,Addfieldnames_tmp{i}];        
    else
        Add2fieldnames=[name_base,'.',Addfieldnames_tmp{i}];
    end    
    
    Addfieldnames{i}.entry=Add2fieldnames;
    Addfieldnames{i}.size=AddDatatypeInfo{i}.size;
    Addfieldnames{i}.bytes=AddDatatypeInfo{i}.bytes;
    Addfieldnames{i}.class=AddDatatypeInfo{i}.class;
end
return

%___________________________________________________________________________
% Recursive function that search though a structure
%
% Return: String structure of all possible entriens of a given
% structure.
%
%___________________________________________________________________________
%SW version: 190303TD, T. Dyrby, 190303, NRU
%
function [Addfieldnames,AddDatatypeInfo]=entries_rec(s_base)

%________ Init parameters
Addfieldnames=[];
AddDatatypeInfo=[];
New_base='s_base';
fieldnamesbase{1}='';
L_fieldnamesbase=1;    

if(isstruct(eval(New_base)))
    fieldnamesbase=fieldnames(s_base);%Get fields    
    L_fieldnamesbase=length(fieldnamesbase);
end

for(i=1:L_fieldnamesbase)    
    %_______ Is cell array
    if(iscell(eval(New_base)))%iscell(s_base) | iscell(eval(New_base)))
        ss_base=eval(New_base);
        
        [x,y]=size(ss_base);%s_base);%Get sizeof cell array
        for(ix=1:x)%Search through cell array (possible of 2D arrays)
            for(iy=1:y)                
                if(isempty(ss_base{ix,iy}))%A cell array can have empty cells
                    continue
                end      
                if(isstruct(ss_base{ix,iy}) | iscell(ss_base{ix,iy}))%If not endpoint            
                    [Add2New_base,Add2DatatypeInfo]=entries_rec(ss_base{ix,iy});
                    AddDatatypeInfo=[AddDatatypeInfo Add2DatatypeInfo];
                    
                    for(iAdd=1:length(Add2New_base))
                        Addfieldnames{end+1}=[fieldnamesbase{i},'{',num2str(ix),',',num2str(iy),'}','.',Add2New_base{iAdd}];
                    end               
                else% Is a endpoint!                                 
                    Addfieldnames{end+1}=[fieldnamesbase{i},'{',num2str(ix),',',num2str(iy),'}'];
                   
                    %________ Add infor of variable
                    % Here some information on variable in current field can be written....
                    a=eval(New_base);
                    info=whos('a');%Get information on actual variable
                    AddDatatypeInfo{end+1}.size=info.size;
                    AddDatatypeInfo{end}.bytes=info.bytes; 
                    AddDatatypeInfo{end}.class=info.class;
                end  
            end%ii
        end%i       
        if(i<L_fieldnamesbase)% Update new structure
            New_base=['s_base','.',fieldnamesbase{i+1}];
        end        
        %_______ Is field
    else        
        New_base=['s_base','.',fieldnamesbase{i}];
        
        if(isstruct(eval(New_base)) | iscell(eval(New_base)))  % Is a struct or end point?
            [Add2New_base,Add2DatatypeInfo]=entries_rec(eval(New_base));        
            AddDatatypeInfo=[AddDatatypeInfo Add2DatatypeInfo];
            
            for(ii=1:length(Add2New_base))
                if(iscell(eval(New_base)))%If next entry was a cell array
                    Addfieldnames{end+1}=[fieldnamesbase{i},Add2New_base{ii}];
                else%If next entry was a cell array
                    Addfieldnames{end+1}=[fieldnamesbase{i},'.',Add2New_base{ii}];
                end                        
            end
        else% Is a endpoint!
            
            Addfieldnames{end+1}=fieldnamesbase{i};
            %________ Add infor of variable
            % Here some information on variable in current field can be written....
            a=eval(New_base);
            info=whos('a');   %Get information on actual variable         
            AddDatatypeInfo{end+1}.size=info.size;
            AddDatatypeInfo{end}.bytes=info.bytes;
            AddDatatypeInfo{end}.class=info.class;
        end    
        
        if(i<L_fieldnamesbase)% Update new structure
            New_base=['s_base','.',fieldnamesbase{i+1}];
        end        
    end%iscell     
end%fieldnamebase

