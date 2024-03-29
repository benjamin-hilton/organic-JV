function solstruct = pindrift(varargin);

%%%%%%% REQUIREMENTS %%%%%%%%%%%%
% Requires v2struct toolbox for unpacking parameters structure
% IMPORTANT! Currently uses parameters from pinParams
% ALL VARIABLES MUST BE DECLARED BEFORE UNPACKING STRUCTURE (see below)
% spatial mesh is generated by meshgen_x
% time mesh is generated by meshgen_t

%%%%%%% GENERAL NOTES %%%%%%%%%%%%
% A routine to test solving the diffusion and drift equations using the
% matlab pdepe solver. 
% 
% The solution from the solver is a 3D matrix, u:
% rows = time
% columns = space
% u(1), page 1 = electron density, n
% u(2), page 2 = hole density, p
% u(3), page 3 = mobile defect density, a
% u(4), page 4 = electric potential, V
%
% The solution structure solstruct contains the solution in addition to
% other useful outputs including the parameters sturcture

%%%%% INPUTS ARGUMENTS %%%%%%%
% This version allows a previous solution to be used as the input
% conditions. If there is no input argument asssume default flat background
% condtions. If there is one argument, assume it is the previous solution
% to be used as the initial conditions (IC). If there are two input arguments,
% assume that first is the previous solution, and the
% second is a parameters structure. If the IC sol = 0, default conditions
% are used, but parameters can still be input. If the second argument is
% any character e.g. 'params', then the parameters from the previous solution 
% are used and any changes in the parameters function pinParams are
% ignored.
%  
% AUTHORS
% Piers Barnes last modified (09/01/2016)
% Phil Calado last modified (14/07/2017)

% Graph formatting
set(0,'DefaultLineLinewidth',1);
set(0,'DefaultAxesFontSize',16);
set(0,'DefaultFigurePosition', [300, 100, 900, 600]);
set(0,'DefaultAxesXcolor', [0, 0, 0]);
set(0,'DefaultAxesYcolor', [0, 0, 0]);
set(0,'DefaultAxesZcolor', [0, 0, 0]);
set(0,'DefaultTextColor', [0, 0, 0]);


% Input arguments are dealt with here
if isempty(varargin)

    params = pinParams;      % Calls Function pinParams and stores in sturcture 'params'

elseif length(varargin) == 1
    
    % Call input parameters function
    icsol = varargin{1, 1}.sol;
    icx = varargin{1, 1}.x;
    params = pinParams;

elseif length(varargin) == 2 

    if max(max(max(varargin{1, 1}.sol))) == 0

       params = varargin{2};
    
    elseif isa(varargin{2}, 'char') == 1            % Checks to see if argument is a character
        
        params = varargin{1, 1}.params
        icsol = varargin{1, 1}.sol;
        icx = varargin{1, 1}.x;
    
    else
    
        icsol = varargin{1, 1}.sol;
        icx = varargin{1, 1}.x;
        params = varargin{2};
    
    end

end

% Declare Variables
% The scoping rules for nested and anonymous functions require that all variables
% used within the function be present in the text of the code.
% Rememeber to add new variables here if adding to parameters list- might
% be a better way of doing this.

[BC, EA, Eg, Ei, IP, JV, JVmeasureposition, JVscan_pnts, Jx, N0, NI, PhiW, T, Vapp, Vend,...
    Vstart, calcJ, cmax, cyclic, d, deltax, e, e_points, e_thickness, epp0,...
    eppp, epps, figson, ic_n, ic_p, inter_points, inter_thickness, kB, m, mobset,...
    mobseti, mue_p, mue_s, muh_p, muh_s, muin_p, muin_s, muip_p, muip_s,...
    ni, p_points, p_thickness, q, snapshot_pos, surfaces, surflines, t0, tmax, tmesh_type, tpoints,...
    varlist, varstr, x0, xmax, xmesh_type] = deal(0);


% Unpacks params structure for use in current workspace 
v2struct(params);

% Currently have to repack params since values change after unpacking- unsure as to what's happening there
% Pack parameters in to structure 'params'
varcell = who('*')';                    % Store variables names in cell array
varcell = ['fieldnames', varcell];      % adhere to syntax for v2struct

params = v2struct(varcell);

%%%% Spatial mesh %%%%
if length(varargin) == 0 || length(varargin) == 2 && max(max(max(varargin{1, 1}.sol))) == 0
    
    % Edit meshes in mesh gen
    x = meshgen_x(params);
        
    icx = x;
    
else
          
        x = icx;

end

xpoints = length(x);
xmax = x(end);
xnm = x*1e7;        

%%%%%% Time mesh %%%%%%%%%
t = meshgen_t(params);

