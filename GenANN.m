classdef GenANN < matlab.mixin.Copyable
% %This Class represents a geneticly trainable ANN.
% 
%       Normal use of this class is in conjunction with the GenANNCon class
% 
%       How to Call: GenANN(Population,Neurons,Inputs,Targets)
%       
%       Population - How many solutions do you want to genetically optimize. 
%       (larger populations take longer to optimize but small populations don't find good solutions as well)
%       
%       Neurons - The number of hidden neurons in each ANN solution
%       
%       Inputs - Array of input values with each column being a complete set of inputs to the network.
%       
%       Targets - Array of targets with each column being a complete set of desired outputs from the network.
%       
%       
%      
%       
%       
% 
% 
%     To Do:
%     Work on the penalty function. It needs to look at each neuron in a layer
%     separately. Rather than considering all weights as independant vectors, the 
%     weights associated with each neuron should be considered an independant vector.
%     Maybe the right way to handle the penalty function is to penalize correlation.
    
    properties
        NeuralGenes= []
        Neurons
        Error
        Penalty
        Cost
        MutationThresh
        CorrPenaltyThresh= 0.3
        Inputs= []
        Targets= []
        Net
        StructureB
        StructureIW
        StructureLW
    end
    
    methods
        
        function obj= GenANN(Population,Neurons,Inputs,Targets)
            if nargin > 0
                m = Population;
                obj(m) = GenANN;
            end
            if nargin > 1
                for m= 1:m
                    obj(m).Neurons= Neurons;
                    obj(m).Inputs= Inputs;
                    obj(m).Targets= Targets;
                    obj(m).InitGenNet;
                end
            end
        end
        
        function objarray= ErrorCalc(objarray)
            %Calculates the mean squared error of the ANN
            for i= 1:numel(objarray)
                [m,n]= size(objarray(1).Targets);
                objarray(1).Error= sum(sum((objarray(1).Net(objarray(1).Inputs)-objarray(1).Targets).^2))/(m*n);
            end
        end
        
        function obj= CostCalc(obj)
            %Sets the cost which is a way penalize networks in a
            %multiobjective system.
            obj.Cost= obj.Error+obj.Penalty;
        end
        
        function val= ANN(obj,inputs)
            val= obj.Net(inputs);
        end
        
        function objarray= SetWb(objarray)
            %Sets the Weights and biases of the ANN solution
            for i= 1:numel(objarray)
                objarray(i).Net= setwb(objarray(i).Net,objarray(i).NeuralGenes');
                %[obj.StructureB,obj.StructureIW,obj.StructureLW]= separatewb(obj.Net,getwb(obj.Net));
            end
            
            objarray.ErrorCalc;
        end
        
        function objarray= InitGenNet(objarray)
            %Initializes the ANN
            for i= 1:numel(objarray)
                objarray(i).Net= feedforwardnet(objarray(i).Neurons);
                objarray(i).Net= configure(objarray(i).Net, objarray(i).Inputs, objarray(i).Targets);
                objarray(i).NeuralGenes=  6.*(rand(1, length(getwb(objarray(i).Net)))-.5);
                objarray(i).MutationThresh= .7;
            end
                objarray.SetWb;
        end
        
        function obj= DistPenalize(obj,PossiblePenalty,Compare)
            %If multliobjective training is used, this penalty penalizes
            %ANNs for being to close together in euclidean space
            obj.Penalty= 0;
            for i= 1:numel(Compare)
                if obj.Error>Compare(i).Error
                    AddPenalty= (PossiblePenalty- pdist2(obj.NeuralGenes,Compare(i).NeuralGenes));
                    AddPenalty= AddPenalty*(AddPenalty>0);
                    obj.Penalty= obj.Penalty+ AddPenalty;
                end
            end
            obj.CostCalc;
        end
        
        function obj= CorrPenalize(obj,PossiblePenalty,Compare)
            %If multiobjective training is used, this penalty penalizes
            %ANNs for being to highly correlated
            obj.Penalty= 0;
            
            corrMatrix= obj.NeuralGenes';
            for i= 1:numel(Compare)
                if obj.Error>Compare(i).Error
                    corrMatrix= [corrMatrix Compare(i).NeuralGenes'];
                end
            end
            
            corrResult= corrcoef(corrMatrix);
            temp= corrResult(2:end,1);
            temp= temp(~isnan(temp(:,1)));
            temp= abs(temp);
            temp= temp(temp>obj.CorrPenaltyThresh);
            temp= temp-obj.CorrPenaltyThresh;
            if isempty(temp); temp= 0; end
            PenaltyCorr= temp;
            
            obj.Penalty= sum(PenaltyCorr)*PossiblePenalty/length(PenaltyCorr);
            obj.CostCalc;
        end
        
        function objarray= Mutate(objarray)
            %Called to inject mutation based on a stochastic process
            %The threshold for mutation oscillates over time to encourage
            %global and local optimization.
            
            randarray= rand(1,numel(objarray));
            round1Select= [objarray.MutationThresh]>randarray;
            
            round1Mutation= objarray(round1Select);
            before= copy(objarray);
            if ~isempty(round1Mutation)
                
                for i= 1:numel(round1Mutation)
                    round1Mutation(i).NeuralGenes= round1Mutation(i).NeuralGenes+(randn(1,length(round1Mutation(i).NeuralGenes)));
                end
                
            end
            objarray(round1Select)= round1Mutation;
            %[objarray.NeuralGenes]-[before.NeuralGenes]
        end
        
        function Children= Breed(objarray,spouse,MutationThreshMax)
            %Crossover function 
            Children= copy(objarray);
            
            for i= 1:numel(Children)
                
                if rand<Children(i).MutationThresh
                    MutMat= betarnd(20,20,1,length(Children(i).NeuralGenes));
                    Children(i).NeuralGenes= (MutMat.*Children(i).NeuralGenes)+((1-MutMat).*spouse.NeuralGenes);
                else
                    Children(i).NeuralGenes= (Children(i).NeuralGenes+spouse.NeuralGenes)./2;
                end
                
                Children(i).MutationThresh= MutationThreshMax*0.7;
            end
            
            Children.Mutate;
            Children.SetWb;
        end
    end
    
end

