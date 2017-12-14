filename = 'Australian Credit Approval Classification.txt';
[A,delimiterOut]=importdata(filename);
n_fold= 10;

A= A';
[m,n]= size(A);
A= A(:,randperm(n));
test_start= ceil(length(A)*(1/n_fold));

Inputs= A(1:14,1:test_start);
Targets= A(15,1:test_start);
Targets= [Targets; ~Targets];

Test_Inputs= A(1:14,test_start+1:end);
Test_Targets= A(15,test_start+1:end);
Test_Targets= [Test_Targets; ~Test_Targets];