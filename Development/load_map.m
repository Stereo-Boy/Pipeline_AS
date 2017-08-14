%This script is used to quickly operate a mrVista gray window with a given co threshold.
%It will close and clean everything restart, load map into gray parameter map slot and 
% in the co slot (divided by 100), open the meshes and project the data on the meshes

%VOLUME{1} = meshDelete(VOLUME{1}, inf);  %remove previous meshes
close all
clear all
 mrVista
 open3ViewWindow

thisMap = '009a_full_EA_INP - COR.mat';
[a, b, ext] = fileparts(thisMap);
if not(strcmp(ext,'.mat')); thisMap=[thisMap,'.mat'];end    
disp(thisMap)
meshL = 'lh_inflated_3L.mat'
meshR = 'rh_inflated_3L.mat'
mapFile=fullfile(cd,'mvpa',thisMap);
meshFileL=fullfile(cd,'Mesh',meshL);
meshFileR=fullfile(cd,'Mesh',meshR);

load(mapFile,'map')
if numel(size(map{1}))>2 %this is not a gray vector but an inplane map
    inplaneFlag=1;
    %first load map in the inplane
    INPLANE{1} = loadParameterMap(INPLANE{1},mapFile); %load parameter map
    INPLANE{1}= refreshScreen(INPLANE{1}); 
    %in that case, the co field does not work...
    %INPLANE{1} = loadCoherenceMap(INPLANE{1}, mapFile, 2); %load into co field after /100 and take abs
    %then convert the map in the gray
    ip = checkSelectedInplane; ip2volAllParMaps(ip, VOLUME{1}, 'linear'); clear ip;
else
   % this is already a gray map
    inplaneFlag=0;
    VOLUME{1} = loadParameterMap(VOLUME{1},mapFile); %load parameter map
    VOLUME{1}= refreshScreen(VOLUME{1}); 
    VOLUME{1} = loadCoherenceMap(VOLUME{1}, mapFile, 2); %load into co field after /100 and take abs
    VOLUME{1}= refreshScreen(VOLUME{1}); 
end

ui = viewGet(VOLUME{1},'ui');
if inplaneFlag==1;
    VOLUME{1}  = setSlider(VOLUME{1},ui.mapWinMin,0.14);
    VOLUME{1} = setSlider(VOLUME{1},ui.mapWinMin,14);
end
VOLUME{1}.ui.mapMode=setColormap(VOLUME{1}.ui.mapMode, 'blueredyellowCmap'); 
if inplaneFlag==0
    VOLUME{1}= setSlider(VOLUME{1},ui.cothresh,0.14);
    
end
ui.mapMode.clipMode = [-50,50];
VOLUME{1} = viewSet(VOLUME{1},'mapMode',ui.mapMode);
VOLUME{1}=refreshScreen(VOLUME{1}, 1);
 
VOLUME{1} = meshLoad(VOLUME{1}, meshFileL, 1); %display mesh and load
VOLUME{1} = meshLoad(VOLUME{1}, meshFileR, 1); %display mesh and load
prefs = getpref('mesh') %change pref of display for mesh
prefs.layerMapMode= 'all';
prefs.overlayLayerMapMode= 'absval';
setpref('mesh', 'layerMapMode', prefs.layerMapMode);
setpref('mesh', 'overlayLayerMapMode', prefs.overlayLayerMapMode);
VOLUME{1} = meshUpdateAll(VOLUME{1}); %update all meshes
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 1); 
meshRetrieveSettings(viewGet(VOLUME{1}, 'CurMesh'), 'Lateral_Left'); 
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 2); 
meshRetrieveSettings(viewGet(VOLUME{1}, 'CurMesh'), 'Lateral_Right'); 
input('Take a printscreen snapshot then press a key')
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 1); 
meshRetrieveSettings(viewGet(VOLUME{1}, 'CurMesh'), 'Medial_Left'); 
VOLUME{1} = viewSet(VOLUME{1}, 'CurMeshNum', 2); 
meshRetrieveSettings(viewGet(VOLUME{1}, 'CurMesh'), 'Medial_Right'); 