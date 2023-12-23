% Solo para Philips 
% Transforma la coordenada vertical de la mesa a distancia respecto el
% isocentro.
% vert positivo indica por encima del iso
% vert negativo indica por debajo del iso
function vert = MesaVert(IsoHeigh, z)
% Entrada:
    % marca: indica el fabricante
    % modelo: modelo equipo
    % IsoHeigh: Solo para philips indica la altura desde el suelo al iso
    % z: array con todas las alturas de la mesa
% En caso de Philips, es la distancia al suelo +30 mm de espesor mesa
% En caso Siemens y GE es distancia respecto el iso
    vert = z + 80 - IsoHeigh;
end
