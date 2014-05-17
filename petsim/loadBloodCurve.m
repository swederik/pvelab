function bloodpar = loadBloodCurve( filename )

fid = fopen( filename , 'r' );

if ( fid == -1 ) 
    fprintf(strcat('Cannot open blood curve file: ', filename));
    return;
end;

% times = str2num(fgetl( fid ));
% activity_values = str2num(fgetl( fid ));
blooddata = load(filename);

if ( length(blooddata(:,1))~=length(blooddata(:,2)) )
    fprintf(strcat('Error in blood curve file: number of times and activity values is different.'));
    return;
end;
bloodpar = eval_bloodcurve_par(blooddata(:,1),blooddata(:,2),1);
