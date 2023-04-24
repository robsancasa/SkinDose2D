function tt = TableTransmision(kV, prim_ang, sec_ang,...
    filtr1m, filtr1th, filtr2m, filtr2th);
% kV = 120
% prim_ang = 0
% sec_ang = 0
% filtr1m = 'al'
% filtr1th = 0.4
% filtr2m = 'Copper or Copper compound'
% filtr2th = 0.9

%% Clasificamos filtración
% Baja filtración 0 mm Cu
% Media filtración < 0.3 mm Cu
% Alta filtración >= 0.3 mm Cu y <=0.5 mm Cu
% Muy alta filtración > 0.5 mm Cu

% En caso de que no haya información sobre la filtración se toma el caso
% más desfavorable de alta filtración.
cobre = 0;
filtracion = 'baja filtracion';

if (strcmp(filtr1m,'Copper or Copper compound') == 1 ||...
        strcmp(filtr2m,'Copper or Copper compound') == 1)
    cobre=1;
    if strcmp(filtr1m,'Copper or Copper compound') == 1
        espesor = filtr1th;
    else
        espesor = filtr2th;
    end
end
if cobre == 1 
    if espesor < 0.3
        filtracion = 'media filtracion';
    elseif espesor >= 0.3 && espesor <= 0.5
        filtracion = 'alta filtracion';
    else
        filtracion = 'muy alta filtracion';
    end
end

%% Corrección por el ángulo de incidencia
pxy = [0;0;-1]; %Normal del plano xy
%matriz de rotaciones respecto eje x
Rx = [1 0 0;0 cos(-sec_ang*pi/180) -sin(-sec_ang*pi/180);...
    0 sin(-sec_ang*pi/180) cos(-sec_ang*pi/180)];

%matriz de rotaciones respecto eje y
Ry = [cos(-prim_ang*pi/180) 0 sin(-prim_ang*pi/180);0 1 0;...
    -sin(-prim_ang*pi/180) 0 cos(-prim_ang*pi/180)];
pd = Rx*Ry*pxy; %Vector rotado
% angulo entre el eje del haz y el plano xy
alfa = 180/pi*acos(dot(pxy,pd));

% Factor de corrección por el ángulo
if alfa < 90
    f_ang = -7.436e-05 * alfa^2 + 2.687e-05 * alfa + 0.9986;
else
    f_ang = 1.0;
end

%% Corrección por el kilovoltaje
switch filtracion
    case 'baja filtracion'
        f_kV = -2.705e-05 * kV^2 + 6.542e-03 * kV + 3.908e-01;
    case 'media filtracion'
        f_kV = -1.325e-05 * kV^2 + 3.261e-03 * kV + 6.084e-01;
    case 'alta filtracion'
        f_kV = -1.795e-05 * kV^2 + 4.018e-03 * kV + 6.409e-01;
    otherwise
        f_kV = -3.010e-05 * kV^2 + 6.816e-03 * kV + 5.079e-01;
end

%% Cálculo final de la transmisión de la mesa
tt = f_ang * f_kV;
end