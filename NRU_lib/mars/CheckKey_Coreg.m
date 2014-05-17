function CheckKey_Coreg(obj,view)
%
% Key-input checking callback for Coreg
%
c=obj;
Char=get(gcbo,'CurrentCharacter');
userdat=get(gcbf,'userdata');
step=userdat.TransStep;
stepa=userdat.AngStep;
Alpha=userdat.alpha;
title(['Transl. ' num2str(step) ' mm. Rot. \pi/' num2str(pi/stepa) ]);
A1=diag([1 1 1 1]);
if strcmp(Char,'+')
    step=step*2;
    userdat.TransStep=step;
elseif strcmp(Char,'-')
    step=step/2;
    userdat.TransStep=step;
elseif strcmp(Char,'/');
    stepa=stepa/2;
    userdat.AngStep=stepa;
elseif strcmp(Char,'*');
    stepa=stepa*2;
    userdat.AngStep=stepa;
elseif strcmp(Char,'x');
    close(gcbf);
elseif strcmp(Char,'s');
    Alpha=Alpha+0.1;
    if Alpha<=1
        userdat.alpha=Alpha;
        alpha(c,Alpha);
    end
elseif strcmp(Char,'a');
    Alpha=Alpha-0.1;
    if Alpha>=0
        userdat.alpha=Alpha;
        alpha(c,Alpha);
    end
else
    for j=1:length(c)
        x=get(c(j),'xdata');
        y=get(c(j),'ydata');
        if not(isempty(Char))
            chnum=Char-0;
            switch chnum
                case 28
                    x=x-step;
                    A1(view(1),4)=-step;
                    set(c(j),'xdata',x,'ydata',y)
                case 29
                    x=x+step;
                    A1(view(1),4)=step;
                    set(c(j),'xdata',x,'ydata',y)
                case 30 %up
                    y=y+step;
                    A1(view(2),4)=step;
                    set(c(j),'xdata',x,'ydata',y)
                case 31 %down
                    y=y-step;
                    A1(view(2),4)=-step;
                    set(c(j),'xdata',x,'ydata',y)
                case 44 %rotate clockwise
                    if ~isempty(get(c(j),'XData'))
                        rotate(c(j),[0 0 1],180*stepa/pi,[userdat.centre 0]);
                        angs=zeros(1,3);
                        angs(view(3))=-stepa;
                        T=diag([1 1 1 1]);
                        T(view(1),4)=userdat.centre(1);
                        T(view(2),4)=userdat.centre(2);
                        A1=T*diffA(angs)*inv(T);
                    end
                case 46 %rotate counter-clockwise
                    if ~isempty(get(c(j),'XData'))
                        rotate(c(j),[0 0 1],-180*stepa/pi,[userdat.centre 0]);
                        angs=zeros(1,3);
                        angs(view(3))=stepa;
                        T=diag([1 1 1 1]);
                        T(view(1),4)=userdat.centre(1);
                        T(view(2),4)=userdat.centre(2);
                        A1=T*diffA(angs)*inv(T);
                    end
            end
        end
    end
end
userdat.A=A1*userdat.A;
set(gcbf,'userdata',userdat);
if isobj(gcbf)
    title(['Transl. ' num2str(step) ' mm. Rot. \pi/' num2str(pi/stepa) ]);
end
