classdef GMEANNs < handle
    %GMEANNs controller to perform genetic optimization on a population
    %or populations of GenANN elements.
    %   GenANNCon(PopulationSize,Species,Iterations,Survivors,PenaltyFunction,Neurons,Inputs,Targets)
    %
    %   PopulationSize is the number of solutions in each species
    %
    %   Species is the number of species or number of competing parrallel
    %   genetic solutions
    %
    %   Iterations is the stopping condition based on number of genetic
    %   loops
    %
    %   Survivors is the number of elite that are held over from one
    %   iteration to the next
    %
    %   Penalty function is the selection of penalty function type. Valid inputs
    %   are 0,1,2. 0 chooses no penalty. 1 chooses a euclidean distance
    %   based penalty. 2 chooses a correlation based penalty.
    %   
    %   Neurons is the number of hidden neurons in the hidden layer of each
    %   ANN solution
    %   
    %   Inputs is an array of column vectors. each column vector is a
    %   complete set of inputs to be used for training. Therefor, each
    %   column in the 2-D array makes up a set of inputs to the networks.
    %   
    %   Targets is an array of column vectors. each column vector is a
    %   complete set of Targets to be used for training. Therefor, each
    %   column in the 2-D array makes up a set of Targets to the networks.
    %
    %   Normal Use for single species ANN training
    %   x= GenANNCon(10,1,2000,1,0,3,[1:10],cos([1:10]))
    %   
    %   For multiple Species without ensemble learning and multiobjective
    %   optimization
    %   x= GenANNCon(12,2,2000,1,0,3,[1:10],cos([1:10]))
    %   
    %   For multiple Species with ensemble learning and multiobjective
    %   optimization using the distance penalty function
    %   x= GenANNCon(12,2,2000,1,1,3,[1:10],cos([1:10]))
    %   
    %   For multiple Species with ensemble learning and multiobjective
    %   optimization using the Correlation penalty function
    %   x= GenANNCon(12,2,2000,1,2,3,[1:10],cos([1:10]))
    
    
%     To Do:
%     Work on the survival of the last round. It should save both the least error
%     and the least cost. As of now it only saves based cost.
    
    properties
        Populations= []
        PopulationSize
        Species
        MaxPenalty= 24;
        Iterations
        Survivors
        PenaltyFunction
    end
    
    methods
        function obj= GMEANNs(PopulationSize,Species,Iterations,Survivors,PenaltyFunction,Neurons,Inputs,Targets)
            obj.PopulationSize= PopulationSize;
            obj.PenaltyFunction= PenaltyFunction;
            obj.Survivors= Survivors;
            obj.Iterations= Iterations;
            obj.Species= Species;
            
            for i= 1:obj.Species
               obj.Populations= [obj.Populations; GenANN(obj.PopulationSize,Neurons,Inputs,Targets)];
            end
        end
        
        function obj= Penalize(obj)
            for s= 1:obj.Species
                for i= 1:length(obj.Populations(s,:))
                    if obj.PenaltyFunction==1
                        obj.Populations(s,i).DistPenalize(obj.MaxPenalty/obj.Species,obj.Populations([1:end ~= s],1));
                    elseif obj.PenaltyFunction==2
                        obj.Populations(s,i).CorrPenalize(obj.MaxPenalty/obj.Species,obj.Populations([1:end ~= s],1));
                    end
                end
            end
        end
        
        function obj= SortError(obj)
            for s= 1:obj.Species
                [~, ind]= sort([obj.Populations(s,:).Error]);
                obj.Populations(s,:)= obj.Populations(s,ind);
            end
        end
        
        function obj= SortCost(obj)
            for s= 1:obj.Species
                [~, ind]= sort([obj.Populations(s,:).Cost]);
                obj.Populations(s,:)= obj.Populations(s,ind);
            end
        end
        
        function obj= Trim(obj)
            obj.Populations(:,obj.PopulationSize+1:end)= [];
        end
        
        function obj= Crossover(obj,count)
            Children= [];
            for s= 1:obj.Species
                tempOutput= [];
                tempInput= obj.Populations(s,obj.Survivors+1:end);
                for i= 1:obj.Survivors
                    tempOutput= [tempOutput tempInput.Breed(obj.Populations(s,i),0.5*(cos((count/(obj.Iterations/20))*pi)+1))];
                end
                Children= [Children; tempOutput];
            end
            %obj.Populations= [obj.Populations Children];
            obj.Populations(:,obj.Survivors+1:end)= [];
            obj.Populations= [obj.Populations Children];
        end
        
        function obj= dispStats(obj, extraDisp, extraDispText)
            error= [];
            cost= error;
            for s= 1:obj.Species
                error= [error obj.Populations(s,1).Error];
                cost= [cost obj.Populations(s,1).Cost];
            end
            disp([extraDispText, ' - ', num2str(extraDisp), ' : error - ', num2str(error), ' : Cost - ', num2str(cost)]);
        end
        
        function obj= Optimize(obj)
            
                obj.SortError;
                if obj.PenaltyFunction>0; obj.Penalize ;obj.SortCost; end
                
            for count= 1:obj.Iterations
                obj.Crossover(count);
                obj.SortError;
                if obj.PenaltyFunction>0; obj.Penalize; obj.SortCost; end
                obj.Trim;
                
                obj.dispStats(count, 'Count');
                
            end
            
            save('Last_Run')
        end
        
    end
    
end

