// -----JS CODE----- 

//@input Asset.Material Material_Simulate
//@input Asset.Material Material_Feedback
//@input Asset.Material Material_Render

// Variables set by NGS
var MAT_SIMULATE;
var MAT_RENDER;
var VFX_OBJECT;
var INSTANCE_COUNT = 1500;
var TEXEL_COUNT = 6;
var DIMENSIONS = new vec2(2046.0, 5.0);
var DEBUG_PRINT = false;

//////////////////////////////////////////////////////////////
// VFX Manager
//////////////////////////////////////////////////////////////
function VfxObject(simMaterial, renderMaterial, texelCount, instanceCount) {
	this.simMaterial = simMaterial;
	this.simMaterialPass = simMaterial.mainPass;
	this.renderMaterial = renderMaterial;
	this.renderMaterialPass = renderMaterial.mainPass;
	this.texelCount = texelCount;
	this.instanceCount = instanceCount;
	this.meshVisual;
	this.passId = 0;
	this.objectId = 0;
}

function VfxPass(cameraObject, camera, layer, renderTargetsA, renderTargetsB, resizePass) {
	this.cameraObject = cameraObject;
	this.camera = camera;
	this.cameraTargets = camera.colorRenderTargets;
	this.layer = layer;
	this.currentRT = renderTargetsA;
	this.previousRT = renderTargetsB;
	this.dimensions = new vec2(1,1);
	this.resizePass = resizePass;
	this.currentOffset = new vec2(0.0, 0.0);
	this.vfxObjects = [];
	this.isNew = true;
	this.isDirty = false;
}

function VfxManager(sceneObject, resizeMaterial) {
	this.passes = [];
	this.frame = 0;
	this.sceneObject = sceneObject;
	this.resizeMaterial = resizeMaterial;
	this.quadMesh = this.createScreenQuad();
	this.newVfxObjects = [];
	
	// Create the first pass
	this.createPass();
	
	if (DEBUG_PRINT) print("Created VFX Manager. Debug print enabled.")
}


//////////////////////////////////////////////////////////////
// Register
//////////////////////////////////////////////////////////////
VfxManager.prototype.register = function(simMaterial, renderMaterial, texelCount, instanceCount) {
	
	// Check if the VFX has already been registered. Lack of material instancing prevents unique instances of the same asset. 
	for (var i = 0; i < this.newVfxObjects.length; i++) {
		if (simMaterial.isSame(this.newVfxObjects[i].simMaterial)) {
			if (DEBUG_PRINT) print("Same vfx found. Not registering");
			return this.newVfxObjects[i];
		}
	}
	
	for (var i = 0; i < this.passes.length; i++) {
		var pass = this.passes[i];
		for (var j = 0; j < pass.vfxObjects.length; j++) {
			if (!isNull(pass.vfxObjects[j].simMaterial) && simMaterial.isSame(pass.vfxObjects[j].simMaterial)) {
				if (DEBUG_PRINT) print("Same vfx found. Not registering");
				return pass.vfxObjects[j];
			}
		}
	}
	
	// Accumulate the new VFX, complete registration in Late Update
	var vfx = new VfxObject(simMaterial, renderMaterial, texelCount, instanceCount);
	this.newVfxObjects.push(vfx);
	
	return vfx;
}


//////////////////////////////////////////////////////////////
// We dont fully destroy the object in order to hold onto the material
////////////////////////////////////////////////////////////// 
VfxManager.prototype.destroy = function(passId, objectId) {
	var meshVisual = this.passes[passId].vfxObjects[objectId].meshVisual;
	meshVisual.destroy();
}


