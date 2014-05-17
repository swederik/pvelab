function [SegmentedmriImg, mrihdr]=loadSegmentedMRI( filenames, directory );
    pinfo.color=[0 1 0];
    pinfo.title='Load MRI files';
    pinfo.size=1;
    p=progbar(pinfo);
number_of_files=size(filenames,1);

if ( (number_of_files==1) && (length(strfind( lower(char(filenames)), '_seg1.img' )) > 0) )
 
    [vol_1, mrihdr] = psReadAnalyzeImg([directory char(filenames)]);

    progbar(p,10);
    [vol_2, hdr2] = psReadAnalyzeImg([directory strrep(char(filenames), '_seg1.img', '_seg2.img' )]);
    progbar(p,20);
    [vol_3, hdr3] = psReadAnalyzeImg([directory strrep(char(filenames), '_seg1.img', '_seg3.img') ]);
    progbar(p,30);
    if ( length(vol_1) >1  )
        vol_1 = round((vol_1-mrihdr.offset)*mrihdr.scale);
        m=max(max(max(vol_1)))/2;
        vol_1(find(vol_1<m)) = 0;
        vol_1(find(vol_1>=m)) = 1;
        SegmentedmriImg=vol_1;
    end;
    progbar(p,55);
   if ( length(vol_2) >1  )
        vol_2 = round((vol_2-hdr2.offset)*hdr2.scale);
        m=max(max(max(vol_2)))/2;
        vol_2(find(vol_2<m)) = 0;
        vol_2(find(vol_2>=m)) = 2;
        SegmentedmriImg=SegmentedmriImg+vol_2;
        SegmentedmriImg( find(SegmentedmriImg>2 ))=2;
    end;
    progbar(p,75);
    if ( length(vol_3) >1  )
        vol_3 = round((vol_3-hdr3.offset)*hdr3.scale);
        m=max(max(max(vol_3)))/2;
        vol_3(find(vol_3<m)) = 0;
        vol_3(find(vol_3>=m)) = 3;
        SegmentedmriImg=SegmentedmriImg+vol_3;
        SegmentedmriImg( find(SegmentedmriImg>3 ))=3;
    end;
    progbar(p,100);
    close(p);
    return;
end;

if ( number_of_files==1 )
    [SegmentedmriImg, mrihdr] = psReadAnalyzeImg([directory char(filenames)]);
    progbar(p,90);
    SegmentedmriImg = round((SegmentedmriImg-mrihdr.offset)*mrihdr.scale);
    progbar(p,100);
    close(p);
    return;
end;

if ( number_of_files >8 )
    number_of_files = 8;
end;

for i=1:number_of_files
    [vol, mrihdr]=psReadAnalyzeImg([directory char(filenames(i))]);
    if ( i==1 )
            SegmentedmriImg=zeros(size(vol));
    end;
    if ( length(vol) == 1 ) continue; end;
    vol = round((vol-mrihdr.offset)*mrihdr.scale);
    m=max(max(max(vol)))/2;
    vol(find(vol<m)) = 0;
    vol(find(vol>=m)) = i;
    SegmentedmriImg=SegmentedmriImg+vol;
    SegmentedmriImg( find(SegmentedmriImg>i ))=i;
    progbar(p,round( 100*i/number_of_files ));
end;
close(p);

