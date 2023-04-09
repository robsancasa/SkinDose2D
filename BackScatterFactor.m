function b = BackScatterFactor(area)
% Calcula el factor de retrodispersión en funcion del area del campo
% incidente
% Estimado promedio para Philips y Toshiba.
if area > 450;
    area = 450;
end
b = -1.915e-6*area.^2+1.779e-3*area+1.12;
return