% Graph options
if surflines == 0
    set(0, 'DefaultSurfaceEdgeColor',  'none');
end

% SOLVER OPTIONS  - limit maximum time step size during integration.
options = odeset('MaxOrder',5, 'NonNegative', [1, 1, 1, 0]);

% Call solver - inputs with '@' are function handles to the subfunctions
% below for the: equation, initial conditions, boundary conditions
sol = pdepe(m,@pdex4pde,@pdex4ic,@pdex4bc,x,t,options);

% --------------------------------------------------------------------------
% Set up partial differential equation (pdepe) (see MATLAB pdepe help for details of c, f, and s)
function [c,f,s,iterations] = pdex4pde(x,t,u,DuDx)

% Prefactors set to 1 for time dependent components - can add other
% functions if you want to include the multiple trapping model
c = [1;
     1;
     1;
     1;
     0;];

f = [(mue_p*(u(1)*(-DuDx(5))*(1-(u(1)/N0))+kB*T*DuDx(1)));       % Current terms for electrons
     (muh_p*(u(2)*DuDx(5)*(1-(u(2)/N0))+kB*T*DuDx(2)));          % Current terms for holes
     (muip_p*(u(3)*DuDx(5)+kB*T*(DuDx(3)+((u(3)*(DuDx(3)+DuDx(4)))/(cmax - u(4) - u(3))))));         % Current terms for +ve ions
     (muin_p*(u(4)*(-DuDx(5))+kB*T*(DuDx(4)+((u(4)*(DuDx(3)+DuDx(4)))/(cmax - u(4) - u(3))))));      % Current terms for -ve ions
     DuDx(5);];                                   % Electric field

s = [0;
     0;
     0;
     0;
     (q/eppp)*(-u(1)+u(2)+u(3)-u(4));]; 
 
end

% --------------------------------------------------------------------------

% Define initial conditions.
function u0 = pdex4ic(x)

if length(varargin) == 0 || length(varargin) >= 1 && max(max(max(varargin{1, 1}.sol))) == 0
    
    u0 = [ic_n;
          ic_p;
          NI;
          NI;
          0;];
     
elseif length(varargin) == 1 || length(varargin) >= 1 && max(max(max(varargin{1, 1}.sol))) ~= 0
    % insert previous solution and interpolate the x points
    u0 = [interp1(icx,icsol(end,:,1),x);
          interp1(icx,icsol(end,:,2),x);
          interp1(icx,icsol(end,:,3),x);
          interp1(icx,icsol(end,:,4),x);
          interp1(icx,icsol(end,:,5),x);];

end

end

% --------------------------------------------------------------------------

% Define boundary condtions, refer pdepe help for the precise meaning of p
% and you l and r refer to left and right.
% in this example I am controlling the flux through the boundaries using
% the difference in concentration from equilibrium and the extraction
% coefficient.
function [pl,ql,pr,qr] = pdex4bc(xl,ul,xr,ur,t)

if JV == 1;
        
    if cyclic == 1;
    
        if t <= tmax/2;

            Vapp = Vstart + ((Vend-Vstart)*t*(2/tmax))

        else

            Vapp = Vend - ((Vend-Vstart)*(t - tmax/2)*(2/tmax))

        end

    else
        
        Vapp = Vstart + ((Vend-Vstart)*t*(1/tmax))
        
    end
        
end

