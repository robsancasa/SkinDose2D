# SkinDose2D<br>
Madrid 24 de abril de 2023<br>
Estima el mapa de dosis piel en un plano horizontal en el punto de referencia intervencionista para equipos de la modalidad XA utilizados en cardiología y radiología intervencionistas.<br>
<br>
Uso del fichero ejecutable para windows:<br>
<br>
dosemap.exe nombrefichero<br>
<br>
nombrefichero es un fichero de texto proporcionado por el sistema DOLQA con la informacion necesaria para el cálculo tal y como se describe más abajo.<br>
<br>
Devuelve el valor de la dosis pico en piel y un mapa de dosis en formato png.<br><br>

Método de estimación:<br>
Estima la proyección del kerma emitido por el tubo de rayos-X en el plano horizontal situado en el punto de referencia intervencionista 15 cm bajo el isocentro (en dirección al tubo).<br>
Para cada evento de irradiación realiza el cálculo en un plano de tamaño 70x70 cm con una resolución de 2,5mm. Estima la dosis en cada uno de los puntos utilizando la expresión:<br><br>
Dosis =Kerma rp · u_en_ro · BSF(kV, filtración, área campo) · TransMesa(kV, filtración, angulo brazo) · f_distancia<br><br>
Donde:<br>
Kerma rp es el kerma en el punto de referencia intervencionista.<br><br>
u_en_ro es la razón de coeficientes de absorción en energía agua aire obtenido de la publicación Hamza Benmakhlouf1,2, Hugo Bouchard3, Annette Fransson1 and Pedro Andreo. Phys. Med. Biol. 56 (2011) 7179–7204 doi:10.1088/0031-9155/56/22/012<br><br>
BSF es el factor de retrodispersión obtenido de la publicación Hamza Benmakhlouf1,2, Hugo Bouchard3, Annette Fransson1 and Pedro Andreo. Phys. Med. Biol. 56 (2011) 7179–7204 doi:10.1088/0031-9155/56/22/012<br><br>
TransMesa es el factor de atenuación de la mesa dependiente de la calidad del haz y el ángulo de incidencia. Obtenido de medidas experimentales.<br><br>
F_distancia es la corrección por distancia para cada haz de radiación, importante para los casos en que el haz está angulado y la distancia foco plano es diferente en las distintas partes del campo de radiación.<br><br>
Como principales limitaciones hay que tener en cuenta:<br>
Modela al paciente como una superficie horizontal. En angulaciones altas del brazo no tiene en cuenta correctamente la distancia foco piel.<br>
Aunque sí tiene en cuenta desplazamientos laterales de la mesa, pero si la posición del paciente es muy diferente del punto de referencia intervencionista, no se tiene en cuenta. Esto puede afectar tanto al tamaño de campo de radiación en la piel del paciente como a la corrección por distancia del kerma en el punto de referencia.<br>
El programa tiene como variable de entrada un fichero con la información del procedimiento proporcionado por la utilidad DOLQA, que deberá contener al menos los siguientes campos para todos los eventos:<br>
Dose RP                            Kerma en el punto de referencia interv (Gy)<br>
Positioner Primary Angle            Angulo lateral (gra) segun DICOM LAO = +90º y RAO = -90º posicion det imag.<br>
Positioner Secondary Angle          Angulo cra-caudal (gra) segun DICOM CRAN = +90º CAU = -90º posicion det img<br>
Xray Filter 1 Material            	   Aluminio o Cobre<br>
Xray Filter 1 Thickness		     Espesor del filtro en  (mm) <br>
XRayFilter2Material		Aluminio o Cobre<br>
XRayFilter2ThicknessMinimum       Espesor del filtro en  (mm)<br>
DistanceSourcetoIsocenter         (mm)<br>
KVP                               <br>
TargetRegion                      Head/Chest/Abdomen... En caso de que sea cabeza no realiza el cálculo.<br>
CollimatedFieldHeight             Y (mm) Distance between the collimator blades in pixel column direction as projected at the detector plane. <br>
CollimatedFieldWidth              X (mm) Distance between the collimator blades in pixel row direction as projected at the detector plane.<br>
DistanceSourcetoDetector          (mm) Measured or calculated distance from the X-Ray source to the detector plane in the center of the beam.<br>
TableLongitudinalPosition         (mm) 113751 Table Longitudinal Position with respect to an arbitrary reference chosen by the equipment. Table longitudinal motion is positive towards  the left of the patient assuming the patient is positioned HEAD FIRST SUPINE.   <br>
TableLateralPosition              (mm) 113752 Table Lateral Position withrespect to an arbitrary reference chosen by the equipment. Table lateral motion is positive towards the head of  the patient assuming the patient is positioned HEAD FIRST.<br>
Como variables de salida el programa proporciona la dosis pico en piel en mGy y un fichero *.png con el mapa de dosis en el plano del punto de referencia intervencionista que representaría la dosis del paciente si viéramos su espalda.<br>