//////////////////////////////////////////////////////////////
// Add registered VFX
//////////////////////////////////////////////////////////////                
VfxManager.prototype.addRegisteredVfx = function() {
	
	// This is where we add newly registered VFX to the manager and calculate the new atlas resolution.
	// Called in LateUpdate to accumulate potentially many VFX that were enabled at once,
	// and ensure that the resize pass is only executed once.
	
	if (this.newVfxObjects.length > 0) {
		
		// Update the resolution of the pass
		for (var i = 0; i < this.newVfxObjects.length; i++) {
			var newVfx = this.newVfxObjects[i];
			var pass = this.passes[this.passes.length-1];
			var offsets = this.getNewOffset(pass, newVfx);
			
			pass.isDirty = true;
			
			// Create a new pass if the new vfx system makes the current one too big
			// Do not create a new pass if the current one is empty with target dimensions of (1,1)
			if (offsets.newOffset2d.y > 2047 && pass.dimensions.x > 1 && pass.dimensions.y > 1) {
				pass = this.createPass();
				offsets = this.getNewOffset(pass, newVfx);
			}
			
			pass.currentOffset.x = offsets.correctedOffset1d % offsets.targetWidth;
			pass.currentOffset.y = Math.floor(offsets.correctedOffset1d / offsets.targetWidth);
			
			// set the new pass dimension property. wait to resize the RT's
			pass.dimensions = new vec2(2048.0, Math.min(2048.0, Math.max(pass.currentOffset.y + 1, 1.0)));
			
			// add the new vfx
			pass.vfxObjects.push(newVfx);
			this.setupMaterialTextures(newVfx.simMaterial, pass.previousRT);
			this.setupMaterialTextures(newVfx.renderMaterial, pass.currentRT);
			
			// create the mesh visual for the new vfx system
			newVfx.meshVisual = pass.cameraObject.createComponent('RenderMeshVisual');
			newVfx.meshVisual.mesh = this.quadMesh.getMesh();
			newVfx.meshVisual.mainMaterial = newVfx.simMaterial;
			newVfx.passId = this.passes.length-1;
			newVfx.objectId = pass.vfxObjects.length-1;
			
			// set these uniforms once
			newVfx.simMaterialPass.vfxOffsetInstances = offsets.offsetInstances;
			newVfx.simMaterialPass.ssTARGET_WIDTH = offsets.targetWidth;
			newVfx.simMaterialPass.ssTARGET_WIDTH_INT = offsets.targetWidth;
			newVfx.renderMaterialPass.vfxOffsetInstances = offsets.offsetInstances;
			newVfx.renderMaterialPass.ssTARGET_WIDTH = offsets.targetWidth;
			newVfx.renderMaterialPass.ssTARGET_WIDTH_INT = offsets.targetWidth;
			
			if (DEBUG_PRINT) {
				print("//// NUM " + i.toString());
				print("instance count: " + newVfx.instanceCount);
				print("texel count: " + newVfx.texelCount);
				print("offset instances: " + offsets.offsetInstances);
				print("offset 1d: " + offsets.correctedOffset1d);
				print("offset 2d: " + pass.currentOffset);
			}
			
		}//newVfxObjects
		
		
		// Resize the pass render targets or enable the resize pass
		for (var i = 0; i < this.passes.length; i++) {
			var pass = this.passes[i];
			
			if (pass.isNew) {
				for (var j = 0; j < 4; j++) {
					pass.currentRT[j].control.resolution = pass.dimensions;
					pass.previousRT[j].control.resolution = pass.dimensions;
				}
				pass.isNew = false;
			}
			else if (pass.isDirty) {
				this.enableResizePass(pass);
			}
			
			// Update all materials in the pass with new resolution
			this.setNewResolution(pass);
			pass.isDirty = false;
			
			if (DEBUG_PRINT) print("Pass " + i.toString() + " res: " + pass.dimensions);
		}
		
		// Empty the temp array
		this.newVfxObjects.length = 0;
	}
	
	return;
	
}    


