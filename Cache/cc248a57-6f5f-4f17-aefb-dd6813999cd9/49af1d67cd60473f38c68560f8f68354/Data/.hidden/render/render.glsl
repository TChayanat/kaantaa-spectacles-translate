#version 310 es

#define NODEFLEX 0 // Hack for now to know if a shader is running in Studio or on a released lens

#define NF_PRECISION highp

//-----------------------------------------------------------------------

#define ENABLE_LIGHTING false
#define ENABLE_DIFFUSE_LIGHTING false
#define ENABLE_SPECULAR_LIGHTING false


//-----------------------------------------------------------------------


//-----------------------------------------------------------------------


//-----------------------------------------------------------------------
// Standard defines
//-----------------------------------------------------------------------


#pragma paste_to_backend_at_the_top_begin
#define SC_DISABLE_FRUSTUM_CULLING
#define SC_ALLOW_16_TEXTURES
#define SC_ENABLE_INSTANCED_RENDERING
#pragma paste_to_backend_at_the_top_end


//-----------------------------------------------------------------------
// Standard includes
//-----------------------------------------------------------------------

#include <std2.glsl>
#include <std2_vs.glsl>
#include <std2_texture.glsl>
#include <std2_receiver.glsl>
#include <std2_fs.glsl>
#include <std2_ssao.glsl>
#if (SC_BACKEND_LANGUAGE_VERSION >= 310) || defined (SC_BACKEND_LANGUAGE_METAL)
#if !SC_RT_RECEIVER_MODE
#include <std2_proxy.glsl>
#endif
#endif

//-----------------------------------------------------------------------
// Global defines
//-----------------------------------------------------------------------

#define SCENARIUM


#ifdef SC_BACKEND_LANGUAGE_MOBILE
#define MOBILE
#endif


#ifdef SC_BACKEND_LANGUAGE_GL
const bool DEVICE_IS_FAST = SC_DEVICE_CLASS >= SC_DEVICE_CLASS_C && bool(SC_GL_FRAGMENT_PRECISION_HIGH);
#else
const bool DEVICE_IS_FAST = SC_DEVICE_CLASS >= SC_DEVICE_CLASS_C;
#endif


const bool SC_ENABLE_SRGB_EMULATION_IN_SHADER = false;


//-----------------------------------------------------------------------
// Varyings
//-----------------------------------------------------------------------

varying vec4 varColor;

//-----------------------------------------------------------------------
// User includes
//-----------------------------------------------------------------------
#include "includes/utils.glsl"		
// in SC_RT_RECEIVER_MODE, the following headers cannot be included as they reference std2_fs_output functions: 
#if !SC_RT_RECEIVER_MODE
#include "includes/blend_modes.glsl"
#include "includes/oit.glsl" 
#endif
#include "includes/rgbhsl.glsl"
#include "includes/uniforms.glsl"

//-----------------------------------------------------------------------

// The next 60 or so lines of code are for debugging support, live tweaks, node previews, etc and will be included in a 
// shared glsl file.

//-----------------------------------------------------------------------

// Hack for now to know if a shader is running in Studio or on a released lens

#if !defined(MOBILE) && !NODEFLEX
#define STUDIO
#endif

//-----------------------------------------------------------------------

#if defined( SIMULATION_PASS )


#define ngsLocalAabbMin						vfxLocalAabbMin
#define ngsWorldAabbMin						vfxWorldAabbMin
#define ngsLocalAabbMax						vfxLocalAabbMax
#define ngsWorldAabbMax						vfxWorldAabbMax
#define ngsCameraAspect 					vfxCameraAspect
#define ngsCameraNear                       vfxCameraNear
#define ngsCameraFar                        vfxCameraFar
#define ngsCameraPosition                   vfxViewMatrixInverse[3].xyz
#define ngsModelMatrix                      vfxModelMatrix
#define ngsModelMatrixInverse               vfxModelMatrixInverse
#define ngsModelViewMatrix                  vfxModelViewMatrix
#define ngsModelViewMatrixInverse           vfxModelViewMatrixInverse
#define ngsProjectionMatrix                 vfxProjectionMatrix
#define ngsProjectionMatrixInverse          vfxProjectionMatrixInverse
#define ngsModelViewProjectionMatrix        vfxModelViewProjectionMatrix
#define ngsModelViewProjectionMatrixInverse vfxModelViewProjectionMatrixInverse
#define ngsViewMatrix                       vfxViewMatrix
#define ngsViewMatrixInverse                vfxViewMatrixInverse
#define ngsViewProjectionMatrix             vfxViewProjectionMatrix
#define ngsViewProjectionMatrixInverse      vfxViewProjectionMatrixInverse
#define ngsCameraUp 					    vfxCameraUp
#define ngsCameraForward                    -vfxCameraForward
#define ngsCameraRight                      vfxCameraRight
#define ngsFrame    	                    vfxFrame


#else


#define ngsLocalAabbMin						sc_LocalAabbMin
#define ngsWorldAabbMin						sc_WorldAabbMin
#define ngsLocalAabbMax						sc_LocalAabbMax
#define ngsWorldAabbMax						sc_WorldAabbMax
#define ngsCameraAspect 					sc_Camera.aspect;
#define ngsCameraNear                       sc_Camera.clipPlanes.x
#define ngsCameraFar                        sc_Camera.clipPlanes.y
#define ngsCameraPosition                   sc_Camera.position
#define ngsModelMatrix                      sc_ModelMatrix
#define ngsModelMatrixInverse               sc_ModelMatrixInverse
#define ngsModelViewMatrix                  sc_ModelViewMatrix
#define ngsModelViewMatrixInverse           sc_ModelViewMatrixInverse
#define ngsProjectionMatrix                 sc_ProjectionMatrix
#define ngsProjectionMatrixInverse          sc_ProjectionMatrixInverse
#define ngsModelViewProjectionMatrix        sc_ModelViewProjectionMatrix
#define ngsModelViewProjectionMatrixInverse sc_ModelViewProjectionMatrixInverse
#define ngsViewMatrix                       sc_ViewMatrix
#define ngsViewMatrixInverse                sc_ViewMatrixInverse
#define ngsViewProjectionMatrix             sc_ViewProjectionMatrix
#define ngsViewProjectionMatrixInverse      sc_ViewProjectionMatrixInverse
#define ngsCameraUp 					    sc_ViewMatrixInverse[1].xyz
#define ngsCameraForward                    -sc_ViewMatrixInverse[2].xyz
#define ngsCameraRight                      sc_ViewMatrixInverse[0].xyz
#define ngsFrame 		                    0


#endif

//-----------------------------------------------------------------------

// Time Overrides

uniform       int   overrideTimeEnabled;
uniform highp float overrideTimeElapsed;
uniform highp float overrideTimeDelta;

//-----------------------------------------------------------------------

#if defined( STUDIO )
#define ssConstOrUniformPrecision	uniform NF_PRECISION
#define ssConstOrUniform			uniform
#else
#define ssConstOrUniformPrecision   const
#define ssConstOrUniform    		const
#endif

//--------------------------------------------------------

// When compiling the shader for rendering in a node-based editor, we need any unconnected dynamic input port's value to
// be tweakable in real-time so we expose it to the engine as a uniform. If we're compiling the shader for a release build
// we use a literal or const value

#if defined( STUDIO )
#define NF_PORT_CONSTANT( xValue, xUniform )	xUniform
#else
#define NF_PORT_CONSTANT( xValue, xUniform )	xValue
#endif

//--------------------------------------------------------

#define float2   vec2
#define float3   vec3
#define float4   vec4
#define bool2    bvec2
#define bool3    bvec3
#define bool4    bvec4
#define float2x2 mat2
#define float3x3 mat3
#define float4x4 mat4

//--------------------------------------------------------

#define ssConditional( C, A, B ) ( ( C * 1.0 != 0.0 ) ? A : B )
#define ssEqual( A, B )          ( ( A == B ) ? 1.0 : 0.0 )
#define ssNotEqual( A, B )       ( ( A == B ) ? 0.0 : 1.0 )
#define ssLarger( A, B )         ( ( A > B ) ? 1.0 : 0.0 )
#define ssLargerOrEqual( A, B )  ( ( A >= B ) ? 1.0 : 0.0 )
#define ssSmaller( A,  B ) 		 ( ( A < B ) ? 1.0 : 0.0 )
#define ssSmallerOrEqual( A, B ) ( ( A <= B ) ? 1.0 : 0.0 )
#define ssNot( A ) 		         ( ( A * 1.0 != 0.0 ) ? 0.0 : 1.0 )

//--------------------------------------------------------

int ssIntMod( int x, int y )
{
	return x - y * ( x / y );
}

//--------------------------------------------------------

float ssSRGB_to_Linear( float value ) { return ( DEVICE_IS_FAST ) ? pow( value, 2.2 ) : value * value; }
vec2  ssSRGB_to_Linear( vec2  value ) { return ( DEVICE_IS_FAST ) ? vec2( pow( value.x, 2.2 ), pow( value.y, 2.2 ) ) : value * value; }
vec3  ssSRGB_to_Linear( vec3  value ) { return ( DEVICE_IS_FAST ) ? vec3( pow( value.x, 2.2 ), pow( value.y, 2.2 ), pow( value.z, 2.2 ) ) : value * value; }
vec4  ssSRGB_to_Linear( vec4  value ) { return ( DEVICE_IS_FAST ) ? vec4( pow( value.x, 2.2 ), pow( value.y, 2.2 ), pow( value.z, 2.2 ), pow( value.w, 2.2 ) ) : value * value; }

float ssLinear_to_SRGB( float value ) { return ( DEVICE_IS_FAST ) ? pow( value, 0.45454545 ) : sqrt( value ); }
vec2  ssLinear_to_SRGB( vec2  value ) { return ( DEVICE_IS_FAST ) ? vec2( pow( value.x, 0.45454545 ), pow( value.y, 0.45454545 ) ) : sqrt( value ); }
vec3  ssLinear_to_SRGB( vec3  value ) { return ( DEVICE_IS_FAST ) ? vec3( pow( value.x, 0.45454545 ), pow( value.y, 0.45454545 ), pow( value.z, 0.45454545 ) ) : sqrt( value ); }
vec4  ssLinear_to_SRGB( vec4  value ) { return ( DEVICE_IS_FAST ) ? vec4( pow( value.x, 0.45454545 ), pow( value.y, 0.45454545 ), pow( value.z, 0.45454545 ), pow( value.w, 0.45454545 ) ) : sqrt( value ); }

