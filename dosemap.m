% Calcula el mapa de dosis de un informe estructurado de un philips allura
function dosemap(rdsrFileName)

% rdsr es el fichero que contiene el informe estructurado de dosis
% Cada fila es un evento de radiación con los datos separados por \t

% eventUID es la id del evento

% primary_angle es el ángulo º de rotación respecto del eje y, lateral.
% Si prim_ang>0 el detector va desde la derecha del paciente al centro

% secondary_angle es el ángulo º de rotación respecto del eje x, cran-cau.
% Si x_ang>0 el detector va de la posición caudal hacia el centro

% shutter_left es el hemicampo en la dirección x izda en mm. Definido a 1 m 
% del focopara los philps allura

% shutter_rigth es el hemicampo en la dirección x dcha en mm. Definido a 1 m 
% del foco para los philps allura

% shutter_top es el hemicampo en la dirección y arriba en mm. Definido a 1 m 
% del foco para los philips allura

% shutter_bottom es el hemicampo en la dirección y arriba en mm. Definido a 1 m 
% del foco para los philips allura

% focus isocenter distance en mm

% kerma_rp es el kerma en el punto de referencia de entrada al paciente en mGy

% couch_lateral es el desplazamiento lateral de la mesa. Si x_couch>0 la mesa
% se desplaza a la izquierda del paciente (el campo hacia la derecha del mapa)

% couch_longitudinal es el desplazamiento cabeza-pies de la mesa. Si y_couch>0 la mesa
% se desplaza hacia la cabeza (el campo hacia los pies del mapa)

% couch_vertical es el desplazamiento de mesa en altura en mm respecto del plano de
% referencia que a su vez esta 150 mm bajo el isocentro. Si z_couch<0 hacia
% el foco

% kv es el kilovoltage del evento

%% Lectura de los ficheros de eventos y almacenado en una struct.
%rdsrFileName = 'C:\Users\roberto\Dropbox\MATLAB\dosemap3D_3\doc\Signos_angulos\01.txt';
procedures = strsplit(rdsrFileName, ' ')';
formato = '%n %s %s %s %n %n %n %n %n %n %n %n %n %n %n %n %n %n %s %n %n %s %n %n %n';
columnas = {'IrradiationEventUID', 'TargetRegion',	'Manufacturer',...
    'AcquisitionPlane',	'PositionerPrimaryAngle',...
    'PositionerSecondaryAngle',	'LeftShutter',	'RightShutter',...
    'TopShutter',	'BottomShutter',	'DistanceSourcetoIsocenter',...
    'DoseRP',	'couch_lat', 'couch_long',	'couch_vert',	'KVP',...
    'CollimatedFieldArea',	'TableHeightPosition',	'XRayFilter1Material'...
    'XRayFilter1ThicknessMinimum',	'XRayFilter1ThicknessMaximum',...
    'XRayFilter2Material',	'XRayFilter2ThicknessMinimum',...
    'XRayFilter2ThicknessMaximum',	'LongitudinalBeamPosition'};
[directorio,nombrefichero,~] = fileparts(procedures{1});

for i=1:length(procedures)    
    EventFile = fopen(procedures{i});
    try
        fichero = textscan(EventFile, formato, 'Delimiter', '\t', ...
        'HeaderLines', 1, 'ReturnOnError', 0);
    catch
        disp('error al abrir fichero');
        return
    end
    fclose(EventFile);
    events(i) = cell2struct(fichero, columnas, 2);
end

