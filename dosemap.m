% Calcula el mapa de dosis de un philips Azurion con la info de DOLQA.
% Versión de 2023


function psk = dosemap(rdsrFileName)

% rdsrFileName es el fichero que contiene la tabla de DOLQA con la 
% información del informe estructurado de dosis.
% Cada fila es un evento de radiación con los datos separados por ';' con
% los siguientes campos:

%% Campo                             Descripción
% StudyInstanceUid_Fkey             id del procedimiento
% IrradiationEventUID               id del evento
% AcquisitionProtocol                  
% AcquisitionPlane                  Single Plane/Frontal/Lateral
% DateTimeStarted
% IrradiationEventType              Fluoroscopy/Stationary Aquisition
% ReferencePointDefinition          
% DoseAreaProduct                   KAP (Gy·cm2)
% DoseRP                            Kerma en PRef Interv (Gy)
% PositionerPrimaryAngle            Angulo lateral (gra) segun DICOM LAO =
%                                   +90º y RAO = -90º posicion det imag.
% PositionerSecondaryAngle          Angulo cra-caudal (gra) segun DICOM
%                                   CRAN = +90º CAU = -90º posicion det img
% XRayFilter1Type                   
% XRayFilter1Material               
% XRayFilter1ThicknessMinimum       (mm) usado para calculo
% XRayFilter1ThicknessMaximum       (mm)
% XRayFilter2Type
% XRayFilter2Material
% XRayFilter2ThicknessMinimum       (mm) usado para calculo
% XRayFilter2ThicknessMaximum       (mm)
% FluoroMode                        PULSED/CONTINOUS
% PulseRate                         (fr/s)
% NumberofPulses
% XRayTubeCurrent                   (mA)
% DistanceSourcetoIsocenter         (mm)
% KVP                               
% ExposureTime                      
% Exposure
% PulseWidth                        (ms)
% IrradiationDuration
% PatientTableRelationship          headfirst/feetfirst/... Orientation of   
%                                   the Patient with respect to the Head 
%                                   of the Table.
% PatientOrientation                Orientation of the Patient with respect
%                                   to Gravity.
% PatientOrientationModifier        supine/prone/lateral  Enhances or 
%                                   modifies the Patient orientation 
%                                   specified in Patient Orientation.
% TargetRegion                      Head/Chest/Abdomen...
% NumberofFrames
% SubImagesperFrame
% BottomShutter                                       
% LeftShutter
% RightShutter
% TopShutter
% HeightofSystem                    Solo Philips. Altura iso (mm)
% LongitudinalBeamPosition          Posicion longitudinal del brazo. Campo 
%                                   privado Philips no en GE o Siemens
% BeamAngle                         Angulo del brazo en suspensión. Campo 
%                                   privado Philips no en GE o Siemens
% TableHeightPosition               (mm) 113753 Table Height Position with 
%                                   respect to an arbitrary chosen 
%                                   reference by the equipment in (mm). 
%                                   Table motion downwards is positive.
% CollimatedFieldArea
% PatientEquivalentThickness        (mm) Value of the control variable used
%                                   to parametrize the Automatic Exposure 
%                                   Control (AEC) closed loop. E.g., "Water Value".
% CollimatedFieldHeight             Y (mm) Distance between the collimator
%                                   blades in pixel column direction as 
%                                   projected at the detector plane.
% CollimatedFieldWidth              X (mm) Distance between the collimator 
%                                   blades in pixel row direction as 
%                                   projected at the detector plane.
% DistanceSourcetoDetector          (mm) Measured or calculated distance 
%                                   from the X-Ray source to the detector 
%                                   plane in the center of the beam.
% TableLongitudinalPosition         (mm) 113751 Table Longitudinal Position
%                                   with respect to an arbitrary reference 
%                                   chosen by the equipment. Table 
%                                   longitudinal motion is positive towards
%                                   the left of the patient assuming the 
%                                   patient is positioned HEAD FIRST SUPINE.   
% TableLateralPosition              (mm) 113752 Table Lateral Position with
%                                   respect to an arbitrary reference 
%                                   chosen by the equipment. Table lateral 
%                                   motion is positive towards the head of
%                                   the patient assuming the patient is 
%                                   positioned HEAD FIRST.
% DistanceWedge1
% DistanceWedge2
% AngleWedge1
% AngleWedge2
% LateralBeamPosition               (mm) posición lat brazo en suspensión 
%                                   campo privado Philips no en GE o Siemens.
% Manufacturer
% ManufacturerModelName
%
% Descripción de los campos en 
% https://dicom.nema.org/medical/dicom/current/output/chtml/part16/sect_xrayradiationdosesriodtemplates.html
% https://dicom.nema.org/medical/dicom/current/output/chtml/part16/chapter_D.html#DCM_113866
% https://dicom.nema.org/medical/dicom/current/output/chtml/part16/chapter_d.html
% https://dicom.nema.org/medical/dicom/2017c/output/chtml/part16/sect_CID_10008.html
% Angulos prim y sec
% https://dicom.nema.org/medical/Dicom/2017c/output/chtml/part03/sect_C.8.7.5.html#:~:text=The%20valid%20range%20of%20Primary,%2D90%20to%20%2B%2090%20degrees.
% Mesa
% https://dicom.nema.org/medical/Dicom/2016b/output/chtml/part03/sect_C.8.19.6.11.html

