y= copy(x.Populations(:,1));
remove= 0;
[i ind]= sort([y.Error]);
y= y(ind);
y(length(y)-remove+1:end)= [];

Accuracys= [];

nodes= 9;
for i= 1:nodes
    start= ((i-1)*ceil(length(Test_Inputs)/nodes))+1;
    if i== nodes
        last= length(Test_Inputs);
    else
        last= ((i)*ceil(length(Test_Inputs)/nodes));
    end
   
    
    in= Test_Inputs(:,start:last);
    target= Test_Targets(:,start:last);
    
    t= []; for i=1:length(y); t= [t; y(i).ANN(in)]; end
    vote= max(t([1:2:length(y)*2],:))>max(t([2:2:length(y)*2],:));
    Error= vote-target(1,:);
    
    MSE= sum(Error.^2)/length(Error);
    Accuracy= 1-MSE;
    
    MAE= sum(abs(Error))/length(Error);
    Accuracy= 1-MAE;
    
    Accuracys= [Accuracys Accuracy];
end
Accuracys
mean(Accuracys)
