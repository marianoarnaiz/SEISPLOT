% %%%%%%%%%%%%%%%%%%%%%%%
% %                     %
% %  SEISPLOT Ver 5.0   %
% %                     %
% %%%%%%%%%%%%%%%%%%%%%%%
% Programa para Leer datos sismicos SEGY, generar secciones sismicas
% y hacer los picks de las llegadas en la seccion
% Elaborador por:
% Mariano Arnaiz (UCV)
% Maxiliano Bezada (University of Minessota)


% Clean Up
% Borrar el contenido de Matlab
clc
clear all
close all

disp('*************************************')
disp('*         Seisplot Ver 5.0          *')
disp('*           Abril de 2015           *')
disp('*************************************')
disp('*    Arnaiz, Bezada, Schmitz (2015) *')
disp('*************************************')
disp('*  Bienvenido a Seisplot Ver 4.1    *')
disp('*  un codigo disenado para trabajar *')
disp('*  con secciones sismicas de forma  *')
disp('*  interactiva en Matlab. Suerte!!  *')
disp('*  Bugs a: marianoarnaiz@gmail.com  *')
disp('*************************************')
disp(' ')
disp('El programa iniciara el modo interactivo.')
disp('Puede presionar Ctrl+c para detenerlo en')
disp('cualquier momento. Procure no cerrar la')
disp('figura de la seccion en ningun momento.')
disp('Recuerde verificar cuantos archivos vacios')
disp('lee Matlab en su sistema operativo (linea 375)')

%% Datos para el Programa
% Esta seccion contiene informacion necesaria para correr el programa de
% forma adecuada. Por favor, leer los parametros cuidadosamente.

% 0. Taza de muestreo del SEGY

SAMPLE=100;

