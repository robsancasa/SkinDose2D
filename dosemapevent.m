function dmap = dosemapevent(prim_ang, sec_ang, coll_w, coll_h,...
    fid, kerma, x_couch, y_couch, z_couch, kV, f1mat, f1thick, f2mat, f2thick)

% Devuelve la matriz 281x281 elementos representando el kerma del evento
% de radiación calculado en el plano del punto de ref interv de 700x700 mm2

% prim_ang es el ángulo º de rotación respecto del eje y, lateral.
% Si prim_ang>0 el detector va desde la derecha del paciente al centro

% sec_ang es el ángulo º de rotación respecto del eje x, cran-cau.
% Si x_ang>0 el detector va de la posición caudal hacia el centro

% coll_w (mm) es el campo X definido a 1 m

% coll_h (mm) es el campo Y definido a 1 m

% fid es la distancia foco isocentro en mm

% k es el kerma en el punto de referencia de entrada al paciente en Gy

% x_couch es el desplazamiento lateral de la mesa respecto de la posicion 
% anterior. Si x_couch>0 la mesa se desplaza a la izquierda del paciente
% (el campo hacia la derecha del mapa). Paciente en supino

% y_couch es el desplazamiento cabeza-pies de la mesa respecto de la 
% posicion anterior. Si y_couch>0 la mesa % se desplaza hacia la cabeza 
% (el campo hacia los pies del mapa). Paciente en supino.

% z_couch es el desplazamiento de mesa en altura en mm respecto del plano de
% referencia que a su vez esta 150 mm bajo el isocentro. Si z_couch<0 hacia
% el foco

%prim_ang = 0;
%sec_ang = 0;
%x_shut_l = 150;
%x_shut_r = 150;
%y_shut_t = 150;
%y_shut_b = 150;
%fid = 765;
%kerma = 100;
%x_couch = 0;
%y_couch = 0;
%z_couch = 0;
%kV = 80;

% Para estar de acuerdo con el estandar dicom, los primary y secondary
% Estándar DICOM detector derecha paciente prim angle < 0
% Estándar DICOM detector craneal sec angle < 0

%matriz de rotaciones respecto eje x cran caud
Rx = [1 0 0;0 cos(sec_ang*pi/180) -sin(sec_ang*pi/180);...
    0 sin(sec_ang*pi/180) cos(sec_ang*pi/180)];

%matriz de rotaciones respecto eje y izd der
% angles deben multiplicarse por -1
Ry = [cos(-prim_ang*pi/180) 0 sin(-prim_ang*pi/180);0 1 0;...
    -sin(-prim_ang*pi/180) 0 cos(-prim_ang*pi/180)];

xcol = coll_w * fid/1000; % colimador x en plano del iso en mm
ycol = coll_h * fid/1000; % colimador y en plano del iso en mm

% El origen de coordenadas está localizado en el isocentro
% iso = [0; 0; 0];

% Foco cuando no hay rotaciones
foco = [0; 0; -fid]; 

% cuatro esquinas del campo rectangular en el plano del iso sin rotacion
piso_pp = [xcol/2; ycol/2; 0]; %esquina ++
piso_mp = [-xcol/2; ycol/2; 0]; %esquina -+
piso_mm = [-xcol/2; -ycol/2; 0]; %esquina --
piso_pm = [xcol/2; -ycol/2; 0]; %esquina +-

% aplicamos rotaciones RyRx*v (no conmutativas)
foco = Rx*foco;
foco = Ry*foco;
prot_pp = Rx*piso_pp;
prot_pp = Ry*prot_pp;
prot_mp = Rx*piso_mp;
prot_mp = Ry*prot_mp;
prot_mm = Rx*piso_mm;
prot_mm = Ry*prot_mm;
prot_pm = Rx*piso_pm;
prot_pm = Ry*prot_pm;

%Vectores de las rectas foco-prot
FP_pp = prot_pp - foco;
FP_mp = prot_mp - foco;
FP_mm = prot_mm - foco;
FP_pm = prot_pm - foco;

