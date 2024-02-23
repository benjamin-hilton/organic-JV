function Vend_test(V_arr, scan_rate)
    p = pinParams;
    sol_i_eq = Equilibrate(p);
    for V = V_arr
        disp(['V_end = ' num2str(V,'%e')])
        p.Vend = V;
        p.tmax = p.mue_p*((2*V)/(scan_rate*p.mue_p));
        close all
        sol = pindrift(sol_i_eq,p);
        disp('Saving...')
        savefigures(sol);
        disp('Saving complete')
    end
end
        