%This script is used to quickly operate a mrVista gray window with a given co threshold.
%It will close and clean everything restart, load map into gray parameter map slot and 
% in the co slot (divided by 100), open the meshes and project the data on the meshes

%VOLUME{1} = meshDelete(VOLUME{1}, inf);  %remove previous meshes
close all
clear all
 mrVista
 open3ViewWindow

map = '007 full_glm ANT ld 0.14.matt'
meshL = 'lh_inflated_3L.mat'
meshR = 'rh_inflated_3L.mat'
mapFile=fullfile(cd,'mvpa',map);
meshFileL=fullfile(cd,'Mesh',meshL);
meshFileR=fullfile(cd,'Mesh',meshR);

 VOLUME{1} = loadParameterMap(VOLUME{1},mapFile); %load parameter map
 VOLUME{1}= refreshScreen(VOLUME{1}); 
 VOLUME{1} = loadCoherenceMap(VOLUME{1}, mapFile, 2); %load into co field after /100 and take abs


 
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