//////////////////////////////////////////////////////////////
// Get new offset
//////////////////////////////////////////////////////////////     
VfxManager.prototype.getNewOffset = function(pass, newVfx) {
	// Get the splat dimensions of the new vfx
	var particleCount2d = new vec2(Math.floor(2048.0 / newVfx.texelCount), Math.ceil(newVfx.instanceCount * newVfx.texelCount / 2048.0));
	var particleCount1d = newVfx.instanceCount * newVfx.texelCount;
	var targetWidth = particleCount2d.x * newVfx.texelCount;
	
	// Get the current offset
	var offsetPixels = new vec2(pass.currentOffset.x, pass.currentOffset.y);
	var offset1d = offsetPixels.x + (2048.0 * Math.max(offsetPixels.y, 0.0));
	var correctedOffset1d = offset1d;
	var offsetInstances = 0;
	
	// Quantize the old offset to this system's texel count
	// convert to 1d, quantize, divide by instanceCount
	// send as 1d instanceId offset to slide the next system	
	if (pass.vfxObjects.length > 0) {
		correctedOffset1d = Math.ceil(offset1d / newVfx.texelCount) * newVfx.texelCount;
		offsetInstances = correctedOffset1d / newVfx.texelCount;
	}
	correctedOffset1d += particleCount1d;
	
	newOffset2d = new vec2(0,0);
	newOffset2d.x = correctedOffset1d % targetWidth;
	newOffset2d.y = Math.ceil(correctedOffset1d / targetWidth);	
	
	//@TODO: choose better names for these
	return {
		"offsetInstances":offsetInstances,
		"correctedOffset1d":correctedOffset1d,
		"newOffset2d":newOffset2d,
		"targetWidth":targetWidth,
		"particleCount2d":particleCount2d
	}
	
}


VfxManager.prototype.setNewResolution = function(pass) {
	for (var i = 0; i < pass.vfxObjects.length; i++) {
		if (!isNull(pass.vfxObjects[i].renderMaterial)) {
			var sim = pass.vfxObjects[i].simMaterial.mainPass;
			var render = pass.vfxObjects[i].renderMaterial.mainPass;
			
			sim.ssTARGET_SIZE_INT = pass.dimensions;
			sim.ssTARGET_SIZE_FLOAT = pass.dimensions;
			sim.ssTARGET_SIZE_INT = pass.dimensions;
			sim.ssTARGET_SIZE_FLOAT = pass.dimensions;
			
			render.ssTARGET_SIZE_INT = pass.dimensions;
			render.ssTARGET_SIZE_FLOAT = pass.dimensions;
			render.ssTARGET_SIZE_INT = pass.dimensions;
			render.ssTARGET_SIZE_FLOAT = pass.dimensions;		
		}
	}
}

//////////////////////////////////////////////////////////////
// Resize Atlas at Runtime
//////////////////////////////////////////////////////////////
VfxManager.prototype.enableResizePass = function(pass) {
	
	var newResolution = pass.dimensions;
	var oldResolution = pass.currentRT[0].control.resolution;
	
	// Enable the resizing camera
	pass.resizePass.resolution = newResolution;
	pass.resizePass.triggerFrame = this.frame;
	pass.resizePass.sceneObject.enabled = true;
	
	var resizePassMaterialPass = pass.resizePass.material.mainPass;
	resizePassMaterialPass.oldRtSizeInv = new vec2(1.0/oldResolution.x, 1.0/oldResolution.y);
	resizePassMaterialPass.newRtSizeInv = new vec2(1.0/newResolution.x, 1.0/newResolution.y);
	
	if (DEBUG_PRINT) print("Enabled resize pass");
}

VfxManager.prototype.disableResizePass = function(pass) {
	// Disable the resize camera and swap its RT's
	pass.resizePass.sceneObject.enabled = false;
	[pass.resizePass.renderTargets, pass.previousRT] = [pass.previousRT, pass.resizePass.renderTargets];
	this.setCameraTargets(pass.resizePass.cameraTargets, pass.resizePass.renderTargets);      
	if (DEBUG_PRINT) print("Disabled resize pass")
}      


VfxManager.prototype.updateResizePass = function(pass) {
	// Resize the render targets we are rendering into
	for (var i = 0; i < 4; i++) {
		pass.resizePass.renderTargets[i].control.resolution = pass.resizePass.resolution;
		pass.currentRT[i].control.resolution = pass.resizePass.resolution;
	}
	
	// Set the resize material to read the previous RT's
	this.setMaterialTex(pass.resizePass.material, pass.previousRT);
	
	// Set the sim and render materials to read from the resize pass RT's
	for (var i = 0; i < pass.vfxObjects.length; i++) {
		if (!isNull(pass.vfxObjects[i].renderMaterial)) {
			this.setMaterialTex(pass.vfxObjects[i].simMaterial, pass.resizePass.renderTargets);
			this.setMaterialTex(pass.vfxObjects[i].renderMaterial, pass.resizePass.renderTargets);
		}
	}                
}


