function time = savefigures(sol)
    % Saves all open figures along with the solution in the workspace and
    % current PinParams
    time = datestr(now, 'dd-mmm-yyyy HH.MM.SS');
    mkdir(time);
    h = get(0,'children');
    disp('Saving pngs...')
    for i=1:length(h)
      saveas(h(i), [pwd '\' time '\' get(h(i),'Name') '.png']);
    end
    mkdir(time, 'MATfig')
    disp('Saving MATLAB figs...')
    for i=1:length(h)
      saveas(h(i), [pwd '\' time '\MATfig\' get(h(i),'Name') '.fig'],'fig');
    end
    disp('Saving solution...')
    save([pwd '\' time '\solution.mat'], 'sol');
    disp('Done.')
    