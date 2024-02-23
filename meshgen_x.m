function [x] = meshgen_x(params)

v2struct(params);

meshfigon = 1;

% Linearly spaced
if xmesh_type == 1

    x = linspace(0,xmax,p_points);

% Linearly spaced, more points at interfaces   
elseif xmesh_type == 2
   
    x = [linspace(0, p_thickness-inter_thickness, p_points),...
        linspace(p_thickness-inter_thickness+deltax, p_thickness, inter_points)]; 
    
% Linearly spaced, more points at interfaces and electrodes
elseif xmesh_type == 3
   
    x = [linspace(0, e_thickness, e_points),...
        linspace(e_thickness+deltax, p_thickness-inter_thickness, p_points),...
        linspace(p_thickness-inter_thickness+deltax, p_thickness, inter_points)]; 
        
end 

px = length(x);

if meshfigon == 1

    xmir = x;
    pxmir = 1:1:length(x);
    
    figure('Name', 'xmesh', 'NumberTitle', 'off');
    plot(xmir, pxmir, '.');
    xlabel('Position');
    ylabel('Point');

end

end