pl = [ul(1) - N0/(exp(-(PhiW - EA)/(kB*T))+1); %(d^2/eppp)*(ul(4) - ul(3)
      ul(2) - N0/(exp(-(IP - PhiW)/(kB*T))+1); 
      0;
      0;
      ul(5) - Vapp;];

ql = [0;
      0;
      1;
      1;
      0;];
  
pr = [0;
      0;
      ur(3) - NI;
      ur(4) - NI;
      ur(5);];  
  
qr = [1;
      1;
      0;
      0;
      0;];

end


disp('Simulation completed.')

%%%%% Analysis %%%%%

% split the solution into its component parts (e.g. electrons, holes and efield)
n = sol(:,:,1);             % Electrons
p = sol(:,:,2);             % Holes
c = sol(:,:,3);             % Cations
a = sol(:,:,4);             % Anions
V = sol(:,:,5);             % Potential

% Calculate energy levels and chemical potential         
V = V - EA;                                % Electric potential
Ecb = EA-V-EA;                             % Conduction band potential
Evb = IP-V-EA;                             % Valence band potential
En = real(Ecb - kB*T*log((N0./n)-1));      % Electron Fermi Level 
Ep = real(Evb + kB*T*log((N0./p)-1));      % Hole Fermi Level


rhoc = (-n + p + c - a);     % Net charge density calculated from adding individual charge densities

for i=1:length(t)

    Fp(i,:) = -gradient(V(i, :), x);       % Electric field calculated from V

end

Potp = V(end, :);

rhoctot = trapz(x, rhoc, 2)/xmax;   % Net charge

rho_a = c - a;                  % Net ionic charge
rho_a_tot = trapz(x, rho_a, 2)/xmax;   % Total Net ion charge

ntot = trapz(x, n, 2);     % Total 
ptot = trapz(x, p, 2);

if JV == 1
    
    if cyclic == 1;
    
        Vapp_arr1 = Vstart + ((Vend-Vstart)*t(1:tpoints/2)*(2/tmax));
        Vapp_arr2 = Vend - ((Vend-Vstart)*(t((tpoints/2)+1:tpoints) - tmax/2)*(2/tmax));
        Vapp_arr = [Vapp_arr1 Vapp_arr2];
        
    else
        
        Vapp_arr = Vstart + ((Vend-Vstart)*t*(1/tmax));
        
    end
    
end

% Calculates currents for all x points at all times
if calcJ == 1
    
    Jndiff = [];
    Jndrift = [];
    Jpdiff = [];
    Jpdrift= [];
    Jadiff = [];
    Jadrift= [];
    Jcdiff = [];
    Jcdrift= [];
    Floct = [];
    Vloct = [];
    
    for j=1:length(t)

        [nloc,dnlocdx] = pdeval(0,x,n(j,:),x(1: end - 0));    
        [ploc,dplocdx] = pdeval(0,x,p(j,:),x(1: end - 0));
        [aloc,dalocdx] = pdeval(0,x,a(j,:),x(1: end - 0));
        [cloc,dclocdx] = pdeval(0,x,c(j,:),x(1: end - 0));
        [Vloc, Floc] = pdeval(0,x,V(j,:),x(1: end - 0));

        % Particle currents
        Jndiff = [Jndiff; (mue_p*kB*T*dnlocdx)*(1000*e)];
        Jndrift = [Jndrift; (-mue_p*nloc.*Floc.*(1-nloc./N0))*(1000*e)];

        Jpdiff = [Jpdiff; (-muh_p*kB*T*dplocdx)*(1000*e)];
        Jpdrift = [Jpdrift; (-muh_p*ploc.*Floc.*(1-nloc./N0))*(1000*e)];

        Jadiff = [Jadiff; (muip_p*kB*T*(dalocdx + ((aloc.*(dalocdx + dclocdx))./(cmax - aloc - cloc))))*(1000*e)];
        Jadrift = [Jadrift; (-muip_p*aloc.*Floc)*(1000*e)];

        Jcdiff = [Jcdiff; (-muin_p*kB*T*(dclocdx + ((cloc.*(dalocdx + dclocdx))./(cmax - aloc - cloc))))*(1000*e)];
        Jcdrift = [Jcdrift; (-muin_p*cloc.*Floc)*(1000*e)];

        % Electric Field
        Floct = [Floct; - Floc];
        Vloct = [Vloct; Vloc];

     end

    % Currents
    Jpartsurf = Jndiff + Jndrift + Jpdiff + Jpdrift + Jadiff + Jadrift + Jcdiff + Jcdrift;
    Jndiffsurf = Jndiff;
    Jndriftsurf = Jndrift;
    Jntotsurf = (Jndiff + Jndrift);
    Jpdiffsurf = Jpdiff;
    Jpdriftsurf = Jpdrift;
    Jptotsurf = (Jpdiff + Jpdrift);
    Jadiffsurf = Jadiff;
    Jadriftsurf = Jadrift;
    Jatotsurf = (Jadiff + Jadrift);
    Jcdiffsurf = Jcdiff;
    Jcdriftsurf = Jcdrift;
    Jctotsurf = (Jcdiff + Jcdrift);

    %Jpartr = -(sn*n(:, end) - ni) %Check when surface recombination is used

    % Displacement Current at left hand side

    %Jdispsurf = (e*1000)*eppp*gradient(Floct, t);

    Jtotsurf = Jpartsurf; %+ Jdispsurf;   
    
end

% Calculates mean currents for points specified at JVmeasureposition all times
if calcJ == 1 || calcJ == 2
    
    % find the internal current density in the device
    Jndiff = zeros(1, length(t));
    Jndrift = zeros(1, length(t));
    Jpdiff = zeros(1, length(t));
    Jpdrift= zeros(1, length(t));
    Jadiff = zeros(1, length(t));
    Jadrift= zeros(1, length(t));
    Jcdiff = zeros(1, length(t));
    Jcdrift= zeros(1, length(t));
    Jpart = zeros(1, length(t));

        for j=1:length(t)

            [nloc,dnlocdx] = pdeval(0,x,n(j,:),x(JVmeasureposition));    
            [ploc,dplocdx] = pdeval(0,x,p(j,:),x(JVmeasureposition));
            [aloc,dalocdx] = pdeval(0,x,a(j,:),x(JVmeasureposition));
            [cloc,dclocdx] = pdeval(0,x,c(j,:),x(JVmeasureposition));
            [Vloc, Floc] = pdeval(0,x,V(j,:),x(JVmeasureposition));

            % Particle currents
            Jndiff(j) = mean((mue_p*kB*T*dnlocdx)*(1000*e));
            Jndrift(j) = mean((-mue_p*nloc.*Floc.*(1-nloc./N0))*(1000*e));
    
            Jpdiff(j) = mean((-muh_p*kB*T*dplocdx)*(1000*e));
            Jpdrift(j) = mean((-muh_p*ploc.*Floc.*(1-nloc./N0))*(1000*e));

            Jadiff(j) = mean((muip_p*kB*T*(dalocdx + ((aloc.*(dalocdx + dclocdx))./(cmax - aloc - cloc))))*(1000*e));
            Jadrift(j) = mean((-muip_p*aloc.*Floc)*(1000*e));

            Jcdiff(j) = mean((-muin_p*kB*T*(dclocdx + ((cloc.*(dalocdx + dclocdx))./(cmax - aloc - cloc))))*(1000*e));
            Jcdrift(j) = mean((-muin_p*cloc.*Floc)*(1000*e));


            % Electric Field
            Floctr(j) = mean(Floc);

        end

    % Currents at the left boundary
    Jpartr = Jndiff + Jndrift + Jpdiff + Jpdrift + Jadiff + Jadrift + Jcdiff + Jcdrift;
    Jndiffr = Jndiff;
    Jndriftr = Jndrift;
    Jntotr = (Jndiff + Jndrift);
    Jpdiffr = Jpdiff;
    Jpdriftr = Jpdrift;
    Jptotr = (Jpdiff + Jpdrift);
    Jadiffr = Jadiff;
    Jadriftr = Jadrift;
    Jatotr = (Jadiff + Jadrift);
    Jcdiffr = Jcdiff;
    Jcdriftr = Jcdrift;
    Jctotr = (Jcdiff + Jcdrift);

    %Jpartr = -(sn*n(:, end) - ni) %Check when surface recombination is used

    % Displacement Current at left hand side

    Jdispr = (e*1000)*eppp*gradient(Floctr, t);

    Jtotr = Jpartr + Jdispr;     

end

function rho = loc(xval, x_arr, type, time)
    [rho, ~] = pdeval(0,x_arr,type(time,:),xval);
end

if calcJ == 1 || calcJ == 3
       
    N = zeros(1, length(t));
    P = zeros(1, length(t));
    A = zeros(1, length(t));
    C = zeros(1, length(t));
    
    spacing = tmax/tpoints;
   
    for j=1:length(t)
        
        %{
        nloc = @(xval)loc(xval, x, n, j);
        iloc = @(xval)loc(xval, x, c, a, j);
        
        N(j) = integral(nloc, x(1), x(end));
        I(j) = integral(iloc, x(1), x(end));
        %}
        
        nloc = @(xval)loc(xval, x, n, j);
        ploc = @(xval)loc(xval, x, p, j);
        aloc = @(xval)loc(xval, x, a, j);
        cloc = @(xval)loc(xval, x, c, j);

        % Particle numbers
        
        N(j) = integral(nloc, x(1), x(end));
        P(j) = integral(ploc, x(1), x(end));
        A(j) = -integral(aloc, x(1), x(end)); %negative sign as entering on rhs
        C(j) = -integral(cloc, x(1), x(end));
        
        
     end

    % Currents
    
    
    Jn = gradient(N, spacing).*e*1000;
    Jp = gradient(P, spacing).*e*1000;
    Ja = -gradient(A, spacing).*e*1000;
    Jc = gradient(C, spacing).*e*1000;
    
    Jelec = gradient(P-N, spacing).*e*1000;
    Jion = gradient(C-A, spacing).*e*1000;
    Jtot = Jelec + Jion;
    
end

disp('Analysis completed.')

%%%%% GRAPHING %%%%%%%%

%Figures
if figson == 1;

% Defines end points for the graphing
xnmend = xnm(end);

for time = snapshot_pos

    figure('Name',['Band Diagram (t = ' num2str((time/tpoints)*tmax) ' s)'],'NumberTitle','off')
    title(['t = ' num2str((time/tpoints)*tmax) ' s'])
    
    % Band Diagram
    %set(FigHandle, 'units','normalized','position',[.1 .1 .4 .4]);
    plot (xnm, En(time,:), '--', xnm, Ep(time,:), '--', xnm, Ecb(time, :), xnm, Evb(time ,:));
    legend('E_{fn}', 'E_{fp}', 'Conduction Band', 'Valence Band');
    set(legend,'FontSize',12);
    %xlabel('Position [nm]');
    ylabel('Energy [eV]'); 
    set(legend,'FontSize',12);
    set(legend,'EdgeColor',[1 1 1]);
    grid off;

    % Electron / Cation Charge Densities
    figure('Name',['Electron and Cation Charge Densities (t = ' num2str((time/tpoints)*tmax) ' s)'],'NumberTitle','off')
    title(['t = ' num2str((time/tpoints)*tmax) ' s'])
    semilogy(xnm, n(time,:), xnm, c(time,:));
    ylabel('{\itn, \itc} [cm^{-3}]')
    legend('\itn', '\itc')
    %xlabel('Position [nm]')
    set(legend,'FontSize',12);
    set(legend,'EdgeColor',[1 1 1]);
    grid off

    % Hole / Anion Charge Densities
    figure('Name',['Hole and Anion Charge Densities (t = ' num2str((time/tpoints)*tmax) ' s)'],'NumberTitle','off')
    title(['t = ' num2str((time/tpoints)*tmax) ' s'])
    semilogy(xnm, p(time,:), xnm, a(time,:));
    ylabel('{\itp, \ita} [cm^{-3}]')
    xlabel('Position [nm]')
    legend('\itp', '\ita')
    set(legend,'FontSize',12);
    set(legend,'EdgeColor',[1 1 1]);
    grid off
    
    % Net charge
    figure('Name',['Net Charge Density (t = ' num2str((time/tpoints)*tmax) ' s)'], 'NumberTitle','off')
    title(['t = ' num2str((time/tpoints)*tmax) ' s'])
    ylabel('Net Charge Density [cm^{-3}]')
    xlabel('Position [nm]')
    semilogy(xnm, rho_a(time,:))
    grid off

end

if surfaces == 1

    figure('Name','Electron Density', 'NumberTitle','off')
    s2 = surf(x,t,n);
    set(gca, 'ZScale', 'log');
    zlabel('Electron Density [cm^{-3}]');
    xlabel('Distance [cm]');
    ylabel('Time [s]');

    figure('Name','Hole Density', 'NumberTitle','off')
    surf(x,t,p);
    set(gca, 'ZScale', 'log');
    zlabel('Hole Density [cm^{-3}]');
    xlabel('Distance [cm]');
    ylabel('Time [s]');

    figure('Name','Anion Density', 'NumberTitle','off')
    surf(x,t,a);
    zlabel('Anion Density [cm^{-3}]');
    xlabel('Distance [cm]');
    ylabel('Time [s]');

    figure('Name','Cation Density', 'NumberTitle','off')
    surf(x,t,c);
    zlabel('Cation Density [cm^{-3}]');
    xlabel('Distance [cm]');
    ylabel('Time [s]');

    figure('Name','Net Charge Density', 'NumberTitle','off')
    surf(x,t,p - n + c - a);
    zlabel('Net Charge Density [cm^{-3}]');
    xlabel('Distance [cm]');
    ylabel('Time [s]');

    figure('Name','Net Ionic Density', 'NumberTitle','off')
    surf(x,t,rho_a);
    zlabel('Net Ionic Charge Density [cm^{-3}]');
    xlabel('Distance [cm]');
    ylabel('Time [s]');
    
end   


if calcJ == 1

    if surfaces == 1
    
        figure('Name','Particle Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jtotsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Particle Current Density [mA cm^{-2}]');

        figure('Name','Electron Diffusion Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jndiffsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Electron Diffusion Current Density [mA cm^{-2}]');

        figure('Name','Electron Drift Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jndriftsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Electron Drift Current Density [mA cm^{-2}]');

        figure('Name','Total Electron Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jntotsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Total Electron Current Density [mA cm^{-2}]');

        figure('Name','Hole Diffusion Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jpdiffsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Hole Diffusion Current Density [mA cm^{-2}]');

        figure('Name','Hole Drift Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jpdriftsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Hole Drift Current Density [mA cm^{-2}]');

        figure('Name','Total Hole Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jptotsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Total Hole Current Density [mA cm^{-2}]');

        figure('Name','Anion Diffusion Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jadiffsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Anion Diffusion Current Density [mA cm^{-2}]');

        figure('Name','Anion Drift Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jadriftsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Anion Drift Current Density [mA cm^{-2}]');

        figure('Name','Total Anion Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jatotsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Total Anion Current Density [mA cm^{-2}]');

        figure('Name','Cation Diffusion Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jcdiffsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Cation Diffusion Current Density [mA cm^{-2}]');

        figure('Name','Cation Drift Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jcdriftsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Cation Drift Current Density [mA cm^{-2}]');

        figure('Name','Total Cation Current Density Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Jctotsurf)
        xlabel('Position [cm]');
        ylabel('Time [s]')
        zlabel('Total Cation Current Density [mA cm^{-2}]');

        figure('Name','Electric Field Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Floct);
        xlabel('Position [cm]');
        ylabel('Time [s]');
        zlabel('Field [V cm^{-1}]');

        figure('Name','Potential Surface', 'NumberTitle','off')
        surf(x(1: end - 0), t, Vloct);
        xlabel('Position [cm]');
        ylabel('Time [s]');
        zlabel('Potential [V]');

        drawnow;
    
    end
        
    if Jx == 1
        
        figure('Name',['J-X Total Particle (t = ' num2str((round(tpoints/2)/tpoints)*tmax) ' s)'], 'NumberTitle','off')
        plot(x, Jpartsurf(round(tpoints/2),:));
        xlabel('Position [cm]');
        ylabel('J_{particle} [mA cm^{-3}]');

        % Drift and diffusion currents for each particle as a function of time
        figure('Name',['J-X Electron (t = ' num2str((round(tpoints/2)/tpoints)*tmax) ' s)'], 'NumberTitle','off')
        plot(x, Jndiffsurf(round(tpoints/2),:), 'b', x, Jndriftsurf(round(tpoints/2),:), 'g', x, Jntotsurf(round(tpoints/2),:), 'r');
        legend('J_{diff}', 'J_{drift}', 'J_{tot}');
        xlabel('Position [cm]');
        ylabel('Electron Current Density [mA cm^{-2}]');
        drawnow;

        figure('Name',['J-X Hole (t = ' num2str((round(tpoints/2)/tpoints)*tmax) ' s)'], 'NumberTitle','off')
        plot(x, Jpdiffsurf(round(tpoints/2),:), 'b', x, Jpdriftsurf(round(tpoints/2),:), 'g', x, Jptotsurf(round(tpoints/2),:), 'r');
        legend('J_{diff}', 'J_{drift}', 'J_{tot}');
        xlabel('Position [cm]');
        ylabel('Hole Current Density [mA cm^{-2}]');
        drawnow;

        figure('Name',['J-X Anion (t = ' num2str((round(tpoints/2)/tpoints)*tmax) ' s)'], 'NumberTitle','off')
        plot(x, Jadiffsurf(round(tpoints/2),:), 'b', x, Jadriftsurf(round(tpoints/2),:), 'g', x, Jatotsurf(round(tpoints/2),:), 'r');
        legend('J_{diff}', 'J_{drift}', 'J_{tot}');
        xlabel('Position [cm]');
        ylabel('Anion Current Density [mA cm^{-2}]');
        drawnow;

        figure('Name',['J-X Cation (t = ' num2str((round(tpoints/2)/tpoints)*tmax) ' s)'], 'NumberTitle','off')
        plot(x, Jcdiffsurf(round(tpoints/2),:), 'b', x, Jcdriftsurf(round(tpoints/2),:), 'g', x, Jctotsurf(round(tpoints/2),:), 'r');
        legend('J_{diff}', 'J_{drift}', 'J_{tot}');
        xlabel('Position [cm]');
        ylabel('Cation Current Density [mA cm^{-2}]');
        drawnow;
        
    end

end

if calcJ == 1 || calcJ == 2

if xmesh_type == 1
    position_str = (JVmeasureposition/p_points)*xmax;
elseif xmesh_type == 2
    if JVmeasureposition < p_points
        position_str = (JVmeasureposition/p_points) * (p_thickness-inter_thickness);
    else
        position_str = (p_thickness-inter_thickness) + ((JVmeasureposition-p_points)/inter_points)*(inter_thickness);
    end
else
    if JVmeasureposition <= e_points
        position_str = (JVmeasureposition/e_points)*e_thickness;
    elseif JVmeasureposition <= p_points
        position_str = (e_thickness) + ((JVmeasureposition-e_points)/p_points)*(p_thickness);
    else
        position_str = (p_thickness-inter_thickness) + ((JVmeasureposition-p_points-e_points)/inter_points)*(inter_thickness);
    end
end

position_str = num2str(position_str);

% Particle and displacement currents as a function of time
figure('Name',['Current Density (x = ' position_str ' cm)'], 'NumberTitle','off')
plot(t, Jtotr, t, Jpartr, t, Jdispr);
legend('J_{total}', 'J_{particle}', 'J_{displacement}')
xlabel('time [s]');
ylabel('J [mA cm^{-2}]');
set(legend,'FontSize',16);
set(legend,'EdgeColor',[1 1 1]);
grid off;
drawnow;

figure('Name',['Particle Current Density (x = ' position_str ' cm)'], 'NumberTitle','off')
xlabel('Time [s]');
ylabel('J [mA cm^{-3}]');

% Drift and diffusion currents for each particle as a function of time
figure('Name',['Electron Current Density at ' position_str ' cm'], 'NumberTitle','off')
plot(t, Jndiffr, 'b', t, Jndriftr, 'g', t, Jntotr, 'r');
legend('J_{diff}', 'J_{drift}', 'J_{tot}');
xlabel('Time [s]');
ylabel('Electron Current Density [mA cm^{-2}]');
drawnow;

figure('Name',['Hole Current Density at ' position_str ' cm'], 'NumberTitle','off')
plot(t, Jpdiffr, 'b', t, Jpdriftr, 'g', t, Jptotr, 'r');
legend('J_{diff}', 'J_{drift}', 'J_{tot}');
xlabel('Time [s]');
ylabel('Hole Current Density [mA cm^{-2}]');
drawnow;

figure('Name',['Anion Current Density at ' position_str ' cm'], 'NumberTitle','off')
plot(t, Jadiffr, 'b', t, Jadriftr, 'g', t, Jatotr, 'r');
legend('J_{diff}', 'J_{drift}', 'J_{tot}');
xlabel('Time [s]');
ylabel('Anion Current density [mA cm^{-2}]');
drawnow;

figure('Name',['Cation Current Density at ' position_str ' cm'], 'NumberTitle','off')
plot(t, Jcdiffr, 'b', t, Jcdriftr, 'g', t, Jctotr, 'r');
legend('J_{diff}', 'J_{drift}', 'J_{tot}');
xlabel('Time [s]');
ylabel('Cation Current density [mA cm^{-2}]');
drawnow;


    if JV == 1
        figure('Name',['JV at ' position_str ' cm'], 'NumberTitle','off')
        plot(Vapp_arr, Jtotr)
        xlabel('V_{app} [V]')
        ylabel('Current Density [mA cm^{-2}]');
        grid off;
        scan_rate = 2*Vend/tmax;
        title(['\nu = ' num2str(scan_rate) 'V s^{-1}'])
        drawnow;
    end

end

if calcJ == 3 || calcJ == 1
    
    
    figure('Name','Electronic Ionic Current Densities', 'NumberTitle','off')
    plot(t, Jelec, t, Jion)
    legend('J_{electronic}', 'J_{ionic}')
    xlabel('Time [s]')
    ylabel('Current Density [mA cm^{-2}]')
    
    figure('Name','Electron Hole Current Densities', 'NumberTitle','off')
    plot(t, Jn, t, Jp)
    legend('J_{n}', 'J_{p}')
    xlabel('Time [s]')
    ylabel('Current Density [mA cm^{-2}]')
    
    figure('Name','Anion Cation Current Densities', 'NumberTitle','off')
    plot(t, Ja, t, Jc)
    legend('J_{a}', 'J_{c}')
    xlabel('Time [s]')
    ylabel('Current Density [mA cm^{-2}]')
    
    figure('Name','Particle Current Density', 'NumberTitle','off')
    plot(t, Jtot)
    xlabel('Time [s]')
    ylabel('Particle Current Density [mA cm^{-2}]')
    
    if JV == 1
        figure('Name','JV (Electronic)', 'NumberTitle','off')
        plot(Vapp_arr, Jelec)
        xlabel('V_{app} [V]')
        ylabel('Electronic Current Density [mA cm^{-2}]')
        scan_rate = 2*Vend/tmax;
        title(['\nu = ' num2str(scan_rate) 'V s^{-1}'])
        
        figure('Name','JV (Ionic)', 'NumberTitle','off')
        plot(Vapp_arr, Jion)
        xlabel('V_{app} [V]')
        ylabel('Ionic Current Density [mA cm^{-2}]')
        title(['\nu = ' num2str(scan_rate) 'V s^{-1}'])
    end
    
end

%{
figure('Name','Barrier Height', 'NumberTitle','off')
barrier_height = (d^2/eppp)*(a(:,1) - c(:,1));
plot(t, barrier_height)
xlabel('Time [s]')
ylabel('Barrier Height [ev]')
%}

drawnow

end


%--------------------------------------------------------------------------------------

% Readout solutions to structure
solstruct.sol = sol; solstruct.n = n(end, :)'; solstruct.p = p(end, :)'; solstruct.a = a(end, :)';...
solstruct.V = V(end, :)'; solstruct.x = x; solstruct.t = t;
solstruct.Ecb = Ecb(end, :)'; solstruct.Evb = Evb(end, :)'; solstruct.Efn = En(end, :)'; solstruct.Efp = Ep(end, :)';...
solstruct.xnm = xnm';

if calcJ == 1 || calcJ == 2

solstruct.Jtotr = Jtotr; solstruct.Jpartr = Jpartr; solstruct.Jdispr = Jdispr;  

end

if length(varargin) == 0 || length(varargin) == 2 && max(max(max(varargin{1, 1}.sol))) == 0
    
    params = rmfield(params, 'params');
    params = rmfield(params, 'varargin');
    
else
    
    params = rmfield(params, 'icsol');
    params = rmfield(params, 'icx');  
    params = rmfield(params, 'params');
    params = rmfield(params, 'varargin');
    
end
% Store params
solstruct.params = params;        
assignin('base', 'sol', solstruct)

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Unused figures

%{
figure(1);
surf(x,t,n);
set(gca, 'ZScale', 'log')
%semilogy(x,n(end,:));
title('n(x,t)');
xlabel('Distance x');
ylabel('time');

figure(2);
surf(x,t,p);
set(gca, 'ZScale', 'log')
title('p(x,t)');
xlabel('Distance x');
ylabel('time');

figure(3);
surf(x,t,a);
title('ion(x,t)');
xlabel('Distance x');
ylabel('time');

figure(11)
plot(xnm, Fc, xnm, Fp);
xlim([0, (xnmend/2)]);
legend('from charge', 'from pot')
ylabel('E Field [V/cm]');
grid off;

% Electric Field vs Position
figure(6);
plot(xnm, Fp(end, :));
xlabel('Position [nm]');
ylabel('Electric Field [Vcm^{-1}]');
grid off;

%}

%{
figure(3)
%set(FigHandle, 'units','normalized','position',[.1 .1 .4 .4]);
[Ax1, h1, h2] = plotyy(xnm, rhoc(end, :), xnm, Urec(end, :));
linkaxes(Ax1,'x');
set(gca,'xlim',[0, (xnmend/2)]);
ylabel(Ax1(1),'Net Charge Density [cm^{-3}]') % left y-axis
ylabel(Ax1(2),{'Recombination';'Rate [cm^{-3}s^{-1}]'}) % right y-axis
%set(Ax1(2),'YScale','log')
set(Ax1(1),'Position', [0.1 0.11 0.7 0.8]);
set(Ax1(2),'Position', [0.1 0.11 0.7 0.8]);
set(Ax1(1),'ycolor',[0.1, 0.1, 0.1]) 
set(Ax1(2),'ycolor',[0, 0.4470, 0.7410])
set(h1,'color',[0.1, 0.1, 0.1])
set(h2, 'color',[0, 0.4470, 0.7410])
grid off;

figure(4)
plot(xnm, g);
grid off

% Electric and Checmial Potential components
figure(4)
%set(FigHandle, 'units','normalized','position',[.1 .1 .4 .4]);
[Ax2, h3, h4] = plotyy(xnm, Potp, xnm, Phi(end,:));
linkaxes(Ax2,'x');
set(gca,'xlim',[0, (xnmend/2)]);
ylabel(Ax2(1),'Electric Potential [V]') % left y-axis
ylabel(Ax2(2),'Chemical Potential [V]') % right y-axis
% get current (active) axes property
set(Ax2(1),'Position', [0.13 0.11 0.775-.08 0.815]);
set(Ax2(2),'Position', [0.13 0.11 0.775-.08 0.815]);
set(Ax2(1),'ycolor',[0.1, 0.1, 0.1]) 
set(Ax2(2),'ycolor',[0.8500, 0.3250, 0.0980])
set(h3,'color',[0.1, 0.1, 0.1])
grid off;



% figure(200)
% [AX,H1,H2] = plotyy(xnm, [Jidiff(end, :).', Jidrift(end, :).'], xnm, (sol(end,:,3)));
% legend('Ion diffusion', 'Ion drift', 'a')
% xlabel('Position [nm]');
% ylabel('Density [cm^{-3}]/Current Density');
% set(AX(2),'Yscale','linear');
% set(legend,'FontSize',20);
% set(legend,'EdgeColor',[1 1 1]);
% set(AX(1), 'Position',[0.18 0.18 0.7 0.70]);     % left, bottom, width, height       
% set(AX(2), 'Position',[0.18 0.18 0.7 0.70]);
% box on
% set(AX(1), 'YMinorTick','on');     % left, bottom, width, height       
% set(AX(2), 'XMinorTick','on','YMinorTick','on');
% set(AX(1),'xlim',[190 250]);
% set(AX(2),'xlim',[190 250]);
% %set(AX(1),'ylim',[1e6 1e18]);
% set(AX(2),'ycolor',[0.9290    0.6940    0.1250]);
% set(H2,'color',[0.9290    0.6940    0.1250]);
% set(legend,'FontSize',12);
% set(legend,'EdgeColor',[1 1 1]);
% grid off;

%}


