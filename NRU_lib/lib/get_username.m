function UserName=get_username()
%
%  Function that returns username as a string. If string is empty 
%   it returns 'Unknown'.
%
%      UserName=GetUserName()
%
% CS, 30072003
%
if (strncmp(computer,'PCWIN',5))
   UserName=getenv('username');
else
   UserName=getenv('USER');
end
if (isempty(UserName))
   UserName='Unknown';
end

