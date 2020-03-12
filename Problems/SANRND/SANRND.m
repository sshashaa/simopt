function [fn, FnVar, FnGrad, FnGradCov, constraint, ConstraintCov, ConstraintGrad, ConstraintGradCov] = RNDSAN(x, runlength, problemRng, seed)
% INPUTS
% x: a column vector equaling the decision variables theta
% runlength: the number of longest paths to simulate
% problemRng: a cell array of RNG streams for the simulation model 
% seed: the index of the first substream to use (integer >= 1)

% RETURNS
% Estimated fn value
% Estimate of fn variance
% Estimated gradient. This is an IPA estimate so is the TRUE gradient of
% the estimated function value
% Estimated gradient covariance matrix

%   *************************************************************
%   ***          Adapted from SAN by Shane Henderson          ***
%   ***            sgh9@cornell.edu    March 5, 2020          ***
%   *************************************************************

constraint = NaN;
ConstraintCov = NaN;
ConstraintGrad = NaN;
ConstraintGradCov = NaN;

% This should be passed in to this function as an argument. For now, I'm
% coding it here
% problem_info contains {num arcs, num nodes, list of arcs}
problemRng = {RandStream.create('mrg32k3a', 'NumStreams', 1)};
ProblemStream = problemRng{1};
RandStream.setGlobalStream(ProblemStream);

% We build a feedforward network with this many nodes
min_nodes=10;
max_nodes=70;
numnodes = randi([min_nodes max_nodes], 1, 1); %uniformly distributed on {min_nodes ... max_nodes}
fwd_arcs = 3; % Typical number of forward arcs from each node. Typically one more than this due to connectiveness loop
fwd_reach = 12; % Maximum distance forward for any arc from current node
arcs = zeros((fwd_arcs+1) * numnodes, 2); % two columns giving "from" index and "to" index. first entry here is guess at size
numarcs = 0;
for i = 1:numnodes-1  % Now generate feedforward arcs
    % From each node except the last "fwd_arcs" nodes, generate "fwd_arc" random forward arcs
    % Notice that there can be duplicates, so number of fwd arcs <= fwd_arcs
    indices = randi([i+1, min(numnodes, i+fwd_reach)], 1, fwd_arcs); % Indices of endpoints
    for j = 1:fwd_arcs
        numarcs = numarcs+1; % Remove duplicates later
        arcs(numarcs, :) = [i, indices(j)]; % Insert the arc from i to destination    
    end
end   
% Now need to make a pass to ensure the network is connected.
for i = 2:numnodes
    numarcs = numarcs+1; % Remove duplicates later
    precursor_index = randi([max(i-fwd_reach, 1) i-1], 1, 1);
    arcs(numarcs, :) = [precursor_index, i];
end
arcs = arcs(1:numarcs, :); % Truncate unneeded zero rows
arcs = unique(arcs, 'rows'); % Delete arc copies
arcs = sortrows(arcs); %arcs must be sorted in increasing order of start node
% If not sorted then the generation procedure will fail
[numarcs, ~] = size(arcs);
problem_info = {numnodes, numarcs, arcs};

% Test code to ensure consistency with SAN.m
%numnodes = 9;
%numarcs = 13;
%arcs = [
%    1 2;
%    1 3;
%    2 3;
%    2 4;
%    2 6;
%    3 6;
%    4 5;
%    4 7;
%    5 6;
%    5 8;
%    6 9;
%    7 8;
%    8 9];
%problem_info = {numnodes, numarcs, arcs};
%numnodes
%numarcs
%arcs

if (runlength <= 0) || (round(runlength) ~= runlength) || (seed <= 0) || (round(seed) ~= seed)
    fprintf('runlength should be a positive integer,\nseed should be a positive integer\n');
    fn = NaN;
    FnVar = NaN;
    FnGrad = NaN;
    FnGradCov = NaN;
    
else % main simulation
    numnodes = problem_info{1};
    numarcs = problem_info{2};
    arcs = problem_info{3}; %numarcs by 2 matrix with "from" and "to" of each arc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TEST CODE HERE - NEEDS TO BE REMOVED FOR RUNNING! %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    x = ones(numarcs, 1) * 2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
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
    fn = mean(cost);
    FnVar = var(cost)/runlength;
    FnGrad = mean(CostGrad, 1); % Calculates the mean of each column as desired
    FnGradCov = cov(CostGrad)/runlength; %FnGradCov = cov(CostGrad, 2);
end