//////////////////////////////////////////////////////////////
// Update
//////////////////////////////////////////////////////////////
VfxManager.prototype.update = function() {
	
	this.addRegisteredVfx();
	
	for (var i = 0; i < this.passes.length; i++) {
		var pass = this.passes[i];
		// The frame after resizing the atlas
		if (pass.resizePass.sceneObject.enabled && (this.frame - pass.resizePass.triggerFrame > 0)) {
			this.disableResizePass(pass);
		}
		
		// Swap
		[pass.currentRT, pass.previousRT] = [pass.previousRT, pass.currentRT];
		this.updatePassTargets(pass);
		
		// Resize pass enabled
		if (pass.resizePass.sceneObject.enabled) {
			this.updateResizePass(pass);
		}
	}
	
	this.frame += 1;
}


VfxManager.prototype.updatePassTargets = function(pass) {
	
	this.setCameraTargets(pass.cameraTargets, pass.currentRT);  
	
	for (var i = 0; i < pass.vfxObjects.length; i++) {
		if (!isNull(pass.vfxObjects[i].renderMaterial)) {
			this.setMaterialTex(pass.vfxObjects[i].simMaterial, pass.previousRT);
			this.setMaterialTex(pass.vfxObjects[i].renderMaterial, pass.currentRT);
		}
	}
	
}

//////////////////////////////////////////////////////////////
// Config Material Textures
//////////////////////////////////////////////////////////////              
VfxManager.prototype.setupMaterialTextures = function( material, renderTargetArray )
{
	this.setMaterialTex(material, renderTargetArray);
	
	var matSamplers = material.mainPass.samplers;
	
	matSamplers.renderTarget0.filtering = FilteringMode.Nearest;
	matSamplers.renderTarget1.filtering = FilteringMode.Nearest;
	matSamplers.renderTarget2.filtering = FilteringMode.Nearest;
	matSamplers.renderTarget3.filtering = FilteringMode.Nearest;
	
	matSamplers.renderTarget0.wrap = WrapMode.ClampToBorder;
	matSamplers.renderTarget1.wrap = WrapMode.ClampToBorder;
	matSamplers.renderTarget2.wrap = WrapMode.ClampToBorder;
	matSamplers.renderTarget3.wrap = WrapMode.ClampToBorder;
	
}

//////////////////////////////////////////////////////////////
// Set Material Textures
//////////////////////////////////////////////////////////////                              
VfxManager.prototype.setMaterialTex = function( material, renderTargetArray ) {
	var matPass = material.mainPass;
	matPass.renderTarget0 = renderTargetArray[0];
	matPass.renderTarget1 = renderTargetArray[1];
	matPass.renderTarget2 = renderTargetArray[2];
	matPass.renderTarget3 = renderTargetArray[3];	
}


//////////////////////////////////////////////////////////////
// Set Camera Render Targets
//////////////////////////////////////////////////////////////                     
VfxManager.prototype.setCameraTargets = function( cameraTargets, renderTargetArray ) {
	for ( var i = 0; i < 4; i++ ) {
		cameraTargets[i].targetTexture = renderTargetArray[i];
	}	
}


//////////////////////////////////////////////////////////////
// Create Pass
//////////////////////////////////////////////////////////////
VfxManager.prototype.createPass = function() {
	var layer = LayerSet.makeUnique();			
	var cameraObject = global.scene.createSceneObject('_ngsCameraObject');
	cameraObject.setParent(this.sceneObject);
	cameraObject.layer = layer;
	
	var cameraComponent = cameraObject.createComponent('Camera');
	
	if ( cameraComponent.supportedColorRenderTargetCount < 4 ) 
	{
		print("VFX is not supported because 4 render targets are not available.");
		return;
	}
	
	var targetsA = [];
	var targetsB = [];
	
	for ( var i = 0; i < 4; i++ ) 
	{
		var targetA = this.createRenderTarget();
		targetA.control.replayCapture = true
		targetsA.push( targetA );
		var targetB = this.createRenderTarget();
		targetB.control.replayCapture = true
		targetsB.push( targetB );
	}
	
	this.setupCamera( cameraComponent, layer, targetsA, -1000 );
	
	var resizePass = this.createResizePass(this.resizeMaterial.clone(), targetsB)
	
	var pass = new VfxPass(cameraObject, cameraComponent, layer, targetsA, targetsB, resizePass);
	this.passes.push(pass);
	return pass;
}