//--------------------------------------------------------

float3 ssWorldToScreen( float3 Vector, mat4 ViewProjectionMatrix )
{
	float4 ScreenVector = ViewProjectionMatrix * float4( Vector, 1.0 );
	return ScreenVector.xyz / ScreenVector.w;
}

//--------------------------------------------------------

float  Dummy1;
float2 Dummy2;
float3 Dummy3;
float4 Dummy4;

//--------------------------------------------------------

#define ssPRECISION_LIMITER( Value ) Value = floor( Value * 10000.0 ) * 0.0001;
#define ssPRECISION_LIMITER2( Value ) Value = floor( Value * 2000.0 + 0.5 ) * 0.0005;

//--------------------------------------------------------

#define ssDELTA_TIME_MIN 0.00

//--------------------------------------------------------


struct ssParticle
{	
	vec3  Position;
	vec3  Velocity;
	vec4  Color;
	float Size;
	float Age; 			// how long the particle has been alive
	float Life;			// the lifespan of the particle
	float Mass;
	mat3  Matrix;
	float Dead;
	//vec4  Quaternion;
	
	// Custom
	
	
	
	// Calculated
	
	float SpawnOffset;
	float Seed;
	vec2  Seed2000;
	float TimeShift;
	int   Index1D;
	float Coord1D;
	float Ratio1D;
	ivec2 Index2D;
	vec2  Coord2D;
	vec2  Ratio2D;
	vec3  Force;
	bool  Spawned;
};

ssParticle gParticle;

vec4 EncodeFloat32( float v /* 0 - 1 range only */ ) 
{
	vec4 enc = vec4(1.0, 255.0, 65025.0, 16581375.0) * v;
	enc = fract(enc);
	enc -= enc.yzww * vec4(1.0/255.0, 1.0/255.0, 1.0/255.0, 0.0);
	return enc;
}

vec3 EncodeFloat24( float v /* 0 - 1 range only */ ) 
{
	vec4 enc = vec4(1.0, 255.0, 65025.0, 16581375.0) * v;
	enc = fract(enc);
	enc -= enc.yzww * vec4(1.0/255.0, 1.0/255.0, 1.0/255.0, 0.0);
	return enc.rgb;
}

vec2 EncodeFloat16( float v /* 0 - 1 range only */ ) 
{
	vec4 enc = vec4(1.0, 255.0, 65025.0, 16581375.0) * v;
	enc = fract(enc);
	enc -= enc.yzww * vec4(1.0/255.0, 1.0/255.0, 1.0/255.0, 0.0);
	return enc.rg;
}

float EncodeFloat8( float v /* 0 - 1 range only */ ) 
{
	vec4 enc = vec4(1.0, 255.0, 65025.0, 16581375.0) * v;
	enc = fract(enc);
	enc -= enc.yzww * vec4(1.0/255.0, 1.0/255.0, 1.0/255.0, 0.0);
	return enc.r;
}

float DecodeFloat32( vec4 rgba /* 0 - 1 range only */, const bool Quantize ) 
{ 
	if ( Quantize ) 
	rgba = floor(rgba * 255.0 + 0.5) / 255.0;
	return dot( rgba, vec4(1.0, 1.0/255.0, 1.0/65025.0, 1.0/16581375.0) );
}

float DecodeFloat24( vec3 rgb /* 0 - 1 range only */, const bool Quantize ) 
{
	if ( Quantize ) 
	rgb = floor(rgb * 255.0 + 0.5) / 255.0;
	return dot( rgb, vec3(1.0, 1.0/255.0, 1.0/65025.0) );
}

float DecodeFloat16( vec2 rg /* 0 - 1 range only */, const bool Quantize ) 
{
	if ( Quantize ) 
	rg = floor(rg * 255.0 + 0.5) / 255.0;
	return dot( rg, vec2(1.0, 1.0/255.0) );
}

float DecodeFloat8( float r /* 0 - 1 range only */, const bool Quantize ) 
{
	if ( Quantize ) 
	r = floor(r * 255.0 + 0.5) / 255.0;
	return r;
}

#define ssDEFAULT_REMAP_RANGE 0.99999
#define ssDEFAULT_REMAP_RANGE2 1.0

vec4  remap (vec4 value, vec4 oldmin, vec4 oldmax, vec4 newmin, vec4 newmax) { return newmin + (value - oldmin) * (newmax - newmin) / (oldmax - oldmin); }
vec3  remap (vec3 value, vec3 oldmin, vec3 oldmax, vec3 newmin, vec3 newmax) { return newmin + (value - oldmin) * (newmax - newmin) / (oldmax - oldmin); }
vec2  remap (vec2 value, vec2 oldmin, vec2 oldmax, vec2 newmin, vec2 newmax) { return newmin + (value - oldmin) * (newmax - newmin) / (oldmax - oldmin); }
float remap (float value, float oldmin, float oldmax, float newmin, float newmax) { return newmin + (value - oldmin) * (newmax - newmin) / (oldmax - oldmin); }
float remapTo01 (float value) { return (value + 1.0) * 0.5; }
float remapFrom01 (float value ) { return (value * 2.0) - 1.0; }

vec4  ssEncodeFloat32( float Value, float Min, float Max, float RemapRange )                      { return EncodeFloat32( remap( clamp( Value, Min, Max ), Min, Max, 0.0, RemapRange ) ); }
vec4  ssEncodeFloat32( float Value, float Min, float Max )                     					  { return ssEncodeFloat32( Value, Min, Max, ssDEFAULT_REMAP_RANGE ); }
vec4  ssEncodeFloat32( float Value, float RemapRange )                                            { return ssEncodeFloat32( Value, 0.0, 1.0, RemapRange ); }
vec3  ssEncodeFloat24( float Value, float Min, float Max, float RemapRange )                      { return EncodeFloat24( remap( clamp( Value, Min, Max ), Min, Max, 0.0, RemapRange ) ); }
vec3  ssEncodeFloat24( float Value, float Min, float Max )                     					  { return ssEncodeFloat24( Value, Min, Max, ssDEFAULT_REMAP_RANGE ); }
vec3  ssEncodeFloat24( float Value, float RemapRange )                                            { return ssEncodeFloat24( Value, 0.0, 1.0, RemapRange ); }
vec2  ssEncodeFloat16( float Value, float Min, float Max, float RemapRange )                      { return EncodeFloat16( remap( clamp( Value, Min, Max ), Min, Max, 0.0, RemapRange ) ); }
vec2  ssEncodeFloat16( float Value, float Min, float Max )                     					  { return ssEncodeFloat16( Value, Min, Max, ssDEFAULT_REMAP_RANGE ); }
vec2  ssEncodeFloat16( float Value, float RemapRange )                                            { return ssEncodeFloat16( Value, 0.0, 1.0, RemapRange ); }
float ssEncodeFloat8(  float Value, float Min, float Max, float RemapRange )                      { return remap( clamp( Value, Min, Max ), Min, Max, 0.0, RemapRange ); }
float ssEncodeFloat8(  float Value, float Min, float Max )                     					  { return remap( clamp( Value, Min, Max ), Min, Max, 0.0, ssDEFAULT_REMAP_RANGE2 ); }
float ssEncodeFloat8(  float Value, float RemapRange )                                            { return ssEncodeFloat8( Value, 0.0, 1.0, RemapRange ); }

float ssDecodeFloat32(  vec4 Value, float Min, float Max, const bool Quantize, float RemapRange ) { return remap( DecodeFloat32( Value, Quantize ), 0.0, RemapRange, Min, Max ); }
float ssDecodeFloat32(  vec4 Value, float Min, float Max ) 										  { return ssDecodeFloat32( Value, Min, Max, true, ssDEFAULT_REMAP_RANGE ); }
float ssDecodeFloat32(  vec4 Value, const bool Quantize, float RemapRange )                       { return ssDecodeFloat32( Value, 0.0, 1.0, Quantize, RemapRange ); }
float ssDecodeFloat24(  vec3 Value, float Min, float Max, const bool Quantize, float RemapRange ) { return remap( DecodeFloat24( Value, Quantize ), 0.0, RemapRange, Min, Max ); }
float ssDecodeFloat24(  vec3 Value, float Min, float Max ) 										  { return ssDecodeFloat24( Value, Min, Max, true, ssDEFAULT_REMAP_RANGE ); }
float ssDecodeFloat24(  vec3 Value, const bool Quantize, float RemapRange )                       { return ssDecodeFloat24( Value, 0.0, 1.0, Quantize, RemapRange ); }
float ssDecodeFloat16(  vec2 Value, float Min, float Max, const bool Quantize, float RemapRange ) { return remap( DecodeFloat16( Value, Quantize ), 0.0, RemapRange, Min, Max ); }
float ssDecodeFloat16(  vec2 Value, float Min, float Max ) 										  { return ssDecodeFloat16( Value, Min, Max, true, ssDEFAULT_REMAP_RANGE ); }
float ssDecodeFloat16(  vec2 Value, const bool Quantize, float RemapRange )                       { return ssDecodeFloat16( Value, 0.0, 1.0, Quantize, RemapRange ); }
float ssDecodeFloat8(  float Value, float Min, float Max, const bool Quantize, float RemapRange ) { return remap( DecodeFloat8( Value, Quantize ), 0.0, RemapRange, Min, Max ); }
float ssDecodeFloat8(  float Value, float Min, float Max ) 										  { return ssDecodeFloat8( Value, Min, Max, true, ssDEFAULT_REMAP_RANGE2); }
float ssDecodeFloat8(  float Value, const bool Quantize, float RemapRange )                       { return ssDecodeFloat8( Value, 0.0, 1.0, Quantize, RemapRange ); }

int ssRandLfsr(int n)
{
	return (n * (n * 1471343 + 101146501) + 1559861749) & 0x7fffffff;
}

float ssNormalizeRand(int r)
{
	return float(r) * (1.0 / 2147483647.0);
}

int ssGetRandSeedDim1(int x) 
{
	return x ^ (x * 15299);
}

