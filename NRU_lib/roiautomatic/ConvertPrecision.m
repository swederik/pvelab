function ConvertPrecision(temp_file,img_file)

% This function converts the precision of data in the template and in the
% analyzed image to 16 bits per pixel, if not already so

[temp_filepath, temp_filename] = fileparts(temp_file);
[img_filepath, img_filename] = fileparts(img_file);

cd(temp_filepath)
[img1,hdr1] = ReadAnalyzeImg(temp_filename);
if hdr1.pre ~= 16
    analyze2_16bit(temp_filename);
    temp_tag_old = get(findobj(gcf,'tag','templatefile'),'string');
    set(findobj(gcf,'tag','templatefile'),'string',[temp_tag_old(1:end-4) '_i16.img']);
end

cd(img_filepath)
[img2,hdr2] = ReadAnalyzeImg(img_filename);
if hdr2.pre ~= 16
    analyze2_16bit(img_filename);
    img_tag_old = get(findobj(gcf,'tag','imagefile'),'string');
    set(findobj(gcf,'tag','imagefile'),'string',[img_tag_old(1:end-4) '_i16.img']);
end