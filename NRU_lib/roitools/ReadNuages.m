function [fv]=ReadNuages(OFFfile)
% function [fv]=ReadNuages(OFFfile)
%
% Reads an OFF file as output by the nuages reconstruction program
%
% fv is a faces + vertices struct
%

% Open the file
[fid, message] = fopen(OFFfile, 'rt');
if fid == -1
	disp(message)
	pause
end

% Read the first line (the header)
head=0;
while not(head==1) 
  headerline = fgetl(fid);
  if not(strcmp('#',headerline(1)))
    head=1;
  end
end
% Read the second line (the format info)
formatline = fgetl(fid);
[VertexCount, remainder] = strtok(formatline);
[PolygonCount, remainder] = strtok(remainder);
[EdgeCount, remainder] = strtok(remainder);
if ~isempty(remainder) 
	disp('There is an error in the second line in the Geomview-file')
else
	disp(strcat('Format read in from:', OFFfile))
end
VertexCount = str2num(VertexCount);
PolygonCount = str2num(PolygonCount);
disp([OFFfile ' has ' num2str(VertexCount) ' Vertices and ' ...
      num2str(PolygonCount) ' Faces']);

Vertices=fscanf(fid,'%f',[6*VertexCount]);
idx1=linspace(1,length(Vertices)-5,length(Vertices)/6);
idx2=idx1+1;
idx3=idx1+2;
Vertices=[Vertices(idx1) Vertices(idx2) Vertices(idx3)];
% Every other line is a normal. drop normals:
%vs=size(Vertices);
%Vertices=Vertices(1:2:vs(1),:);
Faces=fscanf(fid,'%f',[4*PolygonCount]);
idx1=linspace(1,length(Faces)-3,length(Faces)/4);
idx2=idx1+1;
idx3=idx1+2;
idx4=idx1+3;
Faces=[Faces(idx2) Faces(idx3) Faces(idx4)]+1;




% Close the file
status = fclose(fid);
if status == -1
	disp('An error occurred while closing the Geomview-file')
end
disp('File closed')

%fv=Vertices;
fv=struct('faces',Faces,'vertices',Vertices);