int ssGetRandSeedDim2(int x, int y) {
	return (x * 15299) ^ (y * 30133);
}

int ssGetRandSeedDim3(int x, int y, int z) 
{
	return (x * 15299) ^ (y * 30133) ^ (z * 17539);
}

int ssGetRandSeedDim4(int x, int y, int z, int w) 
{
	return (x * 15299) ^ (y * 30133) ^ (z * 17539) ^ (w * 12113);
}

//--------------------------------------------------------

float ssRandFloat(int seed)
{
	return ssNormalizeRand(ssRandLfsr(seed));	
}

// All seeds given by the user are interpreted as ints
float rand_float( float Seed ) { return ssRandFloat( ssGetRandSeedDim1(int(Seed)) ); }
float rand_float( vec2 Seed )  { return ssRandFloat( ssGetRandSeedDim2(int(Seed.x), int(Seed.y)) ); }
float rand_float( vec3 Seed )  { return ssRandFloat( ssGetRandSeedDim3(int(Seed.x), int(Seed.y), int(Seed.z)) ); }
float rand_float( vec4 Seed )  { return ssRandFloat( ssGetRandSeedDim4(int(Seed.x), int(Seed.y), int(Seed.z), int(Seed.w)) ); }

//--------------------------------------------------------

vec2 ssRandVec2(int seed) 
{
	int r1 = ssRandLfsr(seed);
	int r2 = ssRandLfsr(seed * 1399);
	return vec2(ssNormalizeRand(r1), ssNormalizeRand(r2));
}

vec2 rand_vec2( float Seed ) { return ssRandVec2( ssGetRandSeedDim1(int(Seed)) ); }
vec2 rand_vec2( vec2 Seed )  { return ssRandVec2( ssGetRandSeedDim2(int(Seed.x), int(Seed.y)) ); }
vec2 rand_vec2( vec3 Seed )  { return ssRandVec2( ssGetRandSeedDim3(int(Seed.x), int(Seed.y), int(Seed.z)) ); }
vec2 rand_vec2( vec4 Seed )  { return ssRandVec2( ssGetRandSeedDim4(int(Seed.x), int(Seed.y), int(Seed.z), int(Seed.w)) ); }

//--------------------------------------------------------

vec3 ssRandVec3(int seed) 
{
	int r1 = ssRandLfsr(seed);
	int r2 = ssRandLfsr(seed * 1399);
	int r3 = ssRandLfsr(seed * 7177);
	return vec3(ssNormalizeRand(r1), ssNormalizeRand(r2), ssNormalizeRand(r3));
}

vec3 rand_vec3( float Seed ) { return ssRandVec3( ssGetRandSeedDim1(int(Seed)) ); }
vec3 rand_vec3( vec2 Seed )  { return ssRandVec3( ssGetRandSeedDim2(int(Seed.x), int(Seed.y)) ); }
vec3 rand_vec3( vec3 Seed )  { return ssRandVec3( ssGetRandSeedDim3(int(Seed.x), int(Seed.y), int(Seed.z)) ); }
vec3 rand_vec3( vec4 Seed )  { return ssRandVec3( ssGetRandSeedDim4(int(Seed.x), int(Seed.y), int(Seed.z), int(Seed.w)) ); }

//--------------------------------------------------------

vec4 ssRandVec4(int seed) 
{
	int r1 = ssRandLfsr(seed);
	int r2 = ssRandLfsr(seed * 1399);
	int r3 = ssRandLfsr(seed * 7177);
	int r4 = ssRandLfsr(seed * 18919);
	return vec4(ssNormalizeRand(r1), ssNormalizeRand(r2), ssNormalizeRand(r3), ssNormalizeRand(r4));
}

vec4 rand_vec4( float Seed ) { return ssRandVec4( ssGetRandSeedDim1(int(Seed)) ); }
vec4 rand_vec4( vec2 Seed )  { return ssRandVec4( ssGetRandSeedDim2(int(Seed.x), int(Seed.y)) ); }
vec4 rand_vec4( vec3 Seed )  { return ssRandVec4( ssGetRandSeedDim3(int(Seed.x), int(Seed.y), int(Seed.z)) ); }
vec4 rand_vec4( vec4 Seed )  { return ssRandVec4( ssGetRandSeedDim4(int(Seed.x), int(Seed.y), int(Seed.z), int(Seed.w)) ); }

//--------------------------------------------------------	


vec4 ssGetParticleRandom( int Dimension, bool UseTime, bool UseNodeID, bool UseParticleID, float NodeID, ssParticle Particle, float ExtraSeed, float Time )
{
	vec4 Random = vec4( 0.0 );
	vec4 seed = vec4(0.0);
	
	if (UseTime) 		seed.x = floor(fract(Time) * 1000.0);
	if (UseParticleID) 	seed.y = float(Particle.Index1D ^ (Particle.Index1D * 15299 + Particle.Index1D));
	if (UseNodeID) 		seed.z = NodeID;
	seed.w = ExtraSeed * 1000.0;	
	
	int seed_i = ssGetRandSeedDim4(int(seed.x), int(seed.y), int(seed.z), int(seed.w));
	
	if 		( Dimension == 1 ) Random.x 	= ssRandFloat(seed_i);
	else if ( Dimension == 2 ) Random.xy 	= ssRandVec2(seed_i); 					
	else if ( Dimension == 3 ) Random.xyz 	= ssRandVec3(seed_i);
	else 					   Random 		= ssRandVec4(seed_i);
	
	return Random;
}

//--------------------------------------------------------			


//--------------------------------------------------------


#if 0

struct ssPreviewInfo
{
	float4 Color;
	bool   Saved;
};

ssPreviewInfo PreviewInfo;

uniform NF_PRECISION int PreviewEnabled; // PreviewEnabled is set to 1 by the renderer when Lens Studio is rendering node previews
uniform NF_PRECISION int PreviewNodeID;  // PreviewNodeID is set to the node's ID that a preview is being rendered for

varying float4 PreviewVertexColor;
varying float  PreviewVertexSaved;

#define NF_DISABLE_VERTEX_CHANGES() 				( PreviewEnabled == 1 )		
#define NF_SETUP_PREVIEW_VERTEX()					PreviewInfo.Color = PreviewVertexColor = float4( 0.5 ); PreviewInfo.Saved = false; PreviewVertexSaved = 0.0;
#define NF_SETUP_PREVIEW_PIXEL()					PreviewInfo.Color = PreviewVertexColor; PreviewInfo.Saved = ( PreviewVertexSaved * 1.0 != 0.0 ) ? true : false;
#define NF_PREVIEW_SAVE( xCode, xNodeID, xAlpha ) 	if ( PreviewEnabled == 1 && !PreviewInfo.Saved && xNodeID == PreviewNodeID ) { PreviewInfo.Saved = true; { PreviewInfo.Color = xCode; if ( !xAlpha ) PreviewInfo.Color.a = 1.0; } }
#define NF_PREVIEW_FORCE_SAVE( xCode ) 				if ( PreviewEnabled == 0 ) { PreviewInfo.Saved = true; { PreviewInfo.Color = xCode; } }
#define NF_PREVIEW_OUTPUT_VERTEX()					if ( PreviewInfo.Saved ) { PreviewVertexColor = float4( PreviewInfo.Color.rgb, 1.0 ); PreviewVertexSaved = 1.0; }
#define NF_PREVIEW_OUTPUT_PIXEL()					if ( PreviewEnabled == 1 ) { if ( PreviewInfo.Saved ) { Output_Color0 = float4( PreviewInfo.Color ); } else { Output_Color0 = vec4( 0.0, 0.0, 0.0, 0.0 ); /*FinalColor.a = 1.0;*/ /* this will be an option later */ }  }

#else

#define NF_DISABLE_VERTEX_CHANGES()					false		
#define NF_SETUP_PREVIEW_VERTEX()
#define NF_SETUP_PREVIEW_PIXEL()
#define NF_PREVIEW_SAVE( xCode, xNodeID, xAlpha )
#define NF_PREVIEW_FORCE_SAVE( xCode )
#define NF_PREVIEW_OUTPUT_VERTEX()
#define NF_PREVIEW_OUTPUT_PIXEL()

#endif


//--------------------------------------------------------



//--------------------------------------------------------

float4 ssGetScreenPositionNDC( float4 vertexPosition, float3 transformedPosition, mat4 viewProjectionMatrix )
{
	float4 screenPosition = vec4( 0.0 );
	
	#ifdef VERTEX_SHADER
	
	if ( sc_RenderingSpace == SC_RENDERING_SPACE_SCREEN )
	{
		screenPosition = vertexPosition;
	}
	else
	{
		screenPosition = ( viewProjectionMatrix * float4( transformedPosition, 1.0 ) );
		screenPosition.xyz /= screenPosition.w;
	}
	
	#endif
	
	return screenPosition;
}

//--------------------------------------------------------

#ifdef FRAGMENT_SHADER

#define ngsAlphaTest( opacity )

#endif // #ifdef FRAGMENT_SHADER

#ifdef FRAGMENT_SHADER
#if !SC_RT_RECEIVER_MODE
vec4 ngsPixelShader( vec4 result ) 
{	
	if ( sc_ProjectiveShadowsCaster )
	{
		return evaluateShadowCasterColor( result );
	}
	else if ( sc_RenderAlphaToColor )
	{
		return vec4(result.a);
	}
	
	// Blending
	
	if ( sc_BlendMode_Custom )
	{				
		result = applyCustomBlend(result);
	}					
	else
	{
		result = sc_ApplyBlendModeModifications(result);
	}
	
	return result;
}
#endif
#endif


//-----------------------------------------------------------------------


//--------------------------------------------------------

SC_DECLARE_TEXTURE(renderTarget0);
SC_DECLARE_TEXTURE(renderTarget1);
SC_DECLARE_TEXTURE(renderTarget2);
SC_DECLARE_TEXTURE(renderTarget3);

//--------------------------------------------------------

