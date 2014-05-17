function camera=loadCameraParameters( filename )


fid = fopen( filename , 'r' );

if ( fid == -1 ) 
    fprintf(strcat('Cannot open camera parameter file: ', filename));
    camera=-1;
    return 
end;


while ( feof(fid) ~=1 )
    [line]= fgetl( fid);
    pos=strfind( line, '=' );
    clear value;
    clear parname;
    if ( length(pos)==0 ) continue; end;
    parname = line( 1: pos(length(pos))-1 );
    value = str2num( line( pos(length(pos))+1:end ));
    
    if ( strcmp(parname,'pixelSize' ))  camera.pixelSize=value; end;
    if ( strcmp(parname,'axialPixelSize' )) camera.axialPixelSize=value; end;
    if ( strcmp(parname,'radialResolutionValues' )) camera.radialResolutionValues=value; end;
    if ( strcmp(parname,'radialResolutionRadius' )) camera.radialResolutionRadius=value; end;
    if ( strcmp(parname,'members') ) camera.members=value; end;
    if ( strcmp(parname,'theta') ) camera.theta=value; end;
    if ( strcmp(parname,'axialResolutionValues')) camera.axialResolutionValues=value; end;
    if ( strcmp(parname,'axialResolutionRadius')) camera.axialResolutionRadius=value; end;
    if ( strcmp(parname,'calibrationFactor' )) camera.calibrationFactor=value; end;
    if ( strcmp(parname,'voxelSize')) camera.voxelSize=value; end;
    if ( strcmp(parname,'randomEffectConstant' )) camera.randomEffectConstant=value; end;
    if ( strcmp(parname,'randomCorrectionConstants') ) camera.randomCorrectionConstants=value; end;
    if ( strcmp(parname,'projectionOffset') ) camera.projectionOffset=value; end;
    if ( strcmp(parname,'FOV') ) camera.FOV=value; end;
    if ( strcmp(parname,'scale')) camera.scatterscale=value; end;
    if ( strcmp(parname,'A1')) camera.A1=value; end;
    if ( strcmp(parname,'A2')) camera.A2=value; end;
    if ( strcmp(parname,'A3')) camera.A3=value; end;
    if ( strcmp(parname,'A4')) camera.A4=value; end;
    if ( strcmp(parname,'A5')) camera.A5=value; end;
    if ( strcmp(parname,'A6')) camera.A6=value; end;
    if ( strcmp(parname,'A7')) camera.A7=value; end;
    if ( strcmp(parname,'A8')) camera.A8=value; end;
    if ( strcmp(parname,'A10')) camera.A10=value; end;
    if ( strcmp(parname,'A11')) camera.A11=value; end;
    if ( strcmp(parname,'A12')) camera.A12=value; end;
    if ( strcmp(parname,'A13')) camera.A13=value; end;
    if ( strcmp(parname,'A14')) camera.A14=value; end;
    if ( strcmp(parname,'A15')) camera.A15=value; end;
    if ( strcmp(parname,'A16')) camera.A16=value; end;
    if ( strcmp(parname,'A18')) camera.A18=value; end;
    if ( strcmp(parname,'A21')) camera.A21=value; end;
        
        
        
        
 end;



fclose ( fid );