//////////////////////////////////////////////////////////////
// Create Resize Pass
//////////////////////////////////////////////////////////////
VfxManager.prototype.createResizePass = function(resizeMaterial, previousRT) {
	var layer = LayerSet.makeUnique();			
	var resizeSO = global.scene.createSceneObject('_ngsResizeCameraObject');
	resizeSO.setParent(this.sceneObject);
	resizeSO.layer = layer;
	
	var cameraComponent = resizeSO.createComponent('Camera');
	var targetsA = [];
	
	for ( var i = 0; i < 4; i++ ) 
	{
		var targetA = this.createRenderTarget();
		targetA.control.replayCapture = true
		targetsA.push( targetA );
	}
	
	this.setupCamera( cameraComponent, layer, targetsA, -999 );
	
	var postEffect = resizeSO.createComponent('Component.PostEffectVisual');
	postEffect.mainMaterial = resizeMaterial;
	
	this.setupMaterialTextures(resizeMaterial, previousRT);
	
	// Disable by default
	resizeSO.enabled = false;
	
	var pass = {
		"sceneObject": resizeSO,
		"camera": cameraComponent,
		"cameraTargets": cameraComponent.colorRenderTargets,
		"renderTargets": targetsA,
		"material": resizeMaterial,
		"triggerFrame": this.frame,
		"resolution": targetsA[0].control.resolution
	}
	return pass;
}


//////////////////////////////////////////////////////////////
// Setup Camera
//////////////////////////////////////////////////////////////
VfxManager.prototype.setupCamera = function( camera, layer, renderTargetArray, renderOrder )
{
	camera.enableClearColor = true;
	camera.renderLayer = layer;
	camera.renderOrder = renderOrder;
	camera.depthBufferMode = Camera.DepthBufferMode.Regular;
	camera.devicePropertyUsage = Camera.DeviceProperty.All;
	camera.size = 2.0;
	camera.near = 0.1;
	camera.far  = 100.0;
	camera.type = Camera.Type.Orthographic;
	camera.devicePropertyUsage = Camera.DeviceProperty.None;
	
	var colorRenderTargets = camera.colorRenderTargets;
	var clearColor = new vec4( 0, 0, 0, 0 );
	
	for ( var i = 0; i < 4; i++ )
	{
		if ( renderTargetArray[i] )
		{
			this.checkOrAddColorRenderTarget( colorRenderTargets, i );
			colorRenderTargets[i].targetTexture = renderTargetArray[i];
			colorRenderTargets[i].clearColor = clearColor;
		}
		else
		{
			print( "renderTargetArray[" + i + "] is null" );
			
			if ( colorRenderTargets[i] != null ) colorRenderTargets[i].targetTexture = null;
			else print( "colorRenderTarget[" + i + "] is null" );
		}
	}
	
	camera.colorRenderTargets = colorRenderTargets;
};


VfxManager.prototype.checkOrAddColorRenderTarget = function( colorRenderTargetsArray, colorAttachmentIndex )
{
	if ( colorAttachmentIndex >= colorRenderTargetsArray.length )
	{
		for ( var i = colorRenderTargetsArray.length; i <= colorAttachmentIndex; i++ )
		{
			colorRenderTargetsArray.push( Camera.createColorRenderTarget() );
		}
	}
}


//////////////////////////////////////////////////////////////
// Create Render Target
//////////////////////////////////////////////////////////////
VfxManager.prototype.createRenderTarget = function() {
	
	var renderTarget = global.scene.createRenderTargetTexture();
	var renderTargetControl = renderTarget.control;
	renderTargetControl.useScreenResolution = false;
	renderTargetControl.resolution = new vec2(1,1);
	renderTargetControl.clearColorEnabled = true;
	renderTargetControl.clearDepthEnabled = false;
	renderTargetControl.fxaa = false;
	renderTargetControl.msaa = false;
	
	return renderTarget;
}


