% Calcula la transmisión del conjunto colchoneta mesa incluyendo el forward
% scatter. Datos tomados de Matthew C. DeLorenzo, Kai Yang, Xinhua Li, and 
% Bob Liu. Comprehensive evaluation of broad-beam transmission of patient
% supports. Med. Phys. 45 (4), April 2018. 10.1002/mp.12803

function tt = TableTransmision(kV, TC, prim_ang, sec_ang, filtr1m,...
    filtr1th, filtr2m, filtr2th)
% kV = 120 % Kilovoltaje
% TC = 22  % Area del campo de radiación en superficie
% prim_ang = 0  % Ángulo primario
% sec_ang = 0   % Ángulo secundario
% filtr1m = 'al' 
% filtr1th = 0.4
% filtr2m = 'Copper or Copper compound'
% filtr2th = 0.9


%% Corrección por el kilovoltaje y filtración 
% 1 + a ln(b*kv+a) + c ln(b*filt+c)
espesor = 0;

if (strcmp(filtr1m,'Copper or Copper compound') == 1 ||...
        strcmp(filtr2m,'Copper or Copper compound') == 1)
    if strcmp(filtr1m,'Copper or Copper compound') == 1
        espesor = filtr1th;
    else
        espesor = filtr2th;
    end
end
f_kvf = 1 + 0.1321 * log(1.5892 * kV + 0.1321) + 5.043e-02 * log (1.5892 *...
    espesor + 5.043e-02);

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
if alfa < 80
    %f_ang = -7.436e-05 * alfa^2 + 2.687e-05 * alfa + 0.9986;
    f_ang = -4.90e-05 * alfa.^2 + 3.07e-04 * alfa + 1.0;
else
    f_ang = 1.0;
end


%% Corrección por el tamaño de campo
% TC es el área en superficie en m2
TC = TC/1.e4;
if TC > 0.058
    TC = 0.058;
end
f_tc = -12.47 * TC.^2 + 1.7081 * TC + 0.4890;

%% Cálculo final de la transmisión de la mesa
tt = f_ang * f_tc * f_kvf;
end