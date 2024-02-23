function new_density_cross_section(sol, times, species)
    % split the solution into its component parts (e.g. electrons, holes and efield)
    n = sol.sol(:,:,1);             % Electrons
    p = sol.sol(:,:,2);             % Holes
    c = sol.sol(:,:,3);             % Cations
    a = sol.sol(:,:,4);             % Anions
    
    rho_a = p - n + c - a;
   
    tpoints = sol.params.tpoints;
    tmax = sol.params.tmax;
    snapshot_pos = round((tpoints/tmax).*times);
    xnm = sol.xnm;
    
    for time = snapshot_pos
        
        if any(species == 'e')
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
        end
        
        if any(species == 'p')
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
        end
        
        if any(species == 'net')
            % Net charge
            figure('Name',['Net Charge Density (t = ' num2str((time/tpoints)*tmax) ' s)'], 'NumberTitle','off')
            title(['t = ' num2str((time/tpoints)*tmax) ' s'])
            ylabel('Net Charge Density [cm^{-3}]')
            xlabel('Position [nm]')
            semilogy(xnm, rho_a(time,:))
            grid off
        end

    end
end