%% Inicializo la matriz de distribución de dosis
m = 0;
%% Calculamos los procedimientos y los eventos y los sumamos en un mismo
%  fichero
for k=1:length(procedures)
    % Clasificamos por fabricante
    switch events(k).Manufacturer{1}
        case 'Philips Medical Systems'
            DistFocoSuelo = 273; %mm
            %DistRPSuelo = 915; %mm
        case 'TOSHIBA_MEC'
            %DistRPSuelo = 890;
            DistFocoSuelo = 340;
            disp(strcat('Procedure',{' '},num2str(k),' performed at',{' '},...
            events(k).Manufacturer{1},' system.'));
            disp(strcat(events(k).Manufacturer(1),' not supported'));
            return %termina el programa;
        case 'SIEMENS'
            DistFocoSuelo = 310
            disp(strcat('Procedure',{' '},num2str(k),' performed at',{' '},...
            events(k).Manufacturer{1},' system.'));
            disp(strcat(events(k).Manufacturer(1),' not supported'));
            return %termina el programa;
        otherwise
            disp(strcat('Procedure',{' '},num2str(k),' performed at',{' '},...
            events(k).Manufacturer{1},' system.'));
            disp(strcat(events(k).Manufacturer(1),' not supported'));
            return %termina el programa;
    end
    % Clasificamos por region corporal
    switch events(k).TargetRegion{1};
        case 'Chest'
        otherwise
            disp(strcat('Procedure',{' '},num2str(k),' performed at',{' '},...
            events(k).TargetRegion{1}));
            disp('Calculation only valid for Chest');
            disp('Program interrupted');
            return %termina el programa;
    end
    nEvents = length(events(k).IrradiationEventUID);
    for i = 1:nEvents
        AcquisPlane = events(k).AcquisitionPlane(i);
        primary_angle = events(k).PositionerPrimaryAngle(i);
        secondary_angle = events(k).PositionerSecondaryAngle(i);
        shutter_left = events(k).LeftShutter(i);
        shutter_rigth = events(k).RightShutter(i);
        shutter_top = events(k).TopShutter(i);
        shutter_bottom = events(k).BottomShutter(i);
        fid = events(k).DistanceSourcetoIsocenter(i);
        kerma_rp = events(k).DoseRP(i);
        couch_lateral = 0;
        couch_longitudinal = 0;
        couch_vertical = 0;
        %HS = str2num(HeightSys);
        %couch_vertical = events(k).TableHeightPosition(i)-(HS-150);
        kv = events(k).KVP(i);
        filter1 = 0;
        filter2 = 0;
        % Si los shutters estan vacíos, tomamos area y hacemos campo cuadrado
        if (shutter_left == 0 && shutter_right == 0 && shutter_top == 0 &&...
                shutter_bottom == 0)
            disp(strcat('Procedure',{' '},num2str(k),', event',{' '},num2str(i)));
            disp('Program terminated: No shutter information available');
            return
        %    shutter_left = power(event.CollimatedFieldArea(i),0.5)/2;
        %    shutter_rigth = power(event.CollimatedFieldArea(i),0.5)/2;
        %    shutter_top = power(event.CollimatedFieldArea(i),0.5)/2;
        %    shutter_bottom = power(event.CollimatedFieldArea(i),0.5)/2;
        end
        try
            dme = dosemapevent(primary_angle,secondary_angle,shutter_left,...
                shutter_rigth, shutter_top, shutter_bottom, fid, kerma_rp,...
                couch_lateral, couch_longitudinal, couch_vertical,kv);
        catch
            disp('error in dosemapevent function')
            return
        end
        m = m + dme;
    end
end

%% Obtenemos la dosis pico de la matriz suma de todos los eventos
psk = max(max(m));

%% Creamos gráfico
%grafico en png
X=[-350 350];
Y=[-350 350];
fig = figure;
set(fig,'Visible','off'); % la figura no se ve pero se imprime
ax = axes;
colormap jet
c = ([100 300 1000 3000 10000 15000]);
caxis = ([log(c(1)) log(c(length(c)))]);
im = imagesc(X, Y, log(m+1), caxis);
colorbar('FontSize',11,'YTick', log(c), 'YTickLabel', c);
%ax.YDir = 'normal';
daspect = [1,1];
titul = strcat('Mapa de dosis a 15 cm bajo el isocentro. Dmax = ',...
    num2str(round(psk)),' mGy');
ax.Title.String = titul;
ax.XLabel.String = 'Izda                      Vista de la espalda (mm)                        Dcha pac.';
ax.YLabel.String = '(mm)';
text(-250,-425,'Warning: Lateral and longitudinal couch displacements were not available for dose calculation.',...
    'FontSize', 7);
%% Escribimos resultados
% Creamos nombre de fichero dependiendo de si calculamos uno o varios 
% procedimienntos
if length(procedures) == 1;
    manymaps = nombrefichero;
else
    manymaps = strcat(nombrefichero,'_and_others');
end
NombreMapa = strcat(directorio,'\',manymaps,'.png');
try
    %print(fig, NombreMapa, '-dpng', '-r150');
    saveas(fig, NombreMapa, 'png');
catch
    disp('error trying to write map');
    return
end
%clf(fig);
%delete(get(fig,'children'));
warning('off','all');
% Proporciona el PSD por consola
disp (psk);
return
end


