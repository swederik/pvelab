function s = unroll(M)
% UNROLL "Unrolling" a string matrix into a vector
%       S = UNROLL(M)  Converts a string matrix M into
%       a string vector with each row of M corresponding
%       to a line of S.
%       UNROLL removes trailing blanks from each row of M
%       and adds new line characters at the end of each row.

%  Kirill K. Pankratov, kirill@plume.mit.edu
%  03/31/95

 % Handle input ............................
if nargin==0, help unroll, return, end
if ~isstr(M)
  error('Input must be a string');
end
if isempty(M), s=[]; return, end

 % Get new line character ..................
c = computer;
if c(1:2)=='MA'     % MACs
  ch_nl = 13;
elseif c(1:2)=='PC' % DOS
  ch_nl = [13 10];
else                % UNIX
  ch_nl = 10;
end

ch_bl = ' ';   % Blank
ch_rm = 1;     % Mask for trailing blanks

sz = size(M);  % Get input matrix size

 % Find trailing blanks at the end of each row
M = M';
s = flipud(M);
s = cumprod(s==ch_bl);
s = flipud(s);
s = M.*(~s)+ch_rm*s;  % Replace trailing blanks

 % Add new line character at the end of each row
s = [s; ch_nl(ones(1,sz(1)),:)'];

 % Remove trailing blanks
s = s(s~=ch_rm);

 % Make it a row string
s = setstr(s');