//////////////////////////////////////////////////////////////
// Create Screen Quad
//////////////////////////////////////////////////////////////
VfxManager.prototype.createScreenQuad = function( material, meshVisual )
{
	var builder = new MeshBuilder([
			{ name: "position", components: 3 },
			{ name: "normal", components: 3, normalized: true },
			{ name: "texture0", components: 2 },
		]);
	
	builder.topology = MeshTopology.Triangles;
	builder.indexType = MeshIndexType.UInt16;
	
	builder.appendVerticesInterleaved([
			// Position         Normal      UV       Index
			-1.0,  1.0, -1.0,   0, 0, 1,    0, 1,    // 0
			-1.0, -1.0, -1.0,   0, 0, 1,    0, 0,    // 1
			1.0, -1.0, -1.0,   0, 0, 1,    1, 0,    // 2
			1.0,  1.0, -1.0,   0, 0, 1,    1, 1,    // 3
		]);
	
	
	builder.appendIndices([ 
			0,1,2, // First Triangle
			2,3,0, // Second Triangle
		]);
	
	if( builder.isValid() )
	{
		builder.updateMesh();
		return builder;
	}
	else
	{
		print( "NGS Particle Error: Quad data invalid!" );
	}
}


//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------                				

function createParticleMesh( rootObject, material, renderOrder )
{
	var meshVisual = rootObject.createComponent('RenderMeshVisual'); //new
	
	var TempMeshVisual = script.getSceneObject().getParent().getComponent("Component.RenderMeshVisual");
	
	if( TempMeshVisual && TempMeshVisual.mesh )
	{
		meshVisual.setRenderOrder( renderOrder );
		meshVisual.mesh = TempMeshVisual.mesh;
		meshVisual.mainMaterial  = material;
		meshVisual.meshShadowMode = 0;
		meshVisual.shadowColor = new vec4( 1, 1, 1, 1 );
		meshVisual.shadowDensity = 1;
		meshVisual.mainPass.frustumCullMin = new vec3( -1000, -1000, -1000 );
		meshVisual.mainPass.frustumCullMax = new vec3( 1000, 1000, 1000 );
		meshVisual.mainPass.frustumCullMode = FrustumCullMode.UserDefinedAABB;
	}
	else
	{
		print( "NGS Particle Error: No Mesh!" );
	}
	return TempMeshVisual;
}

//-------------------------------------------------------------------------------

function createParticleQuad( rootObject, material, renderOrder )
{
	var builder = new MeshBuilder([
			{ name: "position", components: 3 },
			{ name: "normal", components: 3, normalized: true },
			{ name: "texture0", components: 2 },
		]);
	
	builder.topology = MeshTopology.Triangles;
	builder.indexType = MeshIndexType.UInt16;
	
	var scale = 0.5;
	
	var left = -scale; 
	var right = scale;
	var top = scale;
	var bottom = -scale;
	
	builder.appendVerticesInterleaved([
			// Position         Normal      UV       Index
			left, top, 0,       0, 0, 1,    0, 1,    // 0
			left, bottom, 0,    0, 0, 1,    0, 0,    // 1
			right, bottom, 0,   0, 0, 1,    1, 0,    // 2
			right, top, 0,      0, 0, 1,    1, 1,    // 3
		]);
	
	builder.appendIndices([ 
			0,1,2, // First Triangle
			2,3,0, // Second Triangle
		]);
	
	var meshVisual = rootObject.createComponent('RenderMeshVisual'); //new
	meshVisual.setRenderOrder( renderOrder );
	
	if( builder.isValid() )
	{
		meshVisual.mesh = builder.getMesh();
		meshVisual.mainMaterial  = material;
		meshVisual.meshShadowMode = 0;
		meshVisual.shadowColor = new vec4( 1, 1, 1, 1 );
		meshVisual.shadowDensity = 1;
		meshVisual.mainPass.frustumCullMin = new vec3( -1000, -1000, -1000 );
		meshVisual.mainPass.frustumCullMax = new vec3( 1000, 1000, 1000 );
		meshVisual.mainPass.frustumCullMode = FrustumCullMode.UserDefinedAABB;
		builder.updateMesh();
	}
	else
	{
		print( "NGS Particle Error: Quad data invalid!" );
	}
	return meshVisual;
}


