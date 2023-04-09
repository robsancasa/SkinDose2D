function tt = TableTrans(kV, prim_ang, sec_ang);
% Transmision a 80 kV, 0º y sin filtración adicional de Cu
%kV =70
%prim_ang=30
%sec_ang=30
tt = 0.74;
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

f_ang = exp(-3.62e-03*alfa);

%% Corrección por el kilovoltaje
f_kV = 2.72e-03 * kV +0.772;

%% Cálculo final de la transmisión de la mesa
tt = tt * f_ang * f_kV;
end