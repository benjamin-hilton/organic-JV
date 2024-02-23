function [t] = meshgen_t(params)

v2struct(params);

meshfigon = 0;

% define solution mesh either logarithmically or linearly spaced points
if tmesh_type == 1

    t = linspace(0,tmax,tpoints);
    %xspace = linspace(0,xmax,p_points+pii+pn);      % Array of point values for optical interp1

elseif tmesh_type == 2
   
    t = logspace(log10(t0),log10(tmax),tpoints) - t0;

end

pt = length(t);

if meshfigon == 1

    tmir = t;
    ptmir = 1:1:length(t);
    
    figure('Name', 'xmesh', 'NumberTitle', 'off');
    plot(tmir, ptmir, '.');
    xlabel('Position');
    ylabel('Time');

end

end