//-------------------------------------------------------------------------------


function setParentBySpace( systemId, refObject, type, inWorldSpace)
{
	if ( inWorldSpace ) 
	{
		refObject.setParent(null);
	}
	else 
	{
		refObject.setParent(scriptObject); 
	}
	vfxComponent.setRefObject(systemId, refObject, type);
}


//-------------------------------------------------------------------------------


var isInitialized = false;
var scriptObject = null;
var scriptTransform = null;
var renderObject = null;
var renderMeshVisual = null;
var renderCamera = null;
var renderCameraTransform = null;
var vfxObject = null;
var vfxComponent = null;
var simulatePass;			


var initialize = function()
{
	script.vfxFrame = 0;
	
	MAT_SIMULATE = script.Material_Simulate;
	MAT_RENDER = script.Material_Render;
	
	scriptObject = script.getSceneObject();
	scriptTransform = scriptObject.getTransform();
	vfxObject = scriptObject.getParent();
	vfxComponent = vfxObject.getComponent("Component.VFXComponent");
	simulatePass = MAT_SIMULATE.mainPass;
	
	if (!global._ngsVfxManager) {
		var vfxManagerSO = global.scene.createSceneObject("_ngsVfxManager");
		
		global._ngsVfxManager = new VfxManager(vfxManagerSO, script.Material_Feedback);
		
		var scriptComp = vfxManagerSO.createComponent("Script");
		scriptComp.createEvent("LateUpdateEvent").bind(function(){
				global._ngsVfxManager.update();
			});                              
	}
	
	VFX_OBJECT = global._ngsVfxManager.register(MAT_SIMULATE, MAT_RENDER, TEXEL_COUNT, INSTANCE_COUNT);
	
	simulatePass.instanceCount = INSTANCE_COUNT;
	MAT_RENDER.mainPass.instanceCount = INSTANCE_COUNT;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	// Create the quad we instance and render with
	
	// We need to create a new SceneObject instead of using Script
	renderObject = scene.createSceneObject('renderObject');
	// We need the system id, set true if it is in world space
	setParentBySpace( "39", renderObject, VFXRefObjectType.Rendering, true );
	
	if ( false )
	{
		renderMeshVisual = createParticleMesh( renderObject, MAT_RENDER /* we'll override this if user chooses custom material */, vfxComponent.getRenderOrder() );
	}
	else
	{
		renderMeshVisual = createParticleQuad( renderObject, MAT_RENDER, vfxComponent.getRenderOrder() );
	}                   
	
	renderObject.layer = vfxObject.layer;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	var objects = {arrayKey : []};
	
	for (var i = 0; i < global.scene.getRootObjectsCount(); i++) 
	{
		var rootObject = global.scene.getRootObject(i);
		componentSearchRecursive(rootObject, "Component.Camera", objects);
	}
	
	// Find a camera that matches this script's render layer
	// If it matches, assign the camera component to 'renderCamera'
	//print( script.getSceneObject().layer );
	var objectLayer = renderObject.layer;
	for (var i = 0; i < objects.arrayKey.length; i++) 
	{
		var cameraComponent = objects.arrayKey[i].getComponent("Component.Camera");
		var cameraLayer = cameraComponent.renderLayer;
		
		if (cameraLayer.contains(objectLayer)) {
			renderCamera = cameraComponent;
			renderCameraTransform = renderCamera.getTransform();
			break;
		}
	}
	
	if ( isNull(renderCamera) ) {
		//print( "VFX: Did not find main camera" );
		return;
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( MAT_SIMULATE != undefined ) {
		simulatePass.vfxFrame = 0;
	}
	
	isInitialized = true;
};

//-------------------------------------------------------------------------------


var event = script.createEvent( "SceneEvent.OnStartEvent" );
event.bind( function( eventData )
	{
		initialize();
	});


//-------------------------------------------------------------------------------


var newEvent = script.createEvent('UpdateEvent');
newEvent.bind(function() 
	{
		if ( !isInitialized || MAT_SIMULATE == undefined || isNull(VFX_OBJECT.meshVisual))
		{
			return;
		}
		
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
		
		/* no delay */
		
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
		
		renderMeshVisual.setRenderOrder(vfxComponent.getRenderOrder());
		renderObject.layer = vfxObject.layer;
		
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
		
		// Camera
		
		var cameraAspect = renderCamera.aspect;
		var cameraFov = renderCamera.fov;
		var cameraNear = renderCamera.near;
		var cameraFar = renderCamera.far;
		
		simulatePass.vfxCameraAspect = cameraAspect;
		simulatePass.vfxCameraNear = cameraNear;
		simulatePass.vfxCameraFar = cameraFar;
		simulatePass.vfxCameraUp = renderCameraTransform.up;
		simulatePass.vfxCameraForward = renderCameraTransform.forward;
		simulatePass.vfxCameraRight = renderCameraTransform.right;
		
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
		
		var modelMatrix         = scriptTransform.getWorldTransform();
		var modelMatrixInv      = scriptTransform.getInvertedWorldTransform(); 
		var viewMatrix          = renderCameraTransform.getInvertedWorldTransform();
		var projectionMatrix;
		
		if (renderCamera.type == Camera.Type.Orthographic) {
			var orthoSize = renderCamera.getOrthographicSize().uniformScale(0.5);
			projectionMatrix    = mat4.orthographic(-orthoSize.x, orthoSize.x, -orthoSize.y, orthoSize.y, cameraNear, cameraFar);
		}
		else {
			projectionMatrix    = mat4.perspective(cameraFov, cameraAspect, cameraNear, cameraFar);								
		}
		var modelViewMatrix     = viewMatrix.mult(modelMatrix);
		var modelViewProjection = projectionMatrix.mult(viewMatrix.mult(modelMatrix));
		var viewProjection      = projectionMatrix.mult(viewMatrix);
		
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
		
		// Model 
		
		simulatePass.vfxModelMatrix = modelMatrix;
		simulatePass.vfxModelMatrixInverse = modelMatrixInv;
		
		// Model x View
		
		simulatePass.vfxModelViewMatrix = modelViewMatrix;
		simulatePass.vfxModelViewMatrixInverse = modelViewMatrix.inverse();
		
		// Projection
		
		simulatePass.vfxProjectionMatrix = projectionMatrix;
		simulatePass.vfxProjectionMatrixInverse = projectionMatrix.inverse();
		
		// Model View Projection
		
		simulatePass.vfxModelViewProjectionMatrix = modelViewProjection;
		simulatePass.vfxModelViewProjectionMatrixInverse = modelViewProjection.inverse();
		
		// View
		
		simulatePass.vfxViewMatrix = viewMatrix;
		simulatePass.vfxViewMatrixInverse = viewMatrix.inverse();
		
		// View Projection
		
		simulatePass.vfxViewProjectionMatrix = viewProjection;
		simulatePass.vfxViewProjectionMatrixInverse = viewProjection.inverse();
		
		simulatePass.vfxFrame = script.vfxFrame;
		
		//@TODO we also need to override AABB's in simulatePass when we implement mesh rendering
		
		script.vfxFrame++;
	});


//-------------------------------------------------------------------------------


function componentSearchRecursive(baseObject, component, objects) 
{
	var result = null;
	if (baseObject.getComponentCount(component) > 0) {
		if(baseObject.getFirstComponent(component)) {
			result = baseObject; 
			objects.arrayKey.push(result);
		}
	}
	for (var i = 0; i < baseObject.getChildrenCount(); i++) {
		var childResult = componentSearchRecursive(baseObject.getChild(i), component, objects);
		if (childResult) result = childResult;
	}
	return result;
}

//-------------------------------------------------------------------------------

script.createEvent("OnDestroyEvent").bind(function(){    
		global._ngsVfxManager.destroy(VFX_OBJECT.passId, VFX_OBJECT.objectId);
	})


