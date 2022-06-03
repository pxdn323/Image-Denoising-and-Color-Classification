%read in image
I=double(imread('./castle.jpg'));


%initiallize parameters
w=size(I,1);
h=size(I,2);
NumSites=w*h;
NumLabels=5;
Inew=reshape(I,[NumSites,3]);


%initial labels by kmeans
[ini_label ini_centr]=kmeans(Inew,NumLabels);


%initial match cost
cost_match=zeros(NumLabels,NumSites);
for i=1:NumSites
    for j=1:NumLabels      
        cost_match(j,i)=sum(abs(Inew(i,:)-ini_centr(j,:)))/3;        
    end
end


%initial GCO 
Handle = GCO_Create(NumSites,NumLabels);
GCO_SetLabeling(Handle,ini_label);
GCO_SetDataCost(Handle,cost_match);


%set weights for neighborhood
Weights=sparse(NumSites,NumSites);
site=0;
for j=1:h
    for i=1:w
        site=site+1;
        if (i<w)
            Weights(site,site+1)=1;
        end
        if (j<h)
            Weights(site,site+w)=1;
        end
    end
end
GCO_SetNeighbors(Handle,Weights);


%GCO processing
GCO_SetVerbosity(Handle,2);
GCO_SetLabelOrder(Handle,randperm(NumLabels));
GCO_Expansion(Handle);
Label_resul = GCO_GetLabeling(Handle);  


%write out image
Inew=zeros(w,h,3);
New=reshape(Label_resul,[w,h]);
for i=1:NumLabels
    for x=1:w
        for y=1:h
            if New(x,y)==i
                Inew(x,y,:)=ini_centr(i,:);
            end
        end
    end
end
imwrite(uint8((Inew)),['castle',num2str(NumLabels),'.png']);