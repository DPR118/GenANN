load('dis_quote.mat')
load('dis_bal.mat')
%Parameters
sheets= length(bal.date);
input_col= 6;
delta_days= 17;
n_fold= 2;


A= zeros(input_col,sheets);
B= zeros(1,sheets);

bal_date= datenum(bal.date);
dis_date= datenum(dis.date);

%create input data for each 10q document
for i=1:sheets
    
    A(1,i)= bal.dividendpayoutratio(i);
    A(2,i)= bal.earnings(i)/10^9;
    A(3,i)= bal.pbratio(i);
    A(4,i)= bal.peratio(i);
    A(5,i)= bal.roa(i);
    A(6,i)= bal.roe(i);
    A(7,i)= bal.shareholderequity(i)/10^8;
    A(8,i)= bal.netmargin(i);
    %A(9,i)= bal.splitfactor(i);
    
    %Find corresponding data in stock quote dates
    [num,index]= min(abs(dis_date-bal_date(i)));
    if(datenum(dis.date(index))-datenum(bal.date(i))>0)
        index= index+1;
    end
    
    %Create Target vector from found index
    if(index>length(dis.date))
        A= A(:,1:i-1);
        B= B(:,1:i-1);
        break
    end
    
    %Find target change in price coded as 1 or 0
    B(i)= (dis.close(index-delta_days)-dis.close(index) > 0);
    
    
end

A= [A;B];
[m,n]= size(A);
%A= A(:,randperm(n));
test_start= ceil(length(A)*(1/n_fold));

Inputs= A(1:m-1,1:test_start);
Targets= A(m,1:test_start);
Targets= [Targets; ~Targets];

Test_Inputs= A(1:m-1,test_start+1:end);
Test_Targets= A(m,test_start+1:end);
Test_Targets= [Test_Targets; ~Test_Targets];
