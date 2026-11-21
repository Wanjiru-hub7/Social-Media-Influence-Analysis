
% PROJECT 5: SOCIAL MEDIA INFLUENCE ANALYSIS
clear; clc;

%% MAIN PARAMETERS
numUsers = 50;
timeSteps = 12;

% Different scenarios to compare
%Low=0.25, 0.50=Medium, 0.75=High
trustLevels = [0.25 0.50 0.75];      
viralityLevels = [0.25 0.50 0.75];    
networkTypes = {'random', 'clustered'};

numTrust = length(trustLevels);
numVirality = length(viralityLevels);
numNetworks = length(networkTypes);

% Store results
finalReach = zeros(numTrust, numVirality, numNetworks);
saturationSteps = NaN(numTrust, numVirality, numNetworks);
comparisonSpread = zeros(timeSteps, numNetworks);

%% RUN DIFFERENT NETWORK SCENARIOS
for n = 1:numNetworks
networkType = networkTypes{n};

%% CREATE NETWORK STRUCTURE
switch lower(networkType)
case 'random'
    p = 0.15;
    A = rand(numUsers) < p;
    A = triu(A, 1);
    A = A + A';

case 'clustered'
% Two groups with more connections within each group
A = zeros(numUsers);
for i = 1:numUsers
    for j = i+1:numUsers
        if (i <= 25 && j <= 25) || (i > 25 && j > 25)
            if rand() < 0.40
                            A(i,j) = 1;
                end
        else
                  if rand() < 0.03
                    A(i,j) = 1;
                    end
                end
            end
        end
    A = A + A';
end

% Save networks for visualization
if n == 1
    A_random = A;
else
    A_clustered = A;
end

%% TEST DIFFERENT TRUST AND VIRALITY LEVELS
for tr = 1:numTrust
    for v = 1:numVirality
trust = trustLevels(tr);
 virality = viralityLevels(v);

%% INITIALIZE USERS
users = struct();

for i = 1:numUsers
    users(i).ID = i;
    users(i).exposure = 0;
    users(i).shared = 0;
    users(i).trust = trust;
end

% User 1 starts the information spread
users(1).exposure = 1;
users(1).shared = 1;

exposedCount = zeros(1, timeSteps);
cascadeEdges = [];

previousCount = 1;
saturationStep = NaN;

%% INFORMATION SPREAD SIMULATION
for t = 1:timeSteps
    newSharers = zeros(1, numUsers);
    for i = 1:numUsers
        if users(i).shared == 1
            friends = find(A(i,:) == 1);
            for f = friends
                if users(f).exposure == 0

% Friend sees the post
users(f).exposure = 1;

% Record who exposed the friend
cascadeEdges = [cascadeEdges; i, f];

% Decide whether the friend shares it
if rand() < users(f).trust * virality
    newSharers(f) = 1;
end
            end
        end
    end
end

% Activate new sharers for the next round
for i = 1:numUsers
    if newSharers(i) == 1
        users(i).shared = 1;
    end
end

% Count users who have seen the post
exposedCount(t) = sum([users.exposure]);
% Check whether information spread has stopped
if exposedCount(t) == previousCount
    saturationStep = t - 1;
    exposedCount(t:end) = exposedCount(t);
    break;
end
previousCount = exposedCount(t);
end

%% SAVE RESULTS
finalReach(tr,v,n) = exposedCount(end);
saturationSteps(tr,v,n) = saturationStep;

% Save medium trust and medium virality results
if tr == 2 && v == 2
    comparisonSpread(:,n) = exposedCount;
end

% Save one cascade for visualization
if n == 1 && tr == 2 && v == 2
    baselineCascadeEdges = cascadeEdges;
    baselineUsers = users;
end
    end
end
end

%% DISPLAY RESULTS
fprintf('\nSOCIAL MEDIA INFLUENCE ANALYSIS RESULTS\n');

for n = 1:numNetworks
    for tr = 1:numTrust
        for v = 1:numVirality

fprintf('%s | Trust: %.2f | Virality: %.2f | Reach: %d/%d | ', ...
    upper(networkTypes{n}), trustLevels(tr), ...
    viralityLevels(v), finalReach(tr,v,n), numUsers);

if isnan(saturationSteps(tr,v,n))
    fprintf('Saturation: Not reached within %d steps\n', timeSteps);
else
    fprintf('Saturation step: %d\n', saturationSteps(tr,v,n));
end
      end
   end
end

%% PLOT 1: NETWORK STRUCTURES
figure;

subplot(1,2,1);
plot(graph(A_random));
title('Random Network');

subplot(1,2,2);
plot(graph(A_clustered));
title('Clustered Network');


%% PLOT 2: INFORMATION SPREAD
figure;

plot(comparisonSpread(:,1), '-o');
hold on;
plot(comparisonSpread(:,2), '-s');

title('Spread Over Time');
xlabel('Time Step');
ylabel('Exposed Users');
legend('Random', 'Clustered');
grid on;


%% PLOT 3: TRUST AND VIRALITY
figure;

plot(trustLevels, finalReach(:,1,1), '-o');
hold on;
plot(trustLevels, finalReach(:,2,1), '-o');
plot(trustLevels, finalReach(:,3,1), '-o');

plot(trustLevels, finalReach(:,1,2), '--o');
plot(trustLevels, finalReach(:,2,2), '--o');
plot(trustLevels, finalReach(:,3,2), '--o');

title('Impact of Trust and Virality');
xlabel('Trust Level');
ylabel('Final Reach');

legend('Random Low', 'Random Medium', 'Random High', ...
    'Clustered Low', 'Clustered Medium', 'Clustered High');

grid on;


%% PLOT 4: CASCADE MAP
figure;

G = digraph(baselineCascadeEdges(:,1), ...
    baselineCascadeEdges(:,2), [], numUsers);

plot(G, 'Layout', 'layered');
title('Information Cascade');

fprintf('Simulation completed.\n');
