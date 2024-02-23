function [sol_i_eq] = Equilibrate(varargin)
% Uses analytical initial conditions and runs to equilibrium
% Swicth off mobility and set time to short time step 

sol.sol = 0;

if isempty(varargin)
    p = pinParams;
else
    p = varargin{1};
end

p.tmesh_type = 2;
p.tpoints = 200;

p.JV = 0;
p.Vapp = 0;
p.tmesh_type = 2;
p.tmax = 1e-13;
p.t0 = p.tmax/1e4;
p.figson = 0;
p.calcJ = 0;

p = mobsetfun3(0, 0, p);

% Run with initial solution
sol = pindrift(sol, p);

p = mobsetfun3(1, 0, p);
p.tmax = 1e-13;
p.t0 = p.tmax/1e3;

sol = pindrift(sol, p);

p.tmax = 1e-9;
sol = pindrift(sol, p);

p.tmax = 1e-6;
p.t0 = p.tmax/1e3;

sol = pindrift(sol, p);

p.tmax = 1e-3;
p.t0 = p.tmax/1e3;
p.figson = 0;

sol = pindrift(sol, p);

p.calcJ = 0;
p.tmax = 1;
p.t0 = p.tmax/1e3;

sol_eq = pindrift(sol, p);

p.calcJ = 0;
p.tmax = 100;
p.t0 = 1e-3;
p.figson = 0;

sol_eq = pindrift(sol, p);

assignin('base', 'sol_eq', sol_eq);

%Switch on ion mobility
p.tmax = 1e-9;
p.t0 = p.tmax/1e3;
p.muip_p = 1e-6;
p.muin_p = 1e-6;
p.muip_s = 1e-6;
p.muin_s = 1e-6;

sol = pindrift(sol_eq, p);

p.calcJ = 0;
p.tmax = 1e0;
p.t0 = p.tmax/1e3;

sol = pindrift(sol, p);

p.mue_p = 1e-2;
p.mue_s = 1e-2;
p.muh_p = 1e-2;
p.muh_s = 1e-2;

sol_i_eq = pindrift(sol, p);

assignin('base', 'sol_i_eq', sol_i_eq)

clear symsol
clear sol
clear ssol

end