%% Creamos fichero log con diary
diary(strcat(rdsrFileName,'.log'));

%% Lectura de los ficheros de eventos y almacenado en una tabla.
try
    events = readtable(rdsrFileName, 'DecimalSeparator', ',');
catch excepcion
    disp('error al abrir fichero');
    disp(excepcion);
    diary off;
    return
end

%% Inicializo la matriz de distribución de dosis
m = 0;

%% Clasificamos por region corporal
switch events.TargetRegion{1}
    case 'Head'
        disp('Calculation NOT valid for Head');
        disp(events.TargetRegion);
        diary off;
        return %termina el programa;
end

%% Revisamos distancia foco detector
if (~strcmp('FinalDistanceSourcetoDetector',events.Properties.VariableNames))
    disp('Not info about final distance source to detector');
    if (~strcmp('DistanceSourcetoDetector',events.Properties.VariableNames))
        disp('No info about distance source to detector');
        disp('Calculation not possible');
        diary off;
        return  % termina el programa
    else
        events.FinalDistanceSourcetoDetector = events.DistanceSourcetoDetector;
    end
end
% Si la distancia detector no es numerica termina programa
if ~isa(events.FinalDistanceSourcetoDetector,'numeric')
    disp('No info about distance source to detector');
    disp('Calculation not possible');
    diary off;
    return  % termina el programa
end
%
% Si la distancia detector no es 0 termina programa
if all(events.FinalDistanceSourcetoDetector==0)
    disp('No info about distance source to detector');
    disp('Calculation not possible');
    diary off;
    return  % termina el programa
end
%
if any(events.FinalDistanceSourcetoDetector==0)
    disp('Warning. Some events had distance source to detector = 0 mm');
    disp('Those events will not be considered for calculation')
    disp(events(events.DistanceSourcetoDetector==0,:));
    % Eliminamos eventos con DistanceSourcetoDetector < 500
    events(events.DistanceSourcetoDetector < 500,:) = [];
end

%% Revisamos colimación y utilizamos area si Collimated Field W/H no está
% vacío. Caso de los Allura. No necesario.
if (~strcmp('CollimatedFieldWidth',events.Properties.VariableNames))
    % DOLQA proporcional collimated field area en cm2
    events.CollimatedFieldHeight = sqrt(events.CollimatedFieldArea)*10;
    events.CollimatedFieldWidth = sqrt(events.CollimatedFieldArea)*10;
    disp('There is no info about the X and Y colimators. Square field are used for calculation.')
end
% Si la colimación no es un numero
if (~isa(events.CollimatedFieldWidth,'numeric') || ~isa(events.CollimatedFieldHeight,'numeric'))
    disp('No info about collimation');
    disp('Calculation not possible');
    diary off;
    return  % termina el programa
end    
% Si la colimación sigue siendo 0 termina programa
if any(events.CollimatedFieldWidth == 0) || any(events.CollimatedFieldHeight == 0)
    disp('Program terminated: No collimation information available');
    diary off;
    return
end

%% Revisamos distancia foco isocentro
% Si no existe el campo distancesourcetoisocenter termina programa
if (~strcmp('DistanceSourcetoIsocenter',events.Properties.VariableNames))
    disp('Program terminated: No distance source to isocenter available');
    disp(events.DistanceSourcetoIsocenter);
    diary off;
    return
end
% Si el campo distancesourcetoisocenter no es numerico, termina programa
if ~isa(events.DistanceSourcetoIsocenter,'numeric')
    disp('Program terminated: No distance source to isocenter available');
    disp(events.DistanceSourcetoIsocenter);
    diary off;
    return
end
% Si el campo distancesourcetoisocenter es cero termina programa
if any(events.DistanceSourcetoIsocenter==0)
    disp('Program terminated: No distance source to isocenter available');
    disp(events.DistanceSourcetoIsocenter);
    diary off;
    return
