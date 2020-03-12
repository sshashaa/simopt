function [minmax, d, m, VarNature, VarBds, FnGradAvail, ...
          NumConstraintGradAvail, StartingSol, budget, ObjBd, ...
          OptimalSol, NumRngs, ProblemInstance] = SANRNDStructure(NumStartingSol, InstanceRNG, seed, InstanceParameters)

% Inputs:
% a) NumStartingSol: Number of starting solutions, required. Integer, >= 0
% b) InstanceRNG: a random number stream to generate the instance.
% c) seed: The substream of InstanceRNG to use
% d) InstanceParameters: Parameters associated with desired
% instance, a cell. See markdown file for more detail. Cell contains 3
% integers:
%      num_nodes: integer number of nodes desired. If equals 0 then
%                 randomly selected.
%      fwd_arcs: integer number of arcs to generate from each node in the
%                forward pass. 
%      fwd_reach: integer range over which to generate forward arcs.
%  If InstanceParameters is the empty cell then default values are used.
%
% Return structural information on optimization problem
%   a) minmax: -1 to minimize objective, +1 to maximize objective
%   b) d: positive integer giving the dimension d of the domain
%   c) m: nonnegative integer giving the number of constraints. All
%        constraints must be inequality constraints of the form LHS >= 0.
%        If problem is unconstrained (beyond variable bounds) then should be 0.
%   d) VarNature: a d-dimensional column vector indicating the nature of
%        each variable - real (0), integer (1), or categorical (2).
%   e) VarBds: A d-by-2 matrix, the ith row of which gives lower and
%        upper bounds on the ith variable, which can be -inf, +inf or any
%        real number for real or integer variables. Categorical variables
%        are assumed to take integer values including the lower and upper
%        bound endpoints. Thus, for 3 categories, the lower and upper
%        bounds could be 1,3 or 2, 4, etc.
%   f) FnGradAvail: Equals 1 if gradient of function values are
%        available, and 0 otherwise.
%   g) NumConstraintGradAvail: Gives the number of constraints for which
%        gradients of the LHS values are available. If positive, then those
%        constraints come first in the vector of constraints.
%   h) StartingSol: One starting solution in each row, or NaN if NumStartingSol=0.
%        Solutions generated as per problem writeup
%   i) budget: maximum budget, or NaN if none suggested
%   j) ObjBd is a bound (upper bound for maximization problems, lower
%        bound for minimization problems) on the optimal solution value, or
%        NaN if no such bound is known.
%   k) OptimalSol is a d dimensional column vector giving an optimal
%        solution if known, and it equals NaN if no optimal solution is known.
%   l) NumRngs: the number of random number streams needed by the
%        simulation model
%   m) ProblemInstance: a cell containing the problem
%      instance. Cell includes
%      num_nodes: an integer
%      num_arcs: an integer
%      arcs: a (num_arcs by 2) matrix of arcs, containing the
%      indices  of the "from" and "to" nodes
%

%   *************************************************************
%   ***            Adapted from SAN by Shane Henderson        ***
%   ***            sgh9@cornell.edu    March 12, 2020         ***
%   *************************************************************


minmax = -1; % minimize

RandStream.setGlobalStream(InstanceRNG);
InstanceRNG.Substream = seed;

if isempty(InstanceParameters) % i.e., if InstanceParameters={}
    min_nodes=10;
    max_nodes=70;
    numnodes = randi([min_nodes max_nodes], 1, 1); %uniformly distributed on {min_nodes ... max_nodes}
    fwd_arcs = 3; % Typical number of forward arcs from each node. Typically one more than this due to connectiveness loop
    fwd_reach = 12; % Maximum distance forward for any arc from current node
else
    CellSize = size(InstanceParameters);
    if (CellSize(1) ~= 1) || (CellSize(2) ~= 3)
      fprintf('Input parameter cell to SANRND should be empty or a cell of 3 integers. \n');
      return;
    end
    numnodes = InstanceParameters{1}; % Reasonable value is 50
    fwd_arcs = InstanceParameters{2}; % Reasonable value is  3
    fwd_reach = InstanceParameters{3}; % Reasonable value is 12
end
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
ProblemInstance = {numnodes, numarcs, arcs};

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
%ProblemInstance = {numnodes, numarcs, arcs};
%numnodes
%numarcs
%arcs

d = numarcs; % number of arcs
m = 0; % Just bounds on thetas. No additional constraints beyond box constraints
VarNature = zeros(d, 1); % real variables
VarBds = [ones(d,1) * 0.01, ones(d,1) * 100]; % theta is bounded between .01 and 100
FnGradAvail = 1; % IPA derivative is coded
NumConstraintGradAvail = 0; % No constraint gradients
budget = 100000;
ObjBd = NaN;
OptimalSol = NaN;
NumRngs = 1;

if (NumStartingSol < 0) || (NumStartingSol ~= round(NumStartingSol))
    fprintf('NumStartingSol should be integer >= 0. \n');
    StartingSol = NaN;
else
    if (NumStartingSol == 0)
        StartingSol = NaN;
    else
        % Matlab fills random matrices by column, thus the transpose
        StartingSol = 0.5 + 4.5 * rand(d, NumStartingSol)';
    end    
end
