% Calcula el mapa de dosis de un philips Azurion con la info de DOLQA.
% Versión de 2023

%% 21/04/23  Cambiar color map por iec

function dosemap(rdsrFileName)

% rdsr es el fichero que contiene la tabla con la información del informe 
% estructurado de dosis.
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

%% Lectura de los ficheros de eventos y almacenado en una tabla.
try
    events = readtable(rdsrFileName, 'DecimalSeparator', ',');
catch excepcion
    disp('error al abrir fichero');
    return
end

%% Inicializo la matriz de distribución de dosis
m = 0;
%% Calculamos los procedimientos y los eventos y los sumamos en un mismo
%  fichero
% Clasificamos por fabricante
% switch events.Manufacturer{1}
%     case 'Philips Medical Systems'
%         DistFocoSuelo = 273; %mm
%         %DistRPSuelo = 915; %mm
%     case 'TOSHIBA_MEC'
%         %DistRPSuelo = 890;
%         DistFocoSuelo = 340;
%         disp(strcat('Procedure',{' '},num2str(k),' performed at',{' '},...
%         events.Manufacturer{1},' system.'));
%         disp(strcat(events.Manufacturer(1),' not supported'));
%         return %termina el programa;
%     case 'SIEMENS'
%         DistFocoSuelo = 310
%         disp(strcat('Procedure',{' '},num2str(k),' performed at',{' '},...
%         events.Manufacturer{1},' system.'));
%         disp(strcat(events.Manufacturer(1),' not supported'));
%         return %termina el programa;
%     otherwise
%         disp(strcat('Procedure',{' '},num2str(k),' performed at',{' '},...
%         events.Manufacturer{1},' system.'));
%         disp(strcat(events.Manufacturer(1),' not supported'));
%         return %termina el programa;
% end

%% Clasificamos por region corporal
switch events.TargetRegion{1}
    case 'Head'
        disp(strcat('Procedure',{' '},num2str(k),' performed at',{' '},...
        events.TargetRegion{1}));
        disp('Calculation NOT valid for Head');
        disp('Program interrupted');
        return %termina el programa;
end
%% Revisamos colimación y utilizamos shutters si Collimated Field está
% vacío. Caso de los Allura. No necesario.
if any(events.CollimatedFieldWidth == 0) || any(events.CollimatedFieldHeight == 0)
    events.CollimatedFieldHeight = events.TopShutter + events.BottomShutter;
    events.CollimatedFieldWidth = events.LeftShutter + events.RightShutter;
end
% Si la colimación sigue siendo 0 termina programa
if any(events.CollimatedFieldWidth == 0) || any(events.CollimatedFieldHeight == 0)
    disp(strcat('Procedure',{' '},num2str(k),', event',{' '},num2str(i)));
    disp('Program terminated: No collimation information available');
    return
end

%% Revisamos distancia foco isocentro
if any(events.DistanceSourcetoIsocenter)==0
    disp('Program terminated: No distance source to isocenter available');
    return
end

%% Calculamos para cada evento
nEvents = length(events.IrradiationEventUID);
for i = 1:nEvents
    AcquisPlane = events.AcquisitionPlane(i);
    primary_angle = events.PositionerPrimaryAngle(i);
    secondary_angle = events.PositionerSecondaryAngle(i);
    shutter_left = events.LeftShutter(i);
    shutter_rigth = events.RightShutter(i);
    shutter_top = events.TopShutter(i);
    shutter_bottom = events.BottomShutter(i);
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
        couch_vertical = 0;
    else
        couch_lateral = events.TableLongitudinalPosition(i)-events.TableLongitudinalPosition(i-1);
        couch_longitudinal = events.TableLateralPosition(i)-events.TableLateralPosition(i-1);
        couch_vertical = 0; % No utilizado events.TableHeightPosition(i)
    end

    %HS = str2num(HeightSys);
    %couch_vertical = events.TableHeightPosition(i)-(HS-150);
    kv = events.KVP(i);
    XRayFilter1Material = events.XRayFilter1Material(i);
    XRayFilter1ThicknessMinimum = events.XRayFilter1ThicknessMinimum(i);
    XRayFilter2Material = events.XRayFilter2Material(i);
    XRayFilter2ThicknessMinimum = events.XRayFilter2ThicknessMinimum(i);
    
    try      
        dme = dosemapevent(primary_angle, secondary_angle,...
            CollimatedFieldWidth, CollimatedFieldHeight, fid, kerma_rp,...
            couch_lateral, couch_longitudinal, couch_vertical, kv,...
            XRayFilter1Material, XRayFilter1ThicknessMinimum,...
            XRayFilter2Material, XRayFilter2ThicknessMinimum);
    catch excepcion
        disp('error in dosemapevent function')
        return
    end
    m = m + dme;
end
% Pasamos a mGy para grafico.
m = 1000*m;
%% Obtenemos la dosis pico de la matriz suma de todos los eventos
psk = max(max(m));

%% Creamos gráfico
%grafico en png
X=[-350 350];
Y=[-350 350];
fig = figure;
%set(fig,'Visible','off'); % la figura no se ve pero se imprime
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


