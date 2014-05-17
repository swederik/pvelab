function s = colour8(m)
% Colour8 white,blue,light green,red,light blue, green purple and yellow color map.
%
%         map = Colour8(num_colors)
%
% Colour8(M) returns an M-by-3 matrix containing a "Colour8" colormap.
% Colour8, by itself, is the same length as the current colormap.
%
% For example, to reset the colormap of the current figure:
%
%           colormap(Colour8)
%
% See also HSV, GRAY, PINK, HOT, COOL, BONE, COPPER, FLAG,
%          COLORMAP, RGBPLOT.

%         Copyright (c) 1984-92 by The MathWorks, Inc.
%         Color8 version made by DEOEC PET Center

if nargin < 1, m = size(get(gcf,'colormap'),1); end

%n = fix(3/8*m);

base = [
  0.0000 0.0000 0.0000 
  1.0000 0.5000 0.2500
  0.0000 0.5020 1.0000
  0.0000 1.0000 0.2500
  1.0000 0.0000 0.0000
  0.5000 1.0000 1.0000
  0.0000 0.5000 0.2500
  1.0000 0.5000 1.0000
  1.0000 1.0000 0.5000
];

n = length(base);

X0 = linspace (1, n, m);

s=interp1( [1:9], base, X0, 'nearest' );
