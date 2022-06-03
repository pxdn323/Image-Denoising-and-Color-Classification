%read in image
I=(imread('./denoise_input.jpg'));


%initiallize parameters
m_lambda=150;
background=[245,210,110];
foreground=[0,0,255];
w=size(I,1);
h=size(I,2);
NumVars=w*h;


%initial match cost
Inew1=[];Inew2=[];Inew3=[];
Inew1(:,:,1)=abs(I(:,:,1)-background(1,1));
Inew1(:,:,2)=abs(I(:,:,2)-background(1,2));
Inew1(:,:,3)=abs(I(:,:,3)-background(1,3));
Inew2(:,:,1)=abs(I(:,:,1)-foreground(1,1));
Inew2(:,:,2)=abs(I(:,:,2)-foreground(1,2));
Inew2(:,:,3)=abs(I(:,:,3)-foreground(1,3));
Inew1=(Inew1(:,:,1)+Inew1(:,:,2)+Inew1(:,:,3))/3;
Inew2=(Inew2(:,:,1)+Inew2(:,:,2)+Inew2(:,:,3))/3;
%turn to vector by rows
Inew1=Inew1';
Inew2=Inew2';
cost_match=[Inew1(:) Inew2(:)]';


%create BK object
Handle = BK_Create(NumVars);


%set weights for neighborhood
Weights=sparse(NumVars,NumVars);
site=1;%sites order: left up corner to right then next rows
for i=1:w
    for j=1:h
        if (i<w)
            Weights(site,site+w)=1;
        end
        if (j<h)
            Weights(site,site+1)=1;
        end
        site=site+1;
    end
end
BK_SetNeighbors(Handle,Weights);


%BK algorithm
Costs=cost_match;
BK_SetUnary(Handle,Costs);
BK_Minimize(Handle);
label = BK_GetLabeling(Handle);
label = reshape(label,[h,w]);
label = label';


%initial smoothness cost
cost_smoothness=zeros(w,h,2);
for i=1:w
    for j=1:h
        if (i<w)
            cost_smoothness(i,j,1)=cost_smoothness(i,j,1)+sum(1-abs(I(i+1,j,1)-background(1,1))^2/256/256)*abs(label(i+1,j)-1);
            cost_smoothness(i,j,2)=cost_smoothness(i,j,2)+sum(1-abs(I(i+1,j,1)-foreground(1,1))^2/256/256)*abs(label(i+1,j));
            cost_smoothness(i,j,1)=cost_smoothness(i,j,1)+sum(1-abs(I(i+1,j,2)-background(1,2))^2/256/256)*abs(label(i+1,j)-1);
            cost_smoothness(i,j,2)=cost_smoothness(i,j,2)+sum(1-abs(I(i+1,j,2)-foreground(1,2))^2/256/256)*abs(label(i+1,j));
            cost_smoothness(i,j,1)=cost_smoothness(i,j,1)+sum(1-abs(I(i+1,j,3)-background(1,3))^2/256/256)*abs(label(i+1,j)-1);
            cost_smoothness(i,j,2)=cost_smoothness(i,j,2)+sum(1-abs(I(i+1,j,3)-foreground(1,3))^2/256/256)*abs(label(i+1,j));
        end
        if (j<h)
            cost_smoothness(i,j,1)=cost_smoothness(i,j,1)+sum(1-abs(I(i,j+1,1)-background(1,1))^2/256/256)*abs(label(i,j+1)-1);
            cost_smoothness(i,j,2)=cost_smoothness(i,j,2)+sum(1-abs(I(i,j+1,1)-foreground(1,1))^2/256/256)*abs(label(i,j+1));
            cost_smoothness(i,j,1)=cost_smoothness(i,j,1)+sum(1-abs(I(i,j+1,2)-background(1,2))^2/256/256)*abs(label(i,j+1)-1);
            cost_smoothness(i,j,2)=cost_smoothness(i,j,2)+sum(1-abs(I(i,j+1,2)-foreground(1,2))^2/256/256)*abs(label(i,j+1));
            cost_smoothness(i,j,1)=cost_smoothness(i,j,1)+sum(1-abs(I(i,j+1,3)-background(1,3))^2/256/256)*abs(label(i,j+1)-1);
            cost_smoothness(i,j,2)=cost_smoothness(i,j,2)+sum(1-abs(I(i,j+1,3)-foreground(1,3))^2/256/256)*abs(label(i,j+1));
        end
    end
end
cost_smoothness1=cost_smoothness(:,:,1);
cost_smoothness2=cost_smoothness(:,:,2);
cost_smoothness1=cost_smoothness1';
cost_smoothness2=cost_smoothness2';
cost_smoothness=[cost_smoothness1(:) cost_smoothness2(:)];
cost_smoothness=cost_smoothness'/50;


%BK algorithm with smoothness
Costs_new=cost_match+cost_smoothness*m_lambda;
BK_SetUnary(Handle,Costs_new);
BK_Minimize(Handle);
label = BK_GetLabeling(Handle);
label = reshape(label,[h,w]);
label = label';


%write out image
for i=1:w
    for j=1:h
        if label(i,j)==1
            New(i,j,:)=background;
        else 
            New(i,j,:)=foreground;
        end
    end
end
imwrite(uint8((New)),['noise_with',num2str(m_lambda),'.png']);