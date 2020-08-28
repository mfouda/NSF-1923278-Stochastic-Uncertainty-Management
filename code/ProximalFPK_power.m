close all; clear; clc;
%% Parameters

beta = 2; % inverse temperature

% golbal parameters 
global num_Oscillator dim Gamma M Sigma Pmech K

num_Oscillator = 2; dim  = 2*num_Oscillator; % dim = dimension of state space

gamma = rand(num_Oscillator,1); m = rand(num_Oscillator,1); sigma = rand(num_Oscillator,1); pmech = rand(num_Oscillator,1);

Gamma = diag(gamma); M = diag(m); Sigma = diag(sigma); Pmech = diag(pmech); K = rand(num_Oscillator);

% parameters for proximal recursion
nSample = 500;                      % number of samples                                                           
epsilon = .5;                     % regularizing coefficient                                      
h = 1e-3;                           % time step
numSteps= 1000;                     % number of steps k, in discretization t=kh
             
%% propagate joint PDF

% initial mean and covariance
mean0 = rand(1,num_Oscillator); covariance0 = generateRandomSPD(num_Oscillator);
% samples from initial joint PDF 
theta_0 = 2*pi.*rand(nSample,num_Oscillator);

rho_theta_0 = (1/(2*pi))^num_Oscillator;

omega_0 = mvnrnd(mean0, covariance0, nSample);

% joint PDF values at the initial samples
rho_omega_0 = mvnpdf(omega_0, mean0, covariance0);

rho_theta_omega_0 = rho_omega_0.*rho_theta_0;

psi_upper_diag = M/Sigma;

psi_lower_diag = psi_upper_diag;

psi = kron(eye(num_Oscillator),M/Sigma);

xi_0 = wrapTo2Pi((psi_upper_diag*theta_0')');

eta_0 = (psi_lower_diag*omega_0')';

xi_eta_0 = [xi_0,eta_0];


rho_xi_eta_0 = rho_theta_omega_0/det(M/Sigma);

% stores all the updated (states from the governing SDE
xi_eta_upd = zeros(nSample,dim,numSteps+1);

theta_omega_upd = zeros(nSample,dim,numSteps+1);
% sets initial state
xi_eta_upd(:,:,1) = xi_eta_0; 
% stores all the updated joint PDF values
rho_xi_eta_upd = zeros(nSample,numSteps+1);
% sets initial PDF values
rho_xi_eta_upd(:,1) = rho_xi_eta_0/sum(rho_xi_eta_0);

tic
for j=1:numSteps
   
    
   [drift_j,GradU] = PowerDrift(xi_eta_upd(:,1:num_Oscillator,j),xi_eta_upd(:,num_Oscillator+1:dim,j),nSample);
   
    % SDE update for state
    xi_eta_upd(:,:,j+1) = PowerEulerMaruyama(h,xi_eta_upd(:,:,j),drift_j,nSample,num_Oscillator);
    
  
    % proximal update for joint PDF
    [rho_xi_eta_upd(:,j+1),comptime(j),niter(j)] = FixedPointIteration(beta,epsilon,h,rho_xi_eta_upd(:,j),xi_eta_upd(:,:,j),xi_eta_upd(:,:,j+1),PowerFraction(beta,xi_eta_upd(:,num_Oscillator+1:dim,j)),GradU,dim);  
    
end

walltime = toc;


%% Conversion back to theta,omega coordinates 

for jj = 1:numSteps
  
    
    theta_upd(:,:,jj) = wrapTo2Pi((psi_upper_diag\xi_eta_upd(:,1:num_Oscillator,jj)')');
    
    xi_upd(:,:,jj) = (psi_lower_diag\xi_eta_upd(:,num_Oscillator+1:dim,jj)')';
    
    rho_theta_omega_upd(:,jj) = rho_xi_eta_upd(:,jj)*det(M/Sigma);
    
end


%% plots
set(0,'defaulttextinterpreter','latex')
figure(1)
semilogy(comptime, 'LineWidth', 2)
xlabel('Physical time $t=kh$','FontSize',20)
ylabel('Computational time','FontSize',20)