uniform float       _sc_allow16TexturesMarker;
uniform highp vec3  vfxLocalAabbMin;
uniform highp vec3  vfxWorldAabbMin;
uniform highp vec3  vfxLocalAabbMax;
uniform highp vec3  vfxWorldAabbMax;
uniform highp float vfxCameraAspect;
uniform highp float vfxCameraNear;
uniform highp float vfxCameraFar;
uniform highp vec3  vfxCameraUp;
uniform highp vec3  vfxCameraForward;
uniform highp vec3  vfxCameraRight;
uniform highp mat4  vfxModelMatrix;
uniform highp mat4  vfxModelMatrixInverse;
uniform highp mat4  vfxModelViewMatrix;
uniform highp mat4  vfxModelViewMatrixInverse;
uniform highp mat4  vfxProjectionMatrix;
uniform highp mat4  vfxProjectionMatrixInverse;
uniform highp mat4  vfxModelViewProjectionMatrix;
uniform highp mat4  vfxModelViewProjectionMatrixInverse;
uniform highp mat4  vfxViewMatrix;
uniform highp mat4  vfxViewMatrixInverse;
uniform highp mat4  vfxViewProjectionMatrix;
uniform highp mat4  vfxViewProjectionMatrixInverse;
uniform       int   vfxFrame;

uniform int 		vfxOffsetInstances;		
uniform vec2 		ssTARGET_SIZE_INT;
uniform vec2 		ssTARGET_SIZE_FLOAT;
uniform float 		ssTARGET_WIDTH;
uniform int 		ssTARGET_WIDTH_INT;

//--------------------------------------------------------


#define ssTEXEL_COUNT_INT           6
#define ssTEXEL_COUNT_FLOAT         6.0
#define ssPARTICLE_COUNT_1D_INT		1500
#define ssPARTICLE_COUNT_1D_FLOAT	1500.0
#define ssPARTICLE_COUNT_2D_INT		ivec2( 341, 5 )
#define ssPARTICLE_COUNT_2D_FLOAT	float2( 341.0, 5.0 )
#define ssPARTICLE_LIFE_MAX 		float( 6.0 )
#define ssPARTICLE_TOTAL_LIFE_MAX 	float( 6.0 )
#define ssPARTICLE_BURST_GROUPS 	float( 3.0 )
#define ssPARTICLE_SPAWN_RATE 		float( 500.0 )
#define ssPARTICLE_BURST_EVERY 		float( 2.0 )
#define ssPARTICLE_DELAY_MAX        float( 0.5 )
#define ssPARTICLE_MASS_MAX         float( 100.0 )
#define ssPARTICLE_SIZE_MAX         float( 100.0 )


//--------------------------------------------------------


int    ssParticle_Index2D_to_Index1D( ivec2 Index2D )  { return Index2D.y * ssPARTICLE_COUNT_2D_INT.x + Index2D.x; }
ivec2  ssParticle_Index1D_to_Index2D( int Index1D )	   { return ivec2( Index1D % ssPARTICLE_COUNT_2D_INT.x, Index1D / ssPARTICLE_COUNT_2D_INT.x ); }
float  ssParticle_Index1D_to_Coord1D( int Index1D )    { return ( float( Index1D ) + 0.5 ) / ssPARTICLE_COUNT_1D_FLOAT; }
float  ssParticle_Index1D_to_Ratio1D( int Index1D )    { return float( Index1D ) / max( ssPARTICLE_COUNT_1D_FLOAT - 1.0, 1.0 ); }
float2 ssParticle_Index2D_to_Coord2D( ivec2 Index2D )  { return ( float2( Index2D ) + 0.5 ) / ssPARTICLE_COUNT_2D_FLOAT; }
float2 ssParticle_Index2D_to_Ratio2D( ivec2 Index2D )  { return float2( Index2D ) / max( ssPARTICLE_COUNT_2D_FLOAT - float2( 1.0, 1.0 ), float2( 1.0, 1.0 ) ); }
int    ssParticle_Coord1D_to_Index1D( float Coord1D )  { return int( Coord1D * ssPARTICLE_COUNT_1D_FLOAT ); }
ivec2  ssParticle_Coord2D_to_Index2D( float2 Coord2D ) { return ivec2( Coord2D * ssPARTICLE_COUNT_2D_FLOAT ); }	
float2 ssParticle_Index1D_to_Coord2D( int Index1D )    { return ssParticle_Index2D_to_Coord2D( ssParticle_Index1D_to_Index2D( Index1D ) ); }
float  ssParticle_Index2D_to_Coord1D( ivec2 Index2D )  { return ssParticle_Index1D_to_Coord1D( ssParticle_Index2D_to_Index1D( Index2D ) ); }
int    ssParticle_Coord2D_to_Index1D( float2 Coord2D ) { return ssParticle_Index2D_to_Index1D( ssParticle_Coord2D_to_Index2D( Coord2D ) ); }
ivec2  ssParticle_Coord1D_to_Index2D( float Coord1D )  { return ssParticle_Index1D_to_Index2D( ssParticle_Coord1D_to_Index1D( Coord1D ) ); }
float2 ssParticle_Coord1D_to_Coord2D( float Coord1D )  { return ssParticle_Index2D_to_Coord2D( ssParticle_Coord1D_to_Index2D( Coord1D ) ); }	
float  ssParticle_Coord2D_to_Coord1D( float2 Coord2D ) { return ssParticle_Index1D_to_Coord1D( ssParticle_Coord2D_to_Index1D( Coord2D ) ); }


//--------------------------------------------------------


void ssCalculateParticleSeed( inout ssParticle Particle )
{
	#if 0
	// Spawn Once - Live Forever
	//Particle.Seed = rand( vec2( Particle.Ratio1D + 0.141435 ) * 0.6789 );	
	Particle.Seed = Particle.Ratio1D * 0.976379 + 0.151235;
	ivec2 Index2D = ivec2( Particle.Index1D % 400, Particle.Index1D / 400 );	
	Particle.Seed2000 = ( vec2( Index2D ) + vec2( 1.0, 1.0 ) ) / max( vec2( 400.0, 400.0 ) - float2( 1.0, 1.0 ), float2( 1.0, 1.0 ) );
	#else
	// Any time max life is used
	float ElapsedTime = ( overrideTimeEnabled == 1 ) ? overrideTimeElapsed : sc_TimeElapsed;
	
	Particle.Seed = Particle.Ratio1D * 0.976379 + 0.151235;
	Particle.Seed = Particle.Seed + floor( ( ElapsedTime - Particle.SpawnOffset - 0.0 /*delay*/ + 0.0 /*warmup*/  + ssPARTICLE_TOTAL_LIFE_MAX * 2.0 ) / ssPARTICLE_TOTAL_LIFE_MAX ) * 4.32723;
	Particle.Seed = fract( abs( Particle.Seed ) );
	ivec2 Index2D = ivec2( Particle.Index1D % 400, Particle.Index1D / 400 );	
	Particle.Seed2000 = ( vec2( Index2D ) + vec2( 1.0, 1.0 ) ) / max( vec2( 400.0, 400.0 ) - float2( 1.0, 1.0 ), float2( 1.0, 1.0 ) );
	#endif
	
	//ssPRECISION_LIMITER( Particle.Seed )
}


//--------------------------------------------------------


void ssCalculateDynamicAttributes( int InstanceID, inout ssParticle Particle )
{
	Particle.Spawned     = false;
	Particle.Force       = vec3( 0.0 );
	Particle.Index1D     = InstanceID;
	Particle.Index2D     = ssParticle_Index1D_to_Index2D( Particle.Index1D );
	Particle.Coord1D     = ssParticle_Index1D_to_Coord1D( Particle.Index1D );
	Particle.Coord2D     = ssParticle_Index2D_to_Coord2D( Particle.Index2D );
	Particle.Ratio1D     = ssParticle_Index1D_to_Ratio1D( Particle.Index1D );
	Particle.Ratio2D     = ssParticle_Index2D_to_Ratio2D( Particle.Index2D );
	Particle.Seed        = 0.0;
	
	#if 0
	Particle.TimeShift   = rand( vec2( Particle.Ratio1D ) * vec2( 0.3452, 0.52254 ) ); // legacy random
	#else
	Particle.TimeShift   = ssRandFloat(Particle.Index1D);
	#endif			
	
	#if 0
	Particle.SpawnOffset = Particle.Ratio1D * ssPARTICLE_LIFE_MAX;	
	#elif  1
	Particle.TimeShift   = 0.0;
	Particle.SpawnOffset = float( Particle.Index1D / int( ssPARTICLE_SPAWN_RATE ) ) * ssPARTICLE_BURST_EVERY;
	#else
	Particle.TimeShift   = 0.0;
	Particle.SpawnOffset = 0.0;
	#endif
	
	ssCalculateParticleSeed( Particle );
}


//-----------------------------------------------------------------------


highp vec4  Output_Color0;
highp vec4  Output_Color1;
highp vec4  Output_Color2;
highp vec4  Output_Color3;
highp float Output_Depth;


//-----------------------------------------------------------------------


flat varying highp int Interp_Particle_Index;
varying highp vec3     Interp_Particle_Force;
varying highp vec2     Interp_Particle_Coord;

varying highp mat3 Interp_Particle_Matrix;
varying highp float4 Interp_Particle_Color;
varying highp float Interp_Particle_Mass;
varying highp float Interp_Particle_Size;
varying highp float3 Interp_Particle_Position;
varying highp float3 Interp_Particle_Velocity;
varying highp float Interp_Particle_Life;
varying highp float Interp_Particle_Age;
varying highp float Interp_Particle_Dead;



//--------------------------------------------------------


#ifdef asdf_____USE_16_BIT_TEXTURES
#define ssENCODE_TO_TARGET0( Value, Min, Max ) fragOut[0] = remap( Value, 0, 65534 );
#define ssENCODE_TO_TARGET1( Value, Min, Max ) fragOut[1] = remap( Value, 0, 65534 );
#define ssENCODE_TO_TARGET2( Value, Min, Max ) fragOut[2] = remap( Value, 0, 65534 );
#define ssENCODE_TO_TARGET3( Value, Min, Max ) fragOut[3] = remap( Value, 0, 65534 );
#else
#define ssENCODE_TO_TARGET0( Value, Min, Max ) rt0 = ssEncodeFloat32( Value, Min, Max );
#define ssENCODE_TO_TARGET1( Value, Min, Max ) rt1 = ssEncodeFloat32( Value, Min, Max );
#define ssENCODE_TO_TARGET2( Value, Min, Max ) rt2 = ssEncodeFloat32( Value, Min, Max );
#define ssENCODE_TO_TARGET3( Value, Min, Max ) rt3 = ssEncodeFloat32( Value, Min, Max );
#endif