end
% La coordenada de mesa depende del fabricante
% Deberá ser la altura de la mesa respecto del iso
switch events.Manufacturer{1}
    case "Philips Medical Systems"
        couch_vertical = MesaVert(events.HeightofSystem(1), ...
            events.TableHeightPosition);
    case "Philips"
        couch_vertical = MesaVert(events.HeightofSystem(1), ...
            events.TableHeightPosition);
    case "Canon"
        couch_vertical = -150;
    otherwise
        couch_vertical = events.TableHeightPosition;
end


%% Calculamos para cada evento
nEvents = length(events.IrradiationEventUID);
for i = 1:nEvents
    primary_angle = events.PositionerPrimaryAngle(i);
    secondary_angle = events.PositionerSecondaryAngle(i);
    % Collimated Field es el tamaño campo a 1 m.
    CollimatedFieldHeight = events.CollimatedFieldHeight(i)*...
        1000/events.DistanceSourcetoDetector(i);
    CollimatedFieldWidth = events.CollimatedFieldWidth(i)*...
        1000/events.DistanceSourcetoDetector(i);
    fid = events.DistanceSourcetoIsocenter(i);

    kerma_rp = events.DoseRP(i);
    % La mesa se redefine desde la definicion dicom. Dicom es desde el
    % punto de vista del operador situado a la dcha paciente en supino.
    if i == 1
        couch_lateral = 0;
        couch_longitudinal = 0;
        couch_vert = couch_vertical(i);
    else
        couch_lateral = events.TableLongitudinalPosition(i)-...
            events.TableLongitudinalPosition(i-1);
        couch_longitudinal = events.TableLateralPosition(i)-...
            events.TableLateralPosition(i-1);
        couch_vert = couch_vertical(i); 
    end
    %
    kv = events.KVP(i);
    XRayFilter1Material = events.XRayFilter1Material(i);
    XRayFilter1ThicknessMinimum = events.XRayFilter1ThicknessMinimum(i);
    XRayFilter2Material = events.XRayFilter2Material(i);
    XRayFilter2ThicknessMinimum = events.XRayFilter2ThicknessMinimum(i);
    
    try      
        dme = dosemapevent(primary_angle, secondary_angle,...
            CollimatedFieldWidth, CollimatedFieldHeight, fid, kerma_rp,...
            couch_lateral, couch_longitudinal, couch_vert, kv,...
            XRayFilter1Material, XRayFilter1ThicknessMinimum,...
            XRayFilter2Material, XRayFilter2ThicknessMinimum);
    catch excepcion
        disp('error in dosemapevent function')
        disp(excepcion);
        diary off;
        return
    end
    m = m + dme;
end

%% Obtenemos la dosis pico de la matriz suma de todos los eventos
psk = max(max(m));

%% Creamos gráfico
%grafico en png
X=[-400 400];
Y=[-800 800];
fig = figure;
set(fig,'Visible','off'); % la figura no se ve pero se imprime
%set(fig,'Visible','on');   % para debug
ax = axes;
colormap([0 0 1;0 0 1;0 0 1;...                      %azul 00-3000
    1 1 0; 1 1 0; ...                                % amarillo 3000-5000
    1 0.5 0; 1 0.5 0; 1 0.5 0; 1 0.5 0; 1 0.5 0; ... %naranja 5000-10000
    1 0 0; 1 0 0; 1 0 0; 1 0 0; 1 0 0; ...           %rojo 10000-15000
    1 1 1; 1 1 1])                                   %blanco > 15000
c = ([0 3000 5000 10000 15000 17000]); %kerma en mGy
%c = ([0 3 5 10 15 17]);  % kerma en Gy
caxis = ([c(1) c(6)]);
imagesc(X, Y, m, caxis);
colorbar('FontSize',11,'YTick', c, 'YTickLabel', ...
    {'0,0', '3,0', '5,0', '10,0', '15,0 Gy', ''});
pbaspect([1,2,1]);
titul = strcat('Mapa de dosis a la altura de la mesa. Dmax = ',...
    num2str(round(psk,1)),' mGy');
ax.Title.String = titul;
ax.XLabel.String = 'Izda         (mm)         Dcha pac.';
ax.YLabel.String = 'Pies                  (mm)                 Cabeza';

%% Escribimos resultados
% Creamos nombre de fichero 
NombreMapa = strcat(rdsrFileName,'.png');
try
    saveas(fig, NombreMapa, 'png');
catch excepcion
    disp('error trying to write map');
    disp(excepcion);
    diary off;
    return
end
clf(fig);
delete(get(fig,'children'));
disp('Peal skin dose (mGy)');
disp(psk);
% Cierra el fichero log y el diario.
diary off;

% Proporciona el PSD por consola en mGy
% disp(num2str(psk));

return
end


