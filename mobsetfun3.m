function [p] = mobsetfun3(mob, mobi, params)

% function to switch on and off mobilities. Execute like this:
% p = mobsetfun(1, params)

% params = pinParams

v2struct(params);

    mue_p = mob;
    muh_p = mue_p;
    mue_s = mue_p;
    muh_s = mue_p;
    
    muip_p = mobi;
    muin_p = mobi;
    muip_s = mobi;
    muin_s = mobi;

clear mob;
clear mobi;
clear params;

% Pack parameters in to structure 'params'
varcell = who('*')';                    % Store variables names in cell array
varcell = ['fieldnames', varcell];      % adhere to syntax for v2struct

p = v2struct(varcell);

end