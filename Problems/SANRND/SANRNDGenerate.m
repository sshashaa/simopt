function [ProblemInstance] = SANRNDGenerate(InstanceParameters)

% Inputs:
% a) InstanceParameters: Parameters associated with desired
% instance, A cell. See markdown file for more detail. Cell contains 3
% integers:
%      num_nodes: integer number of nodes desired. If equals 0 then
%                 randomly selected.
%      fwd_arcs: integer number of arcs to generate from each node in the
%                forward pass. 
%      fwd_reach: integer range over which to generate forward arcs.
%  If InstanceParameters is the empty cell then default values are used.
%
% Return (possibly random) problem instance
%   a) ProblemInstance: a cell containing the problem
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

if isempty(InstanceParameters) % i.e., if InstanceParameters={}
    
    min_nodes = 10;
    max_nodes = 70;
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