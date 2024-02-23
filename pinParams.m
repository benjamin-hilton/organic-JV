function [params] = pinParams
% Generates parameters structure for pinDrift

% Physical constants
kB = 8.6173324e-5;    % Boltzmann constant [eV K^-1]
T = 300;              % Temperature [K]
epp0 = 552434;        % [e^2 eV^-1 cm^-1] -Checked (02-11-15)
q = 1;                % in e
e = 1.61917e-19;      % Charge of an electron in Coulombs for current calculations

% Device Dimensions [cm]
p_thickness = 200e-7;         % Polymer layer thickness
p_points = 200;             % Polymer layer points
inter_thickness = 30e-7;      % 0.5x Interfacial region thickness (x_mesh_type = 3)
inter_points = 500;         % 0.5x Interfacial points (x_mesh_type = 3)
e_points = 500;           % electrode interface points
e_thickness = 30e-7;          % electrode interface thickness
d = 1e-7;
deltax = inter_thickness/inter_points;    % spacing in the interfacial region- requires for mesh generation

% Parameters for spatial mesh of solution points - see meshgen_x for
% xmesh_type specification
xmesh_type = 3; 
xmax = p_thickness;      % cm

if xmesh_type == 1 || xmesh_type == 5

    x0 = 0;

else
    
    x0 = xmax/1e3;

end

% Parameters for time mesh
tpoints = 500;              % Number of time points
tmesh_type = 1;             % Mesh type- for use with meshgen_t. Must be 1 for calcJ = 3.

% General Parameters
tmax = 1e-3;           % Time limit
Vapp = 0;              % Applied bias
BC = 1;                % Boundary Conditions. Must be set to one for first solution
figson = 1;            % Toggle figures on/off 
calcJ = 3;             % Calculates Currents- slows down solving calcJ = 1, calculates DD currents at every position, calcJ = 2, calculates DD at boundary.
mobset = 1;            % Switch on/off electron hole mobility- MUST BE SET TO ZERO FOR INITIAL SOLUTION
mobseti = 1;           % Switch on/off ion mobility- MUST BE SET TO ZERO FOR INITIAL SOLUTION
JV = 1;                % Linear time mesh, adjusts potential as a function of time
surfaces = 1;          % Switch on/off charge and current density surfaces
surflines = 0;         % Switch on/off contour lines on surfaces (useful for high density plots)
Jx = 1;                % Switch on/off current density against distance plots
snapshot_pos = [1
                round(tpoints/4)
                round(tpoints/2)
                round(3*tpoints/4)
                tpoints]';     % Array of x-points at which to draw band diagram and density cross-sections

t0 = tmax/1e4;


%%%%%%%%%% CURRENT VOLTAGE SCAN %%%%%%%%%%%% - JV on
% NOT 100% reliable- requires further development and investigation1
Vstart = 0;                 % Ensure equals Vapp
Vend = 0.8;
JVscan_pnts = 1000;
JVmeasureposition = 600;    % int or arr - takes mean iff array
cyclic = 1;                 % Creates cyclic scan up to Vend - note doubles scan rate

%%%%%%%%%%% MATERIAL PROPERTIES %%%%%%%%%%%%%%%%%%%%
if mobset == 0
   
    mue_p = 0;     % [Vcm-2s-1] electron mobility
    muh_p = 0;     % hole mobility
    mue_s = 0;
    muh_s = 0;
    
else
    
    mue_p = 1e-4;          % electron mobility
    muh_p = mue_p;      % hole mobility
    mue_s = mue_p;
    muh_s = mue_p;
    
end

if mobseti == 0
        
    muip_p = 0;    % ion mobility
    muin_p = 0;
    muip_s = 0;
    muin_s = 0;
   
else 
        
    muip_p = 1e-8;    % ion mobility
    muin_p = muip_p;
    muip_s = muip_p;
    muin_s = muip_p;
    
end

eppp = 20*epp0;         % Dielectric constant polymer
epps = 20*epp0;         % Dielectric constant solution
cmax = 1e20;     % Maximum ion concentration [cm^-3] ~6M (Volkov et al.)
 
% Energy levels
EA = -2.95;                      % Conduction band energy
IP = -4.6;                       % Valence band energy
PhiW = -4.2;                     % FTO workfunction
Eg = EA-IP;                      % Band Gap

% Effective density of states
N0 = 1e20;                      % effective Density Of States
ic_n = N0/(exp((EA - PhiW - Vstart)/(kB*T)) + 1);
ic_p = N0/(exp((PhiW + Vstart - IP)/(kB*T)) + 1);

%%%%% ION DENSITY %%%%%
NI = 1e18;                      % [cm-3]

% Intrinsic Fermi Energy
Ei = 0.5*((EA+IP)+kB*T*log(N0/N0));

% Charge Densities
ni = N0*(exp(-Eg/(2*kB*T)));          % Intrinsic carrier density

%%%%%%%%%% CURRENT VOLTAGE SCAN %%%%%%%%%%%%
if JV == 1
    
    calcJ = 1;
    tmax = mue_p*((2*Vend)/(0.001*mue_p));           % Scan time determined by mobility- ensures cell is stable at each point
    t0 = 0;
    tmesh_type = 1;
    tpoints = JVscan_pnts;
    
end

% Define geometry of the system (m=0 1D, m=1 cylindrical polar coordinates,
% m=2 spherical polar coordinates).
m = 0;

% Pack parameters in to structure 'params'
varlist = who('*')';
varstr = strjoin(varlist, ',');

varcell = who('*')';                    % Store variables names in cell array
varcell = ['fieldnames', varcell];      % adhere to syntax for v2struct

params = v2struct(varcell);

end