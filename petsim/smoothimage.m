function imaout = smoothimage(imain,sizeout)
% function imaout = smoothimage(imain,sizeout)
% smoothing the image
  imain = imresize(imain,[sizeout sizeout]);
  imatmp = conv2(imain,kernel(2,'gaussian'),'full');
  imaout = imresize(imatmp,[sizeout sizeout]);