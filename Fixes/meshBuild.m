function [vw,newMeshNum] = meshBuild(vw,hemisphere,numGrayLayers)
% Build a 3D mesh for visualization and analysis
%
%   [vw,newMeshNum] = meshBuild(vw,[hemisphere]);
%
%  Using mrVista data, build a mesh, save it in a file in the anatomy
%  directory, and add the mesh to the 3D Control Window pull down
%  options.  
%
% vw:          A VISTASOFT view structure
% hemisphere:  left, right or both.  Default: left
% numGrayLayers: number of gray layers to create
%
% A mrMesh window is opened as well, showing the computed mesh.
%
% Example:
%    [VOLUME{1},newMeshNum] = meshBuild(VOLUME{1},'left');
%    VOLUME{1} = viewSet(VOLUME{1},'currentmeshn',newMeshNum);
%
% See also:  meshBuildFromClass, meshBuildFromNiftiClass, meshSmooth,
%            meshColor 
%
% 11/05 ras: also saves mesh path.
%
% (c) Stanford VISTA Team 2008

% Programming TODO.  Check this!
%   We have (or had?) trouble for building 'both' meshes.  We need a new
%   procedure.

% Be sure anatomy is loaded (we need it for the mmPerVox field)
if isempty(vw.anat), vw = loadAnat(vw); end
if ieNotDefined('hemisphere'), hemisphere = 'left'; end

newMeshNum = viewGet(vw,'nmesh') + 1;

% Parameters we establish in this routine
[meshName,numGrayLayers,hemiNum] = readParams(newMeshNum,hemisphere,numGrayLayers);
if isempty(meshName), newMeshNum = newMeshNum - 1; return; end   % User pressed cancel.

% Load left, right, or both hemispheres.  
if (hemiNum==1)
    [voxels,vw] = meshGetWhite(vw, 'left', numGrayLayers);
elseif (hemiNum==2)
    [voxels,vw] = meshGetWhite(vw, 'right', numGrayLayers);
elseif (hemiNum == 0)
    [voxels,vw] = meshGetWhite(vw, 'left', numGrayLayers);
    [voxels,vw] = meshGetWhite(vw, 'right', numGrayLayers,voxels);
end

% We build a smoothed (mesh) and an unsmoothed mesh (tenseMesh) with these calls
[newMesh, tenseMesh] = mrmBuild(voxels,viewGet(vw,'mmPerVox'),1);

% Must have a name
newMesh   = meshSet(newMesh,'name',meshName);
tenseMesh = meshSet(tenseMesh,'name',sprintf('%s-tense',meshName));

% waitbar(0.65,wbar,sprintf('meshBuild: Unsmoothed mesh vertex to gray mapping'));
initVertices = meshGet(tenseMesh,'vertices');
newMesh = meshSet(newMesh,'initialvertices',initVertices);
vertexGrayMap = mrmMapVerticesToGray(...
    initVertices, ...
    viewGet(vw,'nodes'), ...
    viewGet(vw,'mmPerVox'),...
    viewGet(vw,'edges'));

newMesh = meshSet(newMesh,'vertexGrayMap',vertexGrayMap);
newMesh = meshSet(newMesh,'name',meshName); 
newMesh = meshSet(newMesh,'nGrayLayers',numGrayLayers);

% Now refresh the UI
vw = viewSet(vw,'add and select mesh',newMesh);

return;

%---------------------------------------
function classFile = verifyClassFile(vw,hemisphere)

classFile =  viewGet(vw,'classFileName',hemisphere);
return;

%---------------------------------------
function voxels = classExtractWhite(voxels,data,voi,whiteValue)
%

% ras 05/07: the indexing of data seems off to me -- is this correct?
voxels(voi(1):voi(2), voi(3):voi(4), voi(5):voi(6)) = ...
    voxels(voi(1):voi(2), voi(3):voi(4), voi(5):voi(6)) ...
    | (data(voi(1):voi(2), voi(3):voi(4), voi(5):voi(6)) == whiteValue);

return;


%----------------------------------------
function [meshName,numGrayLayers,hemiNum,alpha,restrictVOI,relaxIterations] = ...
    readParams(newMeshNum,hemisphere,numGrayLayers)
%
%  readParams
%
% Internal routine to read the parameters for meshBuild
% 
meshName = sprintf('%sSmooth',hemisphere);
numGrayLayers = 0;
switch hemisphere
    case 'left'
        hemiNum = 1;
    case 'right'
        hemiNum = 2;
    case 'both'
        hemiNum = 0;
end

% transparency level (transparency is off by default, but if it gets turned
% on, this alpha parameter will have an effect).
alpha = 200;
restrictVOI = 1;
relaxIterations = 0.2;
return;


%---------------------------------
function [voxels,vw] = meshGetWhite(vw, hemiName, numGrayLayers, voxels)
%
%
%

if ieNotDefined('vw'), error('You must send in a volume vw'); end
if ieNotDefined('hemiName'), error('You must define right,left or both'); end
if ieNotDefined('numGrayLayers'), numGrayLayers = 0; end

classFile = verifyClassFile(vw,hemiName);
if isempty(classFile),
    close(wbar); newMeshNum = -1;
    voxels = [];
    return;
end
classFileParam = [hemiName,'ClassFile'];
vw       = viewSet(vw,classFileParam,classFile);

classData = viewGet(vw,'classdata',hemiName);
if ieNotDefined('voxels'),
    voxelsOld = uint8(zeros(classData.header.xsize, ...
        classData.header.ysize, ...
        classData.header.zsize));
else
    voxelsOld = voxels;
end
voxels = zeros(classData.header.xsize, ...
        classData.header.ysize, ...
        classData.header.zsize);

% Restrict the white matter volume to a size equal to the ROI in which it
% was selected 
voxels = classExtractWhite(voxels,...
    classData.data,classData.header.voi,classData.type.white);

% Add the gray matter
if(numGrayLayers>0)
    
    [nodes,edges,classData] = mrgGrowGray(classData,numGrayLayers);
    voxels = ...
        uint8( (classData.data == classData.type.white) | ...
        (classData.data == classData.type.gray));
end

voxels = uint8(voxels | voxelsOld);

return;