% 1. Directorio de trabajo (en esta direccion van todos los codigos y archivos

if ispc == 1
Carpeta=uigetdir('\','Seleccione la carpeta con los archivos segy');
D= dir(Carpeta);
disp('Corriendo el codico en una PC')
else
Carpeta=uigetdir('/','Seleccione la carpeta con los archivos segy');
D= dir(Carpeta);
disp('Corriendo el codico en una MAC o LINUX')
end

% 2. Archivos con la geometria

%Preguntar el tipo de input y definir constantes con respeto al sistema
%utilizado
UIControl_FontSize_bak = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
resultD = menu('Sistema de Coordenadas Seleccionado','Geograficas (Grados)','Proyectadas (UTM)','Canal de Distancia (km)');
set(0, 'DefaultUIControlFontSize', UIControl_FontSize_bak);

if resultD == 1
     Vnum=1;
     Dnum=111.32;
end
if resultD == 2
     Vnum=1000;
     Dnum=1;
end
if resultD == 3
     disp('Cargar canal de distancia')
     Vnum=1;
     
end

%Carga de datos
load Geometria.txt 

disp(' ')
disp('Geometria Cargada.')
disp(' ')
%Calculo de las distancias al disparo
%Geometria(:,7)=distance(Geometria(:,1),Geometria(:,2),Geometria(:,3),Geometria(:,4));
%Orginazar el archivo de menor a mayor distancia
%Verificacion de cuantos archivos utilizar

prompt = {'?Cual fraccion de las trazas desea plotear (1=todas, 2 la mitad, etc)?:','?Cual es la velocidad de reduccion en km/s?:','?Cual es la tasa de muestreo del SEGY? (Numero entero)','?Cual es el factor de normalizacion a aplicar a las trazas?','Cual es el nombre del disparo?','Norte a la derecha (1) A la Izquierda (2)?'};
dlg_title = '1. Datos Iniciales';
num_lines = 1;
def = {'5','8','1','4','Disparo','1'};
answer = inputdlg(prompt,dlg_title,num_lines,def,'on');

%Fraccion de la seccion
FRACCION=cell2mat(answer(1));
FRACCION=str2double(FRACCION);
Geometria=Geometria(1:FRACCION:end,:);
SERIALES=Geometria(:,1);
coords=Geometria;
shotLat=coords(1,4);
shotLon=coords(1,5);

%Velocidad de reduccion
VV = cell2mat(answer(2));
VV=str2double(VV);
Vred=VV*Vnum; 

%Taza de muestro del SEGY
deltaT=cell2mat(answer(3));
deltaT=str2double(deltaT);

%Factor de Normalizacion
fac = cell2mat(answer(4));
fac=str2double(fac);

%Direccion del perfil
disparo=cell2mat(answer(5));
Perfil=cell2mat(answer(6));
Perfil=str2double(Perfil);

if Perfil==1
    A='N';
    B='S';
else
    A='S';
    B='N';
end   


disp(' ')
disp('Datos Generales Definidos.')
disp(' ')

%% FILTROS!!
%El codigo puede hacer 3 tipos de filtrado, un filtro Butterworth
%(recomendado), un filtro Gaussiano (por convolucion) y un filtro pasabanda
%de ventanas.

%Filtro

UIControl_FontSize_bak = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
filt = menu('Seleccione un Filtro','Butterworth Pasabanda','Gaussiano','FIR Pasabanda','No filtrar (Solo preprocesar)');
set(0, 'DefaultUIControlFontSize', UIControl_FontSize_bak);

disp(' ')
disp('Filtro Definido.')
disp(' ')

if filt == 1
    prompt = {'Frecuencia MENOR de corte del filtro?:','Frecuencia MAYOR de corte del filtro?:','Grado del filtro Butterworth?'};
    dlg_title = '2.1 FILTRO BUTTERWORTH';
    num_lines = 1;
    def = {'1','5','4'};
    answer = inputdlg(prompt,dlg_title,num_lines,def,'on');

        w1=cell2mat(answer(1));
        w1=str2double(w1);
        w2=cell2mat(answer(2));
        w2=str2double(w2);
        grado=cell2mat(answer(3));
        grado=str2double(grado);
        sw=SAMPLE/deltaT; % Samplig rate en Frecuencia (Hz)
        Wn=[w1/(sw/2) w2/(sw/2)];
        [b, a]=butter(grado,Wn,'bandpass'); %Definicion del filtro

end
 
if filt == 2
        prompt = {'Desviacion estandard del filtro (sigma)?:','Tamano del filtro a cada lado?:'};
        dlg_title = '2.2 FILTRO GAUSSIANO';
        num_lines = 1;
        def = {'2','50'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);

        sigmaG=cell2mat(answer(1));
        sigmaG=str2double(sigmaG);
        sizeG=cell2mat(answer(2));
        sizeG=str2double(sizeG);
        x = linspace(-sizeG / 2, sizeG / 2, sizeG);
        gaussFilter = exp(-x .^ 2 / (2 * sigmaG ^ 2));
        gaussFilter = gaussFilter / sum (gaussFilter); % normalize

end
 
if filt == 3
        sw=SAMPLE/deltaT;
        
        prompt = {'Cual es la PRIMEA frecuencia del filtro?:','Cual es la SEGUNDA frecuencia del filtro?:','?Cual es la TERCERA frecuencia del filtro?:','?Cual es la CUARTA frecuencia del filtro:?','?Cual es el factor de atenuacion para la primera frecuencia stopband? (dB):','?Cual es el factor de atenuacion para cresta del filtro? (dB):','?Cual es el factor de atenuacion para la segunda frecuencia stopband? (dB):'};
        dlg_title = '2.3 FILTRO FIR Pasa Banda';
        num_lines = 1;
        def = {'1','2','8','9','60','1','60'};
        answer = inputdlg(prompt,dlg_title,num_lines,def,'on');

        Fstop1=cell2mat(answer(1));
        Fstop1 = (str2double(Fstop1))/(sw/2);

        Fpass1=cell2mat(answer(2));
        Fpass1 = (str2double(Fpass1))/(sw/2);

        Fpass2=cell2mat(answer(3));
        Fpass2 = (str2double(Fpass2))/(sw/2);

        Fstop2=cell2mat(answer(4));
        Fstop2 = (str2double(Fstop2))/(sw/2);

        Astop1=cell2mat(answer(5));
        Astop1=str2double(Astop1);

        Apass=cell2mat(answer(6));
        Apass=str2double(Apass);

        Astop2=cell2mat(answer(7));
        Astop2=str2double(Astop2);

        h = fdesign.bandpass('fst1,fp1,fp2,fst2,ast1,ap,ast2', Fstop1, Fpass1, ...
        Fpass2, Fstop2, Astop1, Apass, Astop2);
        Hd = design(h, 'equiripple');
end


disp(' ')
disp('Filtro Disenado.')
disp(' ')

%% PLOTS!!
%El codigo puede hacer 2 tipos de plots: Wiggle (traza negra) y Variable area (traza a colores)

UIControl_FontSize_bak = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
pPlot = menu('Seleccione un tipo de representacion (Tipo de Plot)','Wiggle','Wiggle+Variable Area (Negro/blanco)','Variable Area positivo (azul)','Variable Area negativo (rojo)');
set(0, 'DefaultUIControlFontSize', UIControl_FontSize_bak);

disp(' ')
disp('Tipo de Plot Seleccionado.')
disp(' ')


%% FIGURA

prompt = {'Offset minimo (xmin, km):','Offset maximo (xmax, km)','Tiempo reducido minimo (s)','Tiempo reducido maximo (s)'};
dlg_title = '3. Limites de la seccion';
num_lines = 1;
def = {'-10','560','-1','20'};
answer = inputdlg(prompt,dlg_title,num_lines,def,'on');

xmin=cell2mat(answer(1));
xmin=str2double(xmin);

xmax=cell2mat(answer(2));
xmax=str2double(xmax);

tminf=cell2mat(answer(3));
tminf=str2double(tminf);

tmin=0;

tmax=cell2mat(answer(4));
tmax=str2double(tmax);

fig=figure; hold on %Crear figura
set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperPosition', [0.1 0.1 11 8]);
ylim([tminf tmax])
xlim([xmin xmax])
xlabel('Distancia (km)')

if Vred== 0
    ylabel('T (s)')
else
    ylabel(strcat('T-X/',num2str(VV), '(s)'))
end

set(gca,'TickDir','out')
title('Disparo')
annotation(fig,'textbox',...
    [0.12998266897747 0.92867409948542 0.0303292894280763 0.0480274442538593],...
    'String',{A},...
    'LineStyle','none'); %Norte
annotation(fig,'textbox',...
    [0.882149046793761 0.92867409948542 0.0303292894280763 0.0480274442538593],...
    'String',{B},...
    'LineStyle','none'); %Sur


%% Lectura de datos

disp('********************************************************')
disp('*         Leyendo archivos, por favor, espere...       *')
disp('********************************************************')

Texans=zeros(1,length(D));

for k=1:length(D) %Hacer el proceso para todos los archivos de la carpeta
       
    %Leer el Kesimo archivo del SEGY a Matlab
    
    if ispc == 1
    fname=[Carpeta '\' D(k).name]; 
    else
    fname=[Carpeta '/' D(k).name];
    end
    
    if length(fname)>3 && strcmp(fname(end-2:end),'sgy')
       
        disp(fname)
        
        [Data,SegyTraceHeaders,SegyHeader]=ReadSegy(fname);
        
        texanID=str2double(fname(end-10:end-6)); %el serial del texan
        
        Texans(k)=texanID; %guardar los seriales de los Texans
        
     %verificar si el serial esta en la lista 
     for r=1:size(SERIALES,1)
        if texanID==SERIALES(r)            
        ix=coords(:,1)==texanID;
        lon=coords(ix,3);
        lat=coords(ix,2);
        DIST=coords(ix,7);
        
        if isempty(lon) || length(lon)>1; fclose all; continue; end %esta linea es porque algunas estaciones estan repetidas
        
        
        %OFFSET
       
        %Calcular las distancias        
        [offset, az]=distance(lat,lon,shotLat,shotLon);
        %Transformar de grados a km
        
        if resultD == 1
        offset=offset*Dnum;
        end
        if resultD==2
            offset=offset*Dnum;
        end
        if resultD ==3
            offset=DIST;
        end
            
        if lat>shotLat; offset=-offset; end % al norte del disparo, offset negativo.
        
               
        if offset>= xmin && offset <= xmax
            %TIME
            
            if Vred == 0 
                time=SegyHeader.time(1:deltaT:end);
            else
                time=SegyHeader.time(1:deltaT:end)-abs(offset)/Vred;
            end
                       
            %time=SegyHeader.time(1:deltaT:end)-abs(offset)/Vred;
            first=find(time<tmin,1,'first');
            last=find(time>tmax,1,'first');
      
            %Cortar info fuera de la ventana de tiempo
            if Vred == 0
                time=time(1:deltaT:last);
                Data=Data(1:deltaT:last);
            else
                time=time(first:deltaT:last);
                Data=Data(first:deltaT:last);
            end
        
            %PROCESAMIENTO DEL DATO
            %Remover la media
            Data=Data-mean(Data);
            %Remover tendecia lineal
            Data=detrend(Data,'linear');
            %Filtrar el dato con el filtro definido con anterioridad
            %Aplicamos el filtro cosine taper, se puede cambiar el radio
            %del filtro, por defecto 0.2 es un buen valor
            ctr = 0.1;
            Data=Data.*tukeywin(size(Data,1),ctr);
        
            if filt == 1
                Data = filter(b,a,Data);
            end
            if filt == 2
                Data = conv(Data, gaussFilter, 'same');
            end
            if filt == 3
                Data = filter(Hd,Data);
            end
            if filt == 3
                disp(' ')
                disp('El dato no ha sido filtrado (solo preprocesado).')
                disp(' ')
            end
                
            try
                Data=Data/max(abs(Data))*fac; %porsiacaso hay un error
            catch ME
                keyboard
            end
        
            shg %mostrar la seccion siendo generada              
        
            %Wiggle
            if pPlot==1
                plot(Data+offset,time','k', 'LineWidth',0.5)
            end
        
            %Wiggle+variable area (Rojo/Azul)
            if pPlot==2
                W1=subplus(Data);
                W2=-subplus(-Data);
                 %Aqui se cambian los colores donde dice 'b' y 'r', usa 'k' para
                 %negro y 'w' para blanco
                patch(W1+offset,time','k', 'LineWidth',0.01)
                %patch(w2(1:deltaT:end),time','w', 'LineWidth',0.01)
                plot(W2+offset,time','k', 'LineWidth',0.01)
            end
         
            %Variable area positivo (Negro)
            if pPlot==3
                W1=subplus(Data);
                patch(W1+offset,time','b', 'LineWidth',0.01)
           
            end
        
            %Variable area Negativo (negro)
            if pPlot==4
                W2=-subplus(-Data);
                patch(W2+offset,time','r', 'LineWidth',0.01)
            end
        
            text(offset,tmax+0.1,[' ',num2str(texanID)], 'FontSize',0.5, 'Color', [1,0,0], 'Rotation', 90)
        
            fclose all;
        
        end
        end
    end            
    end
end

%LEGENDA

Texans=Texans(4:end); %Eliminar los valores vacios en la Matrix de texans
legend(num2str(Texans(:))) %Asignar el serial de cada texan a la traza que corresponde
legend('toggle') %ocultar la legenda para facilitar la revisi?n

%% Limpiaza de Memoria (ayuda a la Velocidad)

UIControl_FontSize_bak = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
clean = menu('Desea limpiar la memoria? (limpiar la memoria ayuda al desempeno del codigo)','SI','NO');
set(0, 'DefaultUIControlFontSize', UIControl_FontSize_bak);

if clean == 1
    clearvars -except Vred fig
    disp(' ')
    disp('Memoria Limpiada.')
    disp(' ')
else
    disp(' ')
    disp('Memoria NO Limpiada.')
    disp(' ')
end
%clear clean

%% Eliminar Trazas

UIControl_FontSize_bak = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
result = menu('?Desea Eliminar trazas de la seccion?','SI','NO');
set(0, 'DefaultUIControlFontSize', UIControl_FontSize_bak);

if result == 1
     disp(' ')
     disp('********************************************************************************')
     disp('*           COMO USAR EL MODULO FOGURE TOOLBOX PARA ELIMINAR TRAZAS            *');
     disp('* 1. Se habre el modulo para editar imagenes                                   *');
     disp('* 2. Haga click sobre la traza que desea eliminar (puede hacer zoom, pan, etc) *');
     disp('* 3. Precione Suprimir, Delete o Backspace                                     *');
     disp('* 4. Cierre el modulo de FIGURE TOOLBOX (Hide Plot Toolbox)                    *');
     disp('********************************************************************************')
     plottools
else
    disp(' ')
    disp('Ninguna Traza Eliminada.')
    disp(' ')
end
 
%% CARGAR Picks anteriores

UIControl_FontSize_bak = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
result = menu('Desea cargar los Picks ANTERIORES?','SI','NO');
set(0, 'DefaultUIControlFontSize', UIControl_FontSize_bak);

 if result == 1
     disp(' ')
     disp('***************************************')
     disp('*           Cargando Picks            *');
     disp('***************************************')
     %falta a?adir prompt y montar las cosas en la seccion
    try 
    load Picks/Pg.txt
    Pga=Pg;
    
    if Vred == 0 
       plot(Pga(:,1),Pga(:,2),'+r','MarkerSize',7,'LineWidth',2.0)
    else
       plot(Pga(:,1),Pga(:,2)-(abs(Pga(:,1))./Vred),'+r','MarkerSize',7,'LineWidth',2.0)
    end
    
    catch error       
    disp('No Pg picks to load.');
    disp('Execution will continue.');
    end
    
    try
    load Picks/PmP.txt
    PmPa=PmP;
    
    if Vred == 0 
       plot(PmPa(:,1),PmPa(:,2),'+b','MarkerSize',7,'LineWidth',2.0)
    else
       plot(PmPa(:,1),PmPa(:,2)-(abs(PmPa(:,1))./Vred),'+b','MarkerSize',7,'LineWidth',2.0)
    end
    
    catch error
    disp('No PmP picks to load.');
    disp('Execution will continue.');
    end
    
    try
    load Picks/Pn.txt
    Pna=Pn;
    
    if Vred == 0 
       plot(Pna(:,1),Pna(:,2),'+b','MarkerSize',7,'LineWidth',2.0)
    else
       plot(Pna(:,1),Pna(:,2)-(abs(Pna(:,1))./Vred),'+g','MarkerSize',7,'LineWidth',2.0)
    end
    
    
    catch error
    disp('No Pn picks to load.');
    disp('Execution will continue.');
    end
    
    try
    load Picks/Pi.txt
    Pia=Pi;
    
    if Vred == 0 
       plot(Pia(:,1),Pia(:,2),'+b','MarkerSize',7,'LineWidth',2.0)
    else
       plot(Pia(:,1),Pia(:,2)-(abs(Pia(:,1))./Vred),'+m','MarkerSize',7,'LineWidth',2.0)
    end
    
    
    
    catch error
    disp('No Pn picks to load.');
    disp('Execution will continue.');
    end
    clear Pg PmP Pn Pi
  end

%% Dibujar lineas gu?as
clear result
result=1;
while result < 2
    
UIControl_FontSize_bak = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
result = menu('Desea Dibujar lineas guias?','SI','CONTINUAR');
set(0, 'DefaultUIControlFontSize', UIControl_FontSize_bak);    


if result == 1
     disp(' ')
     disp('********************************************************************')
     disp('*               COMO USAR EL MODULO DE Dibujo (N veces)            *');
     disp('* 1. Click izquierdo par selecionar un punto                       *');
     disp('* 2. Presione Enter o Rerturn para terminar (presiones N veces)    *');
     disp('* 3. Se dibuja la linea en color azul claro                        *');
     disp('********************************************************************')
    

     [xl,yl]=ginput;
     plot(xl,yl,'c','LineWidth',2.0)
   
    
else
     disp(' ')
     disp('Ninguna linea guia dibujada.')
     disp(' ')
end
end
     

 
 %% Hacer picks para las distintas fases

clear result
result=1;
while result < 5
    
UIControl_FontSize_bak = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
result = menu('Desea Hacer los picks de las fases?','Pg','PmP','Pn','Pi','CONTINUAR'); 
set(0, 'DefaultUIControlFontSize', UIControl_FontSize_bak);

% Hacer picks para Pg
 if result == 1
     disp(' ')
     disp('**********************************************************************')
     disp('*               COMO USAR EL MODULO DE SELECCION (Pg)                *');
     disp('* 1. Click izquierdo para hacer Zoom in                              *');
     disp('* 2. Doble Click izquierdo para regresar a la vista original         *');
     disp('* 3. Click derecho para guardar el Pick                              *');
     disp('* 4. Presione Delete para eliminar el ultimo punto marcado           *');
     disp('* 5. Presione Enter para salir del modo de seleccion (solo en zoom)  *');
     disp('* 6. Al salir del Menu de seleccion se regresa a la vista original   *');
     disp('**********************************************************************')
     
     [xPg,yPg]=ginput2('.r','MarkerSize',15,'LineWidth',4.0);
     plot(xPg,yPg,'.r','MarkerSize',15,'LineWidth',4.0)
     
     if Vred == 0
        Pg=[xPg yPg];
     else
        Pg=[xPg yPg+(abs(xPg)/Vred)];
     end
         
     try
     Pg=[Pg; Pga];
     catch error
     disp('No Previous picks to save.');
     end
     
     dlmwrite('Pg.txt',Pg,' ')
 end

% Hacer picks para PmP
 if result == 2
     disp(' ')
     disp('**********************************************************************')
     disp('*               COMO USAR EL MODULO DE SELECCION (PmP)                *');
     disp('* 1. Click izquierdo para hacer Zoom in                              *');
     disp('* 2. Doble Click izquierdo para regresar a la vista original         *');
     disp('* 3. Click derecho para guardar el Pick                              *');
     disp('* 4. Presione Delete para eliminar el ultimo punto marcado           *');
     disp('* 5. Presione Enter para salir del modo de seleccion (solo en zoom)  *');
     disp('* 6. Al salir del Menu de seleccion se regresa a la vista original   *');
     disp('**********************************************************************')
     
     [xPmP,yPmP]=ginput2('.b','MarkerSize',10,'LineWidth',4.0);
     plot(xPmP,yPmP,'.b','MarkerSize',10,'LineWidth',4.0);
     
     if Vred == 0
        PmP=[xPmP yPmP];
     else
        PmP=[xPmP yPmP+(abs(xPmP)/Vred)];
     end
    
     try
     PmP=[PmP; PmPa];
     catch error
     disp('No Previous picks to save.');
     end
     
     
     dlmwrite('PmP.txt',PmP,' ')
    
     
 end
 
% Hacer picks para Pn
 if result == 3
     disp(' ')
     disp('**********************************************************************')
     disp('*               COMO USAR EL MODULO DE SELECCION (Pn)                *');
     disp('* 1. Click izquierdo para hacer Zoom in                              *');
     disp('* 2. Doble Click izquierdo para regresar a la vista original         *');
     disp('* 3. Click derecho para guardar el Pick                              *');
     disp('* 4. Presione Delete para eliminar el ultimo punto marcado           *');
     disp('* 5. Presione Enter para salir del modo de seleccion (solo en zoom)  *');
     disp('* 6. Al salir del Menu de seleccion se regresa a la vista original   *');
     disp('**********************************************************************')
     
     [xPn,yPn]=ginput2('.g','MarkerSize',10,'LineWidth',4.0);
     plot(xPn,yPn,'.g','MarkerSize',10,'LineWidth',4.0);
     
     if Vred == 0
        Pn=[xPn yPn];
     else
        Pn=[xPn yPn+(abs(xPn)/Vred)];
     end
     
     try
     Pn=[Pn; Pna];
     catch error
     disp('No Previous picks to save.');
     end
     
     
     dlmwrite('Pn.txt',Pn,' ')
 end


% Hacer picks para Pi (fase intracortical)
if result == 4
     disp(' ')
     disp('**********************************************************************')
     disp('*               COMO USAR EL MODULO DE SELECCION (Pi)                *');
     disp('* 1. Click izquierdo para hacer Zoom in                              *');
     disp('* 2. Doble Click izquierdo para regresar a la vista original         *');
     disp('* 3. Click derecho para guardar el Pick                              *');
     disp('* 4. Presione Delete para eliminar el ultimo punto marcado           *');
     disp('* 5. Presione Enter para salir del modo de seleccion (solo en zoom)  *');
     disp('* 6. Al salir del Menu de seleccion se regresa a la vista original   *');
     disp('**********************************************************************')
     
     [xPi,yPi]=ginput2('.m','MarkerSize',10,'LineWidth',4.0);
     plot(xPi,yPi,'.m','MarkerSize',10,'LineWidth',4.0);
     
        
     if Vred == 0
        Pi=[xPi yPi];
     else
        Pi=[xPi yPi+(abs(xPi)/Vred)];
     end
     
     try
     Pi=[Pi; Pia];
     catch error
     disp('No Previous picks to save.');
     end
     
     
     dlmwrite('Pi.txt',Pi,' ')
end
end 

%% Exportar Seccion
%
disp(' ')
UIControl_FontSize_bak = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
result = menu('?Desea exportar la seccion y los datos?','SI','NO');
set(0, 'DefaultUIControlFontSize', UIControl_FontSize_bak);

if result == 1
     print(fig, '-dpsc','Seccion.ps')
end

%Guardar los Picks en una carpeta
mkdir Picks

try
copyfile('Pg.txt','Picks/')
catch error
disp('No Existe el archivo Pg.txt');
end

try
copyfile('PmP.txt','Picks/')
catch error
disp('No Existe el archivo PmP.txt');
end

try
copyfile('Pn.txt','Picks/')
catch error
disp('No Existe el archivo Pn.txt');
end

try
copyfile('Pi.txt','Picks/')
catch error
disp('No Existe el archivo Pi.txt');
end

%% Rayinvr

disp(' ')

UIControl_FontSize_bak = get(0, 'DefaultUIControlFontSize');
set(0, 'DefaultUIControlFontSize', 14);
result = menu('?Desea exportar el archivo T.in para RAYINVR?','SI','NO');
set(0, 'DefaultUIControlFontSize', UIControl_FontSize_bak);


if result == 1
     
prompt = {'?Posicion del Disparo (km)?:','?Flag para la Pg?:','?Error para la Pg?:','?Flag para la PmP?:','?Error para la PmP?:', '?Flag para la Pn?:','?Error para la Pn?:', '?Flag para la Pi?:','?Error para la Pi?:'};
dlg_title = 'Generar Archivo T.in para RAYINVR';
num_lines = 1;
def = {'20','1','0.75','4','1.12','5','1.25','3','1.5',};
answer = inputdlg(prompt,dlg_title,num_lines,def,'on');
    
DIST=cell2mat(answer(1));
DIST=str2double(DIST);

FlagPg=cell2mat(answer(2));
FlagPg=str2double(FlagPg);

FlagPmP=cell2mat(answer(4));
FlagPmP=str2double(FlagPmP);

FlagPn=cell2mat(answer(6));
FlagPn=str2double(FlagPn);

FlagPi=cell2mat(answer(8));
FlagPi=str2double(FlagPi);

ePg=cell2mat(answer(3));
ePg=str2double(ePg);

ePmP=cell2mat(answer(5));
ePmP=str2double(ePmP);

ePn=cell2mat(answer(7));
ePn=str2double(ePn);

ePi=cell2mat(answer(9));
ePi=str2double(ePi);

clear Pg Pga PmP PmPa Pn Pna Pi Pia

try
load Pg.txt
load PmP.txt
load Pn.txt
load Pi.txt
catch error
end

RAYINVR=[0.000 DIST 0.000 0];

try
RAYINVR=[RAYINVR; Pg(:,1)+DIST Pg(:,2) ones(size(Pg,1),1)*ePg ones(size(Pg,1),1)*FlagPg];   
catch error
end

try
RAYINVR=[RAYINVR; PmP(:,1)+DIST PmP(:,2) ones(size(PmP,1),1)*ePmP ones(size(PmP,1),1)*FlagPmP];   
catch error
end

try
RAYINVR=[RAYINVR; Pn(:,1)+DIST Pn(:,2) ones(size(Pn,1),1)*ePn ones(size(Pn,1),1)*FlagPn];   
catch error
end

try
RAYINVR=[RAYINVR; Pi(:,1)+DIST Pi(:,2) ones(size(Pi,1),1)*ePi ones(size(Pi,1),1)*FlagPi];   
catch error
end

RAYINVR=[RAYINVR; 0.000 0.000 0.000 -1];

dlmwrite('T.in',RAYINVR,' ')
   
end


%% FIN

disp('*****************************************************')
disp('*         LISTO! El programa ha terminado.          *')
disp('*         Los archivos estan en la carpeta.         *')
disp('*****************************************************')
