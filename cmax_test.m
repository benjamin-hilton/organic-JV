function cmax_test(cmax_arr, N0_arr)
    p = pinParams;
    for cmax = cmax_arr
        disp(['cmax = ' num2str(cmax,'%e')])
        for N0 = N0_arr
            p.cmax = cmax;
            p.N0 = N0;
            disp(['N0 = ' num2str(N0,'%e')])
            close all
            sol_i_eq = Equilibrate(p);
            sol = pindrift(sol_i_eq,p);
            disp('Saving...')
            savefigures(sol);
            disp('Saving complete')
        end
    end
end
        