% El plano de calculo estará en el plano del punto de referencia
p_calc = -150; %+ z_couch no utilizado;

% Parámetro t resultante de la solución de la intersección recta con el
% plano de calculo
t_FP_pp = (p_calc-prot_pp(3))/FP_pp(3);
t_FP_mp = (p_calc-prot_mp(3))/FP_mp(3);
t_FP_mm = (p_calc-prot_mm(3))/FP_mm(3);
t_FP_pm = (p_calc-prot_pm(3))/FP_pm(3);

% Intersección de las 4 rectas (aristas de la pirámide) que definen el haz
% con el plano de de calculo = vértices del campo en su proyección del 
% campo en el plano de cálculo
pp = prot_pp + t_FP_pp * FP_pp;
mp = prot_mp + t_FP_mp * FP_mp;
mm = prot_mm + t_FP_mm * FP_mm;
pm = prot_pm + t_FP_pm * FP_pm;

% xvert e yvert son vectores que definen las coordenadas x e y de los  
% vértices del cuadrilátero que define la proyección del campo en el plano
% de cálculo
xvert = [pp(1) mp(1) mm(1) pm(1) pp(1)];
yvert = [pp(2) mp(2) mm(2) pm(2) pp(2)];
centro = [(pp(1)+ mp(1) +mm(1) + pm(1))/4;...
    (pp(2) + mp(2) + mm(2) + pm(2))/4; (pp(3) + mp(3) + mm(3) + pm(3))/4];

% Matriz de mapa de dosis de n x m elementos para cubrir un area de
% 800x1600 mm y resolución 2.5 mm resx x resy mm.
m = 321;
n = 641;
resx = 800/(m-1);
resy = 1600/(n-1);
%dmap = zeros(m,n);

% Definimos las matrices xquer e yquer que contienen las coordenadas x e y
% del plano de calculo, de -350 a 350 mm
xq = -400:resx:400;
xquer = repmat(xq,n,1);
yq = (-800:resy:800)';
yquer = repmat(yq,1,m);

% En caso de que la mesa no esté centrada en x e y aplicamos desplazamiento
% de mesa
% x_couch positivo
xvert = xvert + x_couch;
yvert = yvert + y_couch;
foco(1) = foco(1) + x_couch;
foco(2) = foco(2) + y_couch;

% Calculamos la matriz facdist con el factor de correción por inverso del
% cuadrado de la distancia para todos los puntos del plano de calculo
facdist = power(xquer-foco(1),2) + power(yquer-foco(2),2) + ...
    (p_calc-foco(3))^2;
facdist = power(facdist,0.5);
facdist = power(facdist*1/(fid-150),-2);
%mesh(facdist);

% Comprueba que el punto del plano (xquer,yquer)está dentro del cuadrilátero que
% que define el campo y en caso afirmativo le asigna el kerma k
in=inpolygon(xquer,yquer,xvert,yvert);
dmap=in*kerma;

% Aplicamos el factor distancia a cada punto del plano de calculo
dmap = times(facdist,dmap);

% Calculamos factor de retrodispersion
area = polyarea(xvert, yvert)/100; % Area en cm2 en el plano de ref.
%if area > 500   
    %disp(strcat('Warning: event',{' '},...
        %'with larger area than 500 cm2. BSF may be understimated'))
%end
[bsf, u_en_ro] = bsf_mu(area, kV, f1mat, f1thick, f2mat, f2thick);

% Factor de atenuacion de la mesa
m_att = TableTransmision(kV, prim_ang, sec_ang, f1mat, f1thick, f2mat,...
    f2thick);

dmap = dmap*bsf*m_att*u_en_ro;

%Representamos mapa dosis
%contourf(xquer,yquer,dmap,10);     

%% Creamos log
% dlmwrite('dosemap.log',[kerma, bsf, m_att, pdist([foco';pp']),...
%     pdist([foco';pm']), pdist([foco';mp']), pdist([foco';mm'])], '-append')
        