//-----------------------------------------------------------------------


int ngsModInt( int x, int y )
{
	return x - ( ( x / y ) * y );
}


//-----------------------------------------------------------------------


void ssDecodeParticle( int InstanceID )
{
	gParticle.Position   = vec3( 0.0 );
	gParticle.Velocity   = vec3( 0.0 );
	gParticle.Color      = vec4( 0.0 );
	gParticle.Size       = 0.0; 
	gParticle.Age        = 0.0;
	gParticle.Life       = 0.0;
	gParticle.Mass       = 1.0;
	gParticle.Matrix     = mat3( 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0 );
	//gParticle.Quaternion = vec4( 0.0 );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	ssCalculateDynamicAttributes( InstanceID, gParticle );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	
	int offsetPixelId = (vfxOffsetInstances + InstanceID) * ssTEXEL_COUNT_INT;
	ivec2  Index2D = ivec2( ngsModInt( offsetPixelId, ssTARGET_WIDTH_INT ), offsetPixelId / ssTARGET_WIDTH_INT );
	float2 Coord   = ( float2( Index2D ) + 0.5 ) / float2(2048.0, ssTARGET_SIZE_FLOAT.y);	
	float2 Offset  = float2( 1.0 / 2048.0, 0.0 ); 			
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	vec2  uv    = vec2( 0.0 );
	float Scalar0 = 0.0;
	float Scalar1 = 0.0;
	float Scalar2 = 0.0;
	float Scalar3 = 0.0;
	float Scalar4 = 0.0;
	float Scalar5 = 0.0;
	float Scalar6 = 0.0;
	float Scalar7 = 0.0;
	float Scalar8 = 0.0;
	float Scalar9 = 0.0;
	float Scalar10 = 0.0;
	float Scalar11 = 0.0;
	float Scalar12 = 0.0;
	float Scalar13 = 0.0;
	float Scalar14 = 0.0;
	float Scalar15 = 0.0;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	uv = Coord + Offset * 0.0;
	{ vec4 renderTarget0Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget0, uv, 0.0); Scalar0  = renderTarget0Sample.x; Scalar1  = renderTarget0Sample.y; Scalar2  = renderTarget0Sample.z; Scalar3  = renderTarget0Sample.w; }
	{ vec4 renderTarget1Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget1, uv, 0.0); Scalar4  = renderTarget1Sample.x; Scalar5  = renderTarget1Sample.y; Scalar6  = renderTarget1Sample.z; Scalar7  = renderTarget1Sample.w; }
	{ vec4 renderTarget2Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget2, uv, 0.0); Scalar8  = renderTarget2Sample.x; Scalar9  = renderTarget2Sample.y; Scalar10 = renderTarget2Sample.z; Scalar11 = renderTarget2Sample.w; }
	{ vec4 renderTarget3Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget3, uv, 0.0); Scalar12 = renderTarget3Sample.x; Scalar13 = renderTarget3Sample.y; Scalar14 = renderTarget3Sample.z; Scalar15 = renderTarget3Sample.w; }
	
	gParticle.Matrix[0].x = ssDecodeFloat32( vec4( Scalar0, Scalar1, Scalar2, Scalar3 ), -100.0, 100.0 );
	gParticle.Matrix[0].y = ssDecodeFloat32( vec4( Scalar4, Scalar5, Scalar6, Scalar7 ), -100.0, 100.0 );
	gParticle.Matrix[0].z = ssDecodeFloat32( vec4( Scalar8, Scalar9, Scalar10, Scalar11 ), -100.0, 100.0 );
	gParticle.Matrix[1].x = ssDecodeFloat32( vec4( Scalar12, Scalar13, Scalar14, Scalar15 ), -100.0, 100.0 );
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	uv = Coord + Offset * 1.0;
	{ vec4 renderTarget0Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget0, uv, 0.0); Scalar0  = renderTarget0Sample.x; Scalar1  = renderTarget0Sample.y; Scalar2  = renderTarget0Sample.z; Scalar3  = renderTarget0Sample.w; }
	{ vec4 renderTarget1Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget1, uv, 0.0); Scalar4  = renderTarget1Sample.x; Scalar5  = renderTarget1Sample.y; Scalar6  = renderTarget1Sample.z; Scalar7  = renderTarget1Sample.w; }
	{ vec4 renderTarget2Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget2, uv, 0.0); Scalar8  = renderTarget2Sample.x; Scalar9  = renderTarget2Sample.y; Scalar10 = renderTarget2Sample.z; Scalar11 = renderTarget2Sample.w; }
	{ vec4 renderTarget3Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget3, uv, 0.0); Scalar12 = renderTarget3Sample.x; Scalar13 = renderTarget3Sample.y; Scalar14 = renderTarget3Sample.z; Scalar15 = renderTarget3Sample.w; }
	
	gParticle.Matrix[1].y = ssDecodeFloat32( vec4( Scalar0, Scalar1, Scalar2, Scalar3 ), -100.0, 100.0 );
	gParticle.Matrix[1].z = ssDecodeFloat32( vec4( Scalar4, Scalar5, Scalar6, Scalar7 ), -100.0, 100.0 );
	gParticle.Matrix[2].x = ssDecodeFloat32( vec4( Scalar8, Scalar9, Scalar10, Scalar11 ), -100.0, 100.0 );
	gParticle.Matrix[2].y = ssDecodeFloat32( vec4( Scalar12, Scalar13, Scalar14, Scalar15 ), -100.0, 100.0 );
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	uv = Coord + Offset * 2.0;
	{ vec4 renderTarget0Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget0, uv, 0.0); Scalar0  = renderTarget0Sample.x; Scalar1  = renderTarget0Sample.y; Scalar2  = renderTarget0Sample.z; Scalar3  = renderTarget0Sample.w; }
	{ vec4 renderTarget1Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget1, uv, 0.0); Scalar4  = renderTarget1Sample.x; Scalar5  = renderTarget1Sample.y; Scalar6  = renderTarget1Sample.z; Scalar7  = renderTarget1Sample.w; }
	{ vec4 renderTarget2Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget2, uv, 0.0); Scalar8  = renderTarget2Sample.x; Scalar9  = renderTarget2Sample.y; Scalar10 = renderTarget2Sample.z; Scalar11 = renderTarget2Sample.w; }
	{ vec4 renderTarget3Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget3, uv, 0.0); Scalar12 = renderTarget3Sample.x; Scalar13 = renderTarget3Sample.y; Scalar14 = renderTarget3Sample.z; Scalar15 = renderTarget3Sample.w; }
	
	gParticle.Matrix[2].z = ssDecodeFloat32( vec4( Scalar0, Scalar1, Scalar2, Scalar3 ), -100.0, 100.0 );
	gParticle.Color.x = ssDecodeFloat32( vec4( Scalar4, Scalar5, Scalar6, Scalar7 ), 0.0, 1.0 );
	gParticle.Color.y = ssDecodeFloat32( vec4( Scalar8, Scalar9, Scalar10, Scalar11 ), 0.0, 1.0 );
	gParticle.Color.z = ssDecodeFloat32( vec4( Scalar12, Scalar13, Scalar14, Scalar15 ), 0.0, 1.0 );
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	uv = Coord + Offset * 3.0;
	{ vec4 renderTarget0Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget0, uv, 0.0); Scalar0  = renderTarget0Sample.x; Scalar1  = renderTarget0Sample.y; Scalar2  = renderTarget0Sample.z; Scalar3  = renderTarget0Sample.w; }
	{ vec4 renderTarget1Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget1, uv, 0.0); Scalar4  = renderTarget1Sample.x; Scalar5  = renderTarget1Sample.y; Scalar6  = renderTarget1Sample.z; Scalar7  = renderTarget1Sample.w; }
	{ vec4 renderTarget2Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget2, uv, 0.0); Scalar8  = renderTarget2Sample.x; Scalar9  = renderTarget2Sample.y; Scalar10 = renderTarget2Sample.z; Scalar11 = renderTarget2Sample.w; }
	{ vec4 renderTarget3Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget3, uv, 0.0); Scalar12 = renderTarget3Sample.x; Scalar13 = renderTarget3Sample.y; Scalar14 = renderTarget3Sample.z; Scalar15 = renderTarget3Sample.w; }
	
	gParticle.Color.w = ssDecodeFloat32( vec4( Scalar0, Scalar1, Scalar2, Scalar3 ), 0.0, 1.0 );
	gParticle.Mass = ssDecodeFloat32( vec4( Scalar4, Scalar5, Scalar6, Scalar7 ), 0.0, 1000.0 );
	gParticle.Size = ssDecodeFloat32( vec4( Scalar8, Scalar9, Scalar10, Scalar11 ), 0.0, 100.0 );
	gParticle.Position.x = ssDecodeFloat32( vec4( Scalar12, Scalar13, Scalar14, Scalar15 ), -1000.0, 1000.0 );
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	uv = Coord + Offset * 4.0;
	{ vec4 renderTarget0Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget0, uv, 0.0); Scalar0  = renderTarget0Sample.x; Scalar1  = renderTarget0Sample.y; Scalar2  = renderTarget0Sample.z; Scalar3  = renderTarget0Sample.w; }
	{ vec4 renderTarget1Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget1, uv, 0.0); Scalar4  = renderTarget1Sample.x; Scalar5  = renderTarget1Sample.y; Scalar6  = renderTarget1Sample.z; Scalar7  = renderTarget1Sample.w; }
	{ vec4 renderTarget2Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget2, uv, 0.0); Scalar8  = renderTarget2Sample.x; Scalar9  = renderTarget2Sample.y; Scalar10 = renderTarget2Sample.z; Scalar11 = renderTarget2Sample.w; }
	{ vec4 renderTarget3Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget3, uv, 0.0); Scalar12 = renderTarget3Sample.x; Scalar13 = renderTarget3Sample.y; Scalar14 = renderTarget3Sample.z; Scalar15 = renderTarget3Sample.w; }
	
	gParticle.Position.y = ssDecodeFloat32( vec4( Scalar0, Scalar1, Scalar2, Scalar3 ), -1000.0, 1000.0 );
	gParticle.Position.z = ssDecodeFloat32( vec4( Scalar4, Scalar5, Scalar6, Scalar7 ), -1000.0, 1000.0 );
	gParticle.Velocity.x = ssDecodeFloat32( vec4( Scalar8, Scalar9, Scalar10, Scalar11 ), -1000.0, 1000.0 );
	gParticle.Velocity.y = ssDecodeFloat32( vec4( Scalar12, Scalar13, Scalar14, Scalar15 ), -1000.0, 1000.0 );
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	uv = Coord + Offset * 5.0;
	{ vec4 renderTarget0Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget0, uv, 0.0); Scalar0  = renderTarget0Sample.x; Scalar1  = renderTarget0Sample.y; Scalar2  = renderTarget0Sample.z; Scalar3  = renderTarget0Sample.w; }
	{ vec4 renderTarget1Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget1, uv, 0.0); Scalar4  = renderTarget1Sample.x; Scalar5  = renderTarget1Sample.y; Scalar6  = renderTarget1Sample.z; Scalar7  = renderTarget1Sample.w; }
	{ vec4 renderTarget2Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget2, uv, 0.0); Scalar8  = renderTarget2Sample.x; Scalar9  = renderTarget2Sample.y; Scalar10 = renderTarget2Sample.z; Scalar11 = renderTarget2Sample.w; }
	{ vec4 renderTarget3Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget3, uv, 0.0); Scalar12 = renderTarget3Sample.x; Scalar13 = renderTarget3Sample.y; Scalar14 = renderTarget3Sample.z; Scalar15 = renderTarget3Sample.w; }
	
	gParticle.Velocity.z = ssDecodeFloat32( vec4( Scalar0, Scalar1, Scalar2, Scalar3 ), -1000.0, 1000.0 );
	gParticle.Life = ssDecodeFloat32( vec4( Scalar4, Scalar5, Scalar6, Scalar7 ), 0.0, 6.0 );
	gParticle.Age = ssDecodeFloat32( vec4( Scalar8, Scalar9, Scalar10, Scalar11 ), 0.0, 6.0 );
	gParticle.Dead = ssDecodeFloat8( Scalar12, 0.0, 255.0 );
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	ssPRECISION_LIMITER2( gParticle.Velocity )
	ssPRECISION_LIMITER2( gParticle.Position )
	ssPRECISION_LIMITER2( gParticle.Color )
	ssPRECISION_LIMITER2( gParticle.Size )
	ssPRECISION_LIMITER2( gParticle.Mass )
	ssPRECISION_LIMITER2( gParticle.Life )
}


//--------------------------------------------------------


void ssEncodeParticle( float2 Coord, out vec4 rt0, out vec4 rt1, out vec4 rt2, out vec4 rt3 )
{
	#ifdef FRAGMENT_SHADER
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	int TexelIndex = int( floor( Coord.x * ssTEXEL_COUNT_FLOAT ) );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	vec4  Vector = vec4( 0.0 );
	float Scalar0 = 0.0;
	float Scalar1 = 0.0;
	float Scalar2 = 0.0;
	float Scalar3 = 0.0;
	float Scalar4 = 0.0;
	float Scalar5 = 0.0;
	float Scalar6 = 0.0;
	float Scalar7 = 0.0;
	float Scalar8 = 0.0;
	float Scalar9 = 0.0;
	float Scalar10 = 0.0;
	float Scalar11 = 0.0;
	float Scalar12 = 0.0;
	float Scalar13 = 0.0;
	float Scalar14 = 0.0;
	float Scalar15 = 0.0;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( TexelIndex == 0 )
	{
		Vector.xyzw = ssEncodeFloat32( gParticle.Matrix[0].x, -100.0, 100.0 ); Scalar0 = Vector.x; Scalar1 = Vector.y; Scalar2 = Vector.z; Scalar3 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Matrix[0].y, -100.0, 100.0 ); Scalar4 = Vector.x; Scalar5 = Vector.y; Scalar6 = Vector.z; Scalar7 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Matrix[0].z, -100.0, 100.0 ); Scalar8 = Vector.x; Scalar9 = Vector.y; Scalar10 = Vector.z; Scalar11 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Matrix[1].x, -100.0, 100.0 ); Scalar12 = Vector.x; Scalar13 = Vector.y; Scalar14 = Vector.z; Scalar15 = Vector.w;
	}
	else if ( TexelIndex == 1 )
	{
		Vector.xyzw = ssEncodeFloat32( gParticle.Matrix[1].y, -100.0, 100.0 ); Scalar0 = Vector.x; Scalar1 = Vector.y; Scalar2 = Vector.z; Scalar3 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Matrix[1].z, -100.0, 100.0 ); Scalar4 = Vector.x; Scalar5 = Vector.y; Scalar6 = Vector.z; Scalar7 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Matrix[2].x, -100.0, 100.0 ); Scalar8 = Vector.x; Scalar9 = Vector.y; Scalar10 = Vector.z; Scalar11 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Matrix[2].y, -100.0, 100.0 ); Scalar12 = Vector.x; Scalar13 = Vector.y; Scalar14 = Vector.z; Scalar15 = Vector.w;
	}
	else if ( TexelIndex == 2 )
	{
		Vector.xyzw = ssEncodeFloat32( gParticle.Matrix[2].z, -100.0, 100.0 ); Scalar0 = Vector.x; Scalar1 = Vector.y; Scalar2 = Vector.z; Scalar3 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Color.x, 0.0, 1.0 );          Scalar4 = Vector.x; Scalar5 = Vector.y; Scalar6 = Vector.z; Scalar7 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Color.y, 0.0, 1.0 );          Scalar8 = Vector.x; Scalar9 = Vector.y; Scalar10 = Vector.z; Scalar11 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Color.z, 0.0, 1.0 );          Scalar12 = Vector.x; Scalar13 = Vector.y; Scalar14 = Vector.z; Scalar15 = Vector.w;
	}
	else if ( TexelIndex == 3 )
	{
		Vector.xyzw = ssEncodeFloat32( gParticle.Color.w, 0.0, 1.0 );           Scalar0 = Vector.x; Scalar1 = Vector.y; Scalar2 = Vector.z; Scalar3 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Mass, 0.0, 1000.0 );           Scalar4 = Vector.x; Scalar5 = Vector.y; Scalar6 = Vector.z; Scalar7 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Size, 0.0, 100.0 );            Scalar8 = Vector.x; Scalar9 = Vector.y; Scalar10 = Vector.z; Scalar11 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Position.x, -1000.0, 1000.0 ); Scalar12 = Vector.x; Scalar13 = Vector.y; Scalar14 = Vector.z; Scalar15 = Vector.w;
	}
	else if ( TexelIndex == 4 )
	{
		Vector.xyzw = ssEncodeFloat32( gParticle.Position.y, -1000.0, 1000.0 ); Scalar0 = Vector.x; Scalar1 = Vector.y; Scalar2 = Vector.z; Scalar3 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Position.z, -1000.0, 1000.0 ); Scalar4 = Vector.x; Scalar5 = Vector.y; Scalar6 = Vector.z; Scalar7 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Velocity.x, -1000.0, 1000.0 ); Scalar8 = Vector.x; Scalar9 = Vector.y; Scalar10 = Vector.z; Scalar11 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Velocity.y, -1000.0, 1000.0 ); Scalar12 = Vector.x; Scalar13 = Vector.y; Scalar14 = Vector.z; Scalar15 = Vector.w;
	}
	else if ( TexelIndex == 5 )
	{
		Vector.xyzw = ssEncodeFloat32( gParticle.Velocity.z, -1000.0, 1000.0 ); Scalar0 = Vector.x; Scalar1 = Vector.y; Scalar2 = Vector.z; Scalar3 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Life, 0.0, 6.0 );              Scalar4 = Vector.x; Scalar5 = Vector.y; Scalar6 = Vector.z; Scalar7 = Vector.w;
		Vector.xyzw = ssEncodeFloat32( gParticle.Age, 0.0, 6.0 );               Scalar8 = Vector.x; Scalar9 = Vector.y; Scalar10 = Vector.z; Scalar11 = Vector.w;
		Vector.x = ssEncodeFloat8( gParticle.Dead, 0.0, 255.0 );                Scalar12 = Vector.x;
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	rt0 = vec4( Scalar0,  Scalar1,  Scalar2,  Scalar3 ); 
	rt1 = vec4( Scalar4,  Scalar5,  Scalar6,  Scalar7 ); 
	rt2 = vec4( Scalar8,  Scalar9,  Scalar10, Scalar11 ); 
	rt3 = vec4( Scalar12, Scalar13, Scalar14, Scalar15 );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	//rt0 = rt1 = rt2 = rt3 = vec4( float( TexelIndex ) / max( ssTEXEL_COUNT_FLOAT - 1.0, 1.0 ), 0.0, 0.0, 1.0 );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	#endif
}


//-----------------------------------------------------------------------

#ifndef saturate // HACK 05/15/2019: SAMPLETEX() uses saturate(), but core doesn't define it. This can be removed after Core 10.59.
#define saturate(A) clamp(A, 0.0, 1.0)
#endif

//-----------------------------------------------------------------------



// Uniforms ( Ports )

#if defined( STUDIO )
uniform NF_PRECISION float Port_AlphaTestThreshold_N039;
uniform NF_PRECISION float Port_Input0_N011;
uniform NF_PRECISION float2 Port_Import_N091;
uniform NF_PRECISION float2 Port_Center_N012;
uniform NF_PRECISION float Port_Input1_N013;
uniform NF_PRECISION float Port_Input1_N014;
uniform NF_PRECISION float Port_Input1_N017;
uniform NF_PRECISION float Port_Input0_N023;
uniform NF_PRECISION float Port_Input1_N057;
uniform NF_PRECISION float Port_Value0_N055;
uniform NF_PRECISION float Port_Value1_N055;
uniform NF_PRECISION float Port_Value2_N055;
uniform NF_PRECISION float Port_Default_N055;
uniform NF_PRECISION float Port_Import_N024;
uniform NF_PRECISION float Port_Input1_N027;
uniform NF_PRECISION float Port_Input2_N027;
uniform NF_PRECISION float Port_Input1_N030;
uniform NF_PRECISION float Port_RangeMinA_N053;
uniform NF_PRECISION float Port_Import_N003;
uniform NF_PRECISION float Port_RangeMinB_N053;
uniform NF_PRECISION float Port_RangeMaxB_N053;
uniform NF_PRECISION float Port_Input1_N054;
#endif	



