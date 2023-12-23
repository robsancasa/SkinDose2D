% Medida de dosis en radcal en el plano de cálculo de dosemap
function medida = Radcal(x,y,R,matriz)
% Entrada
%   x, y double. Centro de la radcal
%   R double. Radio de la radcal
    th = linspace(0,2*pi); 
    xc = x+R*cos(th); 
    yc = y+R*sin(th);
    % coordinates candidates at map
    m = 321;
    n = 641;
    resx = 800/(m-1);
    resy = 1600/(n-1);
    xq = -400:resx:400;
    xquer = repmat(xq,n,1);
    yq = (-800:resy:800)';
    yquer = repmat(yq,1,m);
    % get points inside circle 
    idx = inpolygon(xquer,yquer,xc,yc); 
    % GEt mean 
    medida = mean(matriz(idx));
    hold on
    plot(xc,yc)
    disp(medida);