function [fn, FnVar, FnGrad, FnGradCov, constraint, ConstraintCov, ...
          ConstraintGrad, ConstraintGradCov] = SANRND(x, runlength, problemRng, seed, ProblemInstance)
% INPUTS
% x: a column vector equaling the decision variables theta
% runlength: the number of longest paths to simulate
% problemRng: a cell array of RNG streams for the simulation model 
% seed: the index of the first substream to use (integer >= 1)
% ProblemInstance: a cell containing the problem instance:
%      num_nodes: an integer
%      num_arcs: an integer
%      arcs: a (num_arcs by 2) matrix of arcs, containing the
%      indices  of the "from" and "to" nodes in columns.
%
% RETURNS
% Estimated fn value
% Estimate of fn variance divided by runlength (square of standard error)
% Estimated gradient. This is an IPA estimate so is the TRUE gradient of
% the estimated function value
% Estimated gradient covariance matrix divided by runlength (square of
% standard error)

%   *************************************************************
%   ***          Adapted from SAN by Shane Henderson          ***
%   ***           sgh9@cornell.edu    March 12, 2020          ***
%   *************************************************************

constraint = NaN;
ConstraintCov = NaN;
ConstraintGrad = NaN;
ConstraintGradCov = NaN;


if (runlength <= 0) || (round(runlength) ~= runlength) || (seed <= 0) || (round(seed) ~= seed)
    fprintf('runlength should be a positive integer,\nseed should be a positive integer\n');
    fn = NaN;
    FnVar = NaN;
    FnGrad = NaN;
    FnGradCov = NaN;
    
else % main simulation
    numnodes = ProblemInstance{1};
    numarcs = ProblemInstance{2};
    arcs = ProblemInstance{3}; %numarcs by 2 matrix with "from" and "to" of each arc
    
    [a, b] = size(x);
    if (a == 1) && (b == numarcs)
        theta = x'; %theta is a column vector
    elseif (a == numarcs) && (b == 1)
        theta = x;
    else
        fprintf('x should be a column vector with %d rows\n', numarcs);
        fn = NaN; FnVar = NaN; FnGrad = NaN; FnGradCov = NaN;
        return;
    end
    rowtheta = theta'; % Convert to row vector
    
    % Get random number stream from input and set as global stream
    DurationStream = problemRng{1};
    RandStream.setGlobalStream(DurationStream);
    
    % Initialize for storage
    cost = zeros(runlength, 1);
    CostGrad = zeros(runlength, numarcs);
    
    % Run simulation
    for i = 1:runlength
            
        % Start on a new substream
        DurationStream.Substream = seed + i - 1;
        
        % Generate random duration data
        arc_lengths = exprnd(rowtheta); % rowtheta gives the mean
        
        T = zeros(numnodes, 1); % longest path to this node from first
        Tderiv = zeros(numnodes, numarcs); % gradient
        
        % Time to reach node 1 is always 0, and so is its gradient
        for j = 1:numarcs
           origin = arcs(j, 1); % index of starting point of arc
           destination = arcs(j, 2); % index of destination of arc
           new_time = T(origin) + arc_lengths(j);
           if new_time > T(destination) % This arc creates a later start time for destination
               T(destination) = new_time;
               Tderiv(destination, :) = Tderiv(origin, :);
               Tderiv(destination, j) = arc_lengths(j) / rowtheta(j);
           end
        end
        
        cost(i) = T(numnodes) + sum(1 ./ rowtheta);
        CostGrad(i, :) = Tderiv(numnodes, :) - 1 ./ rowtheta.^2;
    end
    
    % Calculate summary measures
    if runlength==1
        fn=cost;
        FnVar=0;
        FnGrad=CostGrad;
        FnGradCov=zeros(length(CostGrad));
    else
        fn = mean(cost);
        FnVar = var(cost)/runlength;
        FnGrad = mean(CostGrad, 1); % Calculates the mean of each column as desired
        FnGradCov = cov(CostGrad)/runlength; %FnGradCov = cov(CostGrad, 2);
    end
end