//-----------------------------------------------------------------------

varying float gParticlesDebug;
varying vec2 ParticleUV;

//-----------------------------------------------------------------------

#ifdef VERTEX_SHADER

//-----------------------------------------------------------------------

//----------

// Globals

struct ssGlobals
{
	float gTimeElapsed;
	float gTimeDelta;
	float gTimeElapsedShifted;
	
	
};

ssGlobals tempGlobals;
#define scCustomCodeUniform

//-----------------------------------------------------------------------

void main() 
{
	NF_SETUP_PREVIEW_VERTEX()
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	sc_Vertex_t v = sc_LoadVertexAttributes();
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( sc_IsEditor )
	{
		v.position.x += _sc_allow16TexturesMarker;
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	#if !defined(MOBILE)
	if ( NF_DISABLE_VERTEX_CHANGES() )
	v.texture0.x = 1.0 - v.texture0.x; // fix to flip the preview quad UVs horizontally
	#endif
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	int InstanceID = sc_LocalInstanceID;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( InstanceID >= ssPARTICLE_COUNT_1D_INT )
	{
		sc_SetClipPosition( vec4( 0.0 ) );
		return;
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	ssDecodeParticle( InstanceID );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	ssGlobals Globals;	
	Globals.gTimeElapsed        = ( overrideTimeEnabled == 1 ) ? overrideTimeElapsed : sc_TimeElapsed;
	Globals.gTimeDelta          = ( overrideTimeEnabled == 1 ) ? overrideTimeDelta : max( sc_TimeDelta, ssDELTA_TIME_MIN );
	Globals.gTimeElapsedShifted = Globals.gTimeElapsed - gParticle.TimeShift * Globals.gTimeDelta - 0.0;
	
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( ( gParticle.Dead > 16.0 || gParticle.Size < 0.00001 || gParticle.Age >= gParticle.Life ) )
	{
		sc_SetClipPosition( vec4( 0.0 ) );
		return;
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	// Transform from Update to Output space
	
	
	
	gParticle.Matrix = mat3( ngsModelMatrix ) * gParticle.Matrix;
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	#ifdef VFX_GEOMETRY_MESH
	{
		varPos     = gParticle.Position + mat3( gParticle.Matrix ) * v.position.xyz * gParticle.Size;	
		varNormal  = mat3( gParticle.Matrix ) * v.normal;
		varTangent.xyz = mat3( gParticle.Matrix ) * v.tangent;
		varTangent.w = 1.0; 				
	}
	#else
	{
		varPos     = gParticle.Position + mat3( gParticle.Matrix ) * vec3( v.position.x * gParticle.Size, v.position.y * gParticle.Size, 0.0 );
		varNormal      = mat3( gParticle.Matrix ) * float3( 0.0, 0.0, 1.0 );
		varTangent.xyz = mat3( gParticle.Matrix ) * float3( 1.0, 0.0, 0.0 );
		varTangent.w = 1.0;
	}
	#endif
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	varTex01 = vec4( v.texture0, v.texture1 );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	// Execution Code
	
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( UseViewSpaceDepthVariant && ( sc_OITDepthGatherPass || sc_OITCompositingPass || sc_OITDepthBoundsPass ) )
	{
		float4 ViewPosition = ngsViewMatrix * vec4( varPos, 1.0 );
		varViewSpaceDepth = -ViewPosition.z; 
		sc_SetClipPosition( ngsProjectionMatrix * ViewPosition );
	}
	else
	{
		vec4 clipPosition = ngsViewProjectionMatrix * vec4( varPos, 1.0 );
		clipPosition = applyDepthAlgorithm( clipPosition );
		sc_SetClipPosition( clipPosition );
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	// Interpolation Code
	
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	// Debug
	
	#if 0
	{
		if ( sc_LocalInstanceID == 0 )
		{
			sc_SetClipPosition( vec4( vec2( 0.8, -0.85 ) - ( v.texture0 ) * vec2( 0.4, -0.23 ) * 3.0, 1.0, 1.0 ) );
			varTex0 = v.texture0;
			gParticlesDebug = 1.0;
		}
		else
		{
			gParticlesDebug = -1.0;
		}
	}
	#endif
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	Interp_Particle_Index = sc_LocalInstanceID;
	Interp_Particle_Force = gParticle.Force;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	Interp_Particle_Matrix = gParticle.Matrix;
	Interp_Particle_Color = gParticle.Color;
	Interp_Particle_Mass = gParticle.Mass;
	Interp_Particle_Size = gParticle.Size;
	Interp_Particle_Position = gParticle.Position;
	Interp_Particle_Velocity = gParticle.Velocity;
	Interp_Particle_Life = gParticle.Life;
	Interp_Particle_Age = gParticle.Age;
	Interp_Particle_Dead = gParticle.Dead;
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	#if !defined(MOBILE)
	if ( NF_DISABLE_VERTEX_CHANGES() )
	{
		if ( sc_IsEditor ) 
		{
			v.position.x += _sc_allow16TexturesMarker;
		}
		
		// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
		
		sc_SetClipPosition( ngsViewProjectionMatrix * float4( v.position.xyz, 1.0 ) );
	}				
	#endif
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	NF_PREVIEW_OUTPUT_VERTEX()
}

//-----------------------------------------------------------------------

#endif // #ifdef VERTEX_SHADER

//-----------------------------------------------------------------------

#ifdef FRAGMENT_SHADER

//-----------------------------------------------------------------------------

//----------

// Globals

struct ssGlobals
{
	float gTimeElapsed;
	float gTimeDelta;
	float gTimeElapsedShifted;
	
	float2 Surface_UVCoord0;
};

ssGlobals tempGlobals;
#define scCustomCodeUniform	

//----------

// Functions

#define Node39_Output_Quad_World_Space( AlphaTestThreshold, Globals ) /* does nothing */
#define Node20_Particle_Get_Attribute( Value, Globals ) Value = gParticle.Color
#define Node4_Surface_UV_Coord( UVCoord, Globals ) UVCoord = Globals.Surface_UVCoord0
#define Node91_Float_Import( Import, Value, Globals ) Value = clamp( Import, 0.0, 10.0 )
#define Node11_Divide( Input0, Input1, Output, Globals ) Output = float2(Input0) / (Input1 + 1.234e-6)
#define Node12_Scale_Coords( CoordsIn, Scale, Center, CoordsOut, Globals ) CoordsOut.xy = ( CoordsIn.xy - Center ) * Scale + Center
#define Node13_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * float2(Input1)
#define Node14_Subtract( Input0, Input1, Output, Globals ) Output = Input0 - float2(Input1)
#define Node79_Swizzle( Input, Output, Globals ) Output = Input
#define Node16_Swizzle( Input, Output, Globals ) Output = Input.y
#define Node17_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node18_ATan2( Input0, Input1, Output, Globals ) Output = atan( Input1, Input0 )
#define Node45_PI( Output, Globals ) Output = 3.1415926535897932
#define Node23_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node56_Particle_Get_Attribute( Value, Globals ) Value = float( gParticle.Index1D )
#define Node57_Mod( Input0, Input1, Output, Globals ) Output = mod( Input0, Input1 )
void Node55_Switch( in float Switch, in float Value0, in float Value1, in float Value2, in float Default, out float Result, ssGlobals Globals )
{ 
	/* Input port: "Switch"  */
	
	{
		float Value_N56 = 0.0; Node56_Particle_Get_Attribute( Value_N56, Globals );
		float Output_N57 = 0.0; Node57_Mod( Value_N56, NF_PORT_CONSTANT( float( 3.0 ), Port_Input1_N057 ), Output_N57, Globals );
		
		Switch = Output_N57;
	}
	Switch = floor( Switch );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	
	if ( ( Switch ) == 0.0 )
	{
		
		Result = Value0;
	}
	else if ( ( Switch ) == 1.0 )
	{
		
		Result = Value1;
	}
	else if ( ( Switch ) == 2.0 )
	{
		
		Result = Value2;
	}
	else
	{
		
		Result = Default;
	}
}
#define Node24_Float_Import( Import, Value, Globals ) Value = Import
#define Node26_Floor( Input0, Output, Globals ) Output = floor( Input0 )
#define Node27_Clamp( Input0, Input1, Input2, Output, Globals ) Output = clamp( Input0, Input1, Input2 )
#define Node28_Divide( Input0, Input1, Output, Globals ) Output = Input0 / (Input1 + 1.234e-6)
#define Node29_Divide( Input0, Input1, Output, Globals ) Output = Input0 / (Input1 + 1.234e-6)
#define Node30_Add( Input0, Input1, Output, Globals ) Output = Input0 + Input1
#define Node31_Floor( Input0, Output, Globals ) Output = floor( Input0 )
#define Node46_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node49_Subtract( Input0, Input1, Output, Globals ) Output = Input0 - Input1
#define Node50_Cos( Input0, Output, Globals ) Output = cos( Input0 )
#define Node51_Length( Input0, Output, Globals ) Output = length( Input0 )
#define Node52_Multiply( Input0, Input1, Output, Globals ) Output = Input0 * Input1
#define Node74_One_Minus( Input0, Output, Globals ) Output = 1.0 - Input0
#define Node3_Float_Import( Import, Value, Globals ) Value = clamp( Import, 0.0, 1.0 )
#define Node53_Remap( ValueIn, ValueOut, RangeMinA, RangeMaxA, RangeMinB, RangeMaxB, Globals ) ValueOut = ( ( ValueIn - RangeMinA ) / ( RangeMaxA - RangeMinA ) ) * ( RangeMaxB - RangeMinB ) + RangeMinB
#define Node78_Float_Export( Value, Export, Globals ) Export = Value
#define Node54_Is_Less( Input0, Input1, Output, Globals ) Output = ssSmaller( Input0, Input1 )
void Node1_Discard( in float4 Input0, in float Input1, out float4 Output, ssGlobals Globals )
{ 
	Output = Input0;
	
	#ifdef FRAGMENT_SHADER
	if ( Input1 * 1.0 != 0.0 )
	{
		discard;
	}	
	#endif
}
void Node21_Set_Color_Pixel( in float4 Color, ssGlobals Globals )
{ 
	#ifdef FRAGMENT_SHADER
	Output_Color0 = Color;
	#endif
}

//-----------------------------------------------------------------------

vec3  ngsTempNormal;
vec4  ngsTempTangent;
vec2  ngsTempUVCoord0;
vec2  ngsTempUVCoord1;
float ngsTempBinormalSign;

//-----------------------------------------------------------------------

void main() 
{
	sc_DiscardStereoFragment();
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	NF_SETUP_PREVIEW_PIXEL()
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	vec4 renderTarget0Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget0, vec2( 0.5 ), 0.0);
	vec4 renderTarget1Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget1, vec2( 0.5 ), 0.0);
	vec4 renderTarget2Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget2, vec2( 0.5 ), 0.0);
	vec4 renderTarget3Sample = SC_SAMPLE_TEX_LEVEL_R(renderTarget3, vec2( 0.5 ), 0.0);
	
	if ( dot( renderTarget0Sample + renderTarget1Sample + renderTarget2Sample + renderTarget3Sample, vec4( 0.2542325 ) ) == 0.3423183476 )
	{
		discard; // hack so the texture filter modes don't get wiped out
	}
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	ngsTempNormal.xyz  = ( sc_GetGlFrontFacing() ) ? varNormal.xyz  : -varNormal.xyz;
	ngsTempTangent.xyz = ( sc_GetGlFrontFacing() ) ? varTangent.xyz : -varTangent.xyz;
	ngsTempUVCoord0 = ( sc_GetGlFrontFacing() ) ? varTex01.xy : vec2( 1.0-varTex01.x, varTex01.y );
	ngsTempUVCoord1 = ( sc_GetGlFrontFacing() ) ? varTex01.zw : vec2( 1.0-varTex01.z, varTex01.w );
	ngsTempBinormalSign = ( sc_GetGlFrontFacing() ) ? 1.0 : -1.0;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	gParticle.Matrix = Interp_Particle_Matrix;
	gParticle.Color = Interp_Particle_Color;
	gParticle.Mass = Interp_Particle_Mass;
	gParticle.Size = Interp_Particle_Size;
	gParticle.Position = Interp_Particle_Position;
	gParticle.Velocity = Interp_Particle_Velocity;
	gParticle.Life = Interp_Particle_Life;
	gParticle.Age = Interp_Particle_Age;
	gParticle.Dead = Interp_Particle_Dead;
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	ssGlobals Globals;	
	Globals.gTimeElapsed        = ( overrideTimeEnabled == 1 ) ? overrideTimeElapsed : sc_TimeElapsed;
	Globals.gTimeDelta          = ( overrideTimeEnabled == 1 ) ? overrideTimeDelta : max( sc_TimeDelta, ssDELTA_TIME_MIN );
	Globals.gTimeElapsedShifted = Globals.gTimeElapsed - gParticle.TimeShift * Globals.gTimeDelta - 0.0;
	Globals.Surface_UVCoord0 = ngsTempUVCoord0;
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	ssCalculateDynamicAttributes( Interp_Particle_Index, gParticle );
	Globals.gTimeElapsedShifted = Globals.gTimeElapsed - gParticle.TimeShift * Globals.gTimeDelta - 0.0; // fix for TimeShift not being setup yet...
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	Output_Color0 = gParticle.Color;
	Output_Color1 = vec4( 0.0 );
	Output_Color2 = vec4( 0.0 );
	Output_Color3 = vec4( 0.0 );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	// Execution Code
	
	Node39_Output_Quad_World_Space( NF_PORT_CONSTANT( float( 0.0 ), Port_AlphaTestThreshold_N039 ), Globals );
	float4 Value_N20 = float4(0.0); Node20_Particle_Get_Attribute( Value_N20, Globals );
	float2 UVCoord_N4 = float2(0.0); Node4_Surface_UV_Coord( UVCoord_N4, Globals );
	float2 Value_N91 = float2(0.0); Node91_Float_Import( NF_PORT_CONSTANT( float2( 0.5, 0.5 ), Port_Import_N091 ), Value_N91, Globals );
	float2 Output_N11 = float2(0.0); Node11_Divide( NF_PORT_CONSTANT( float( 1.0 ), Port_Input0_N011 ), Value_N91, Output_N11, Globals );
	float2 CoordsOut_N12 = float2(0.0); Node12_Scale_Coords( UVCoord_N4, Output_N11, NF_PORT_CONSTANT( float2( 0.5, 0.5 ), Port_Center_N012 ), CoordsOut_N12, Globals );
	float2 Output_N13 = float2(0.0); Node13_Multiply( CoordsOut_N12, NF_PORT_CONSTANT( float( 2.0 ), Port_Input1_N013 ), Output_N13, Globals );
	float2 Output_N14 = float2(0.0); Node14_Subtract( Output_N13, NF_PORT_CONSTANT( float( 1.0 ), Port_Input1_N014 ), Output_N14, Globals );
	float Output_N79 = 0.0; Node79_Swizzle( Output_N14.x, Output_N79, Globals );
	float Output_N16 = 0.0; Node16_Swizzle( Output_N14, Output_N16, Globals );
	float Output_N17 = 0.0; Node17_Multiply( Output_N16, NF_PORT_CONSTANT( float( -1.0 ), Port_Input1_N017 ), Output_N17, Globals );
	float Output_N18 = 0.0; Node18_ATan2( Output_N79, Output_N17, Output_N18, Globals );
	float Output_N45 = 0.0; Node45_PI( Output_N45, Globals );
	float Output_N23 = 0.0; Node23_Multiply( NF_PORT_CONSTANT( float( 2.0 ), Port_Input0_N023 ), Output_N45, Output_N23, Globals );
	float Result_N55 = 0.0; Node55_Switch( float( 0.0 ), NF_PORT_CONSTANT( float( 0.003 ), Port_Value0_N055 ), NF_PORT_CONSTANT( float( 4.0 ), Port_Value1_N055 ), NF_PORT_CONSTANT( float( 100.0 ), Port_Value2_N055 ), NF_PORT_CONSTANT( float( 4.0 ), Port_Default_N055 ), Result_N55, Globals );
	float Value_N24 = 0.0; Node24_Float_Import( Result_N55, Value_N24, Globals );
	float Output_N26 = 0.0; Node26_Floor( Value_N24, Output_N26, Globals );
	float Output_N27 = 0.0; Node27_Clamp( Output_N26, NF_PORT_CONSTANT( float( 3.0 ), Port_Input1_N027 ), NF_PORT_CONSTANT( float( 50.0 ), Port_Input2_N027 ), Output_N27, Globals );
	float Output_N28 = 0.0; Node28_Divide( Output_N23, Output_N27, Output_N28, Globals );
	float Output_N29 = 0.0; Node29_Divide( Output_N18, Output_N28, Output_N29, Globals );
	float Output_N30 = 0.0; Node30_Add( Output_N29, NF_PORT_CONSTANT( float( 0.5 ), Port_Input1_N030 ), Output_N30, Globals );
	float Output_N31 = 0.0; Node31_Floor( Output_N30, Output_N31, Globals );
	float Output_N46 = 0.0; Node46_Multiply( Output_N31, Output_N28, Output_N46, Globals );
	float Output_N49 = 0.0; Node49_Subtract( Output_N46, Output_N18, Output_N49, Globals );
	float Output_N50 = 0.0; Node50_Cos( Output_N49, Output_N50, Globals );
	float Output_N51 = 0.0; Node51_Length( Output_N14, Output_N51, Globals );
	float Output_N52 = 0.0; Node52_Multiply( Output_N50, Output_N51, Output_N52, Globals );
	float Output_N74 = 0.0; Node74_One_Minus( Output_N52, Output_N74, Globals );
	float Value_N3 = 0.0; Node3_Float_Import( NF_PORT_CONSTANT( float( 0.0 ), Port_Import_N003 ), Value_N3, Globals );
	float ValueOut_N53 = 0.0; Node53_Remap( Output_N74, ValueOut_N53, NF_PORT_CONSTANT( float( 0.0 ), Port_RangeMinA_N053 ), Value_N3, NF_PORT_CONSTANT( float( 0.0 ), Port_RangeMinB_N053 ), NF_PORT_CONSTANT( float( 1.0 ), Port_RangeMaxB_N053 ), Globals );
	float Export_N78 = 0.0; Node78_Float_Export( ValueOut_N53, Export_N78, Globals );
	float Output_N54 = 0.0; Node54_Is_Less( Export_N78, NF_PORT_CONSTANT( float( 0.01 ), Port_Input1_N054 ), Output_N54, Globals );
	float4 Output_N1 = float4(0.0); Node1_Discard( Value_N20, Output_N54, Output_N1, Globals );
	Node21_Set_Color_Pixel( Output_N1, Globals );
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	// Alpha Test
	
	#if 0
	
	if ( Output_Color0.a < AlphaTestFunction_N39( Globals ) )
	{
		discard;
	}
	
	#endif
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	// Alpha to Coverage
	
	#ifdef ENABLE_STIPPLE_PATTERN_TEST
	
	vec2  localCoord = floor( mod( sc_GetGlFragCoord().xy, vec2( 4.0 ) ) );
	float threshold  = ( mod( dot( localCoord, vec2( 4.0, 1.0 ) ) * 9.0, 16.0 ) + 1.0 ) / 17.0;
	
	if ( Output_Color0.a < threshold )
	{
		discard;
	}
	
	#endif
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	Output_Color0 = ngsPixelShader( Output_Color0 );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	#if defined( sc_ProjectiveShadowsCaster )
	
	if ( Output_Color0.a < 1.0 / 256.0 )
	discard;
	
	vec4 CasterColor = evaluateShadowCasterColor( Output_Color0 );
	
	sc_writeFragData0( CasterColor );
	
	#else
	
	#ifdef STUDIO
	vec4 Cost = getPixelRenderingCost();
	if ( Cost.w > 0.0 )
	Output_Color0 = Cost;
	#endif
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	sc_writeFragData0( Output_Color0 );
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	processOIT( Output_Color0 );
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	
	
	#endif
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	NF_PREVIEW_OUTPUT_PIXEL()
	
	// -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
	
	if ( sc_IsEditor )
	{
		//sc_writeFragData0( sc_readFragData0() + _sc_allow16TexturesMarker );
	}
}

#endif //FRAGMENT SHADER
