fig2 = open([pwd '\MATfig\JV (Ionic).fig']);
fig1 = open([pwd '\MATfig\JV (Electronic).fig']);
ax1 = get(fig1, 'Children');
ax2 = get(fig2, 'Children');
ax2Children = get(ax2(i),'Children');
ax2Children.Color = [1 0 0];
copyobj(ax2Children, ax1(i));
legend('J_{electronic}', 'J_{ionic}')
saveas(fig1, 'JV', 'png')
saveas(fig1, [pwd '\MATfig\JV.fig'], 'fig')