#version 120
#include "lib/colorRange.glsl"

#define BLOOM
	#define BLOOM_MULT 5.0 //[0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 5.0 6.0 7.0 8.0] basic multiplier

#define VIGNETTE //A dark tint around the screen
	#define VIGNETTE_MULT 1.0 //[0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 5.0 6.0 7.0 8.0] basic multiplier

#define SCREEN_REFRACTION //Refracts the sceen underwater and when rain is hitting the camera.
	#define SCREEN_REFRACTION_MULT 1.0 //[0.5 1.0 1.5 2.0]

#define BRIGHTNESS 1.0 //[0.0 0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define GAMMA 1.0 //[0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define CONTRAST 1.0 //[0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define LIFT 0.0 //[0.05 0.1 0.15 0.2]
#define INVERSE_LIFT 0.020 //[0.020 0.05 0.075 0.1]

#define RED_MULT 1.0 		//[0.0 0.25 0.5 0.75 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]
#define GREEN_MULT 1.0 		//[0.0 0.25 0.5 0.75 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]
#define BLUE_MULT 1.0 		//[0.0 0.25 0.5 0.75 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0]

//#define DOF

const bool gcolorMipmapEnabled = true;

varying vec4 texcoord;

uniform sampler2D gcolor;
uniform sampler2D gdepthtex;
uniform sampler2D composite;
uniform sampler2D noisetex;
uniform sampler2D colortex7;

uniform float frameTimeCounter;

uniform float viewWidth;
uniform float aspectRatio;

uniform float rainStrength;
uniform ivec2 eyeBrightnessSmooth;

uniform float far;
uniform float near;

uniform int isEyeInWater;

float dynamicExposure = mix(1.0,0.0,(pow(eyeBrightnessSmooth.y / 240.0f, 3.0f)));

float getRainDrops(){

	float noiseTexture = texture2D(noisetex, vec2(texcoord.s, texcoord.t / 5.5) * 0.015 + vec2(0.0,frameTimeCounter) * 0.0005).x;
	noiseTexture += texture2D(noisetex, vec2(texcoord.s, texcoord.t / 5.5) * 0.03 + vec2(0.0,frameTimeCounter) * 0.002).x * 0.5;

	noiseTexture = min(max(noiseTexture - 1.1,0.0) * 10.0, 1.0);
	noiseTexture *= clamp((eyeBrightnessSmooth.y-220)/15.0,0.0,1.0);

	return noiseTexture;
}

vec2 customTexcoord(){
	vec2 texCoord = texcoord.st;

	float noiseTexture = texture2D(noisetex, texcoord.st * 0.03 + frameTimeCounter * 0.001).x;

	vec2 wavyness = (vec2(noiseTexture, noiseTexture) * 2.0 - 1.0) * mix(getRainDrops() * rainStrength * 2.0,1.0,isEyeInWater) * 0.0075;

	#ifdef SCREEN_REFRACTION
		return texCoord + wavyness * SCREEN_REFRACTION_MULT;
	#else
		return texCoord;
	#endif
}

vec2 newTexcoord = customTexcoord();

vec3 tonemap(vec3 color)
{
	float a = BRIGHTNESS;
	float b = GAMMA;
	float c = CONTRAST;
	float d = LIFT;
	float e = INVERSE_LIFT;

	color = mix(color, vec3(0.33333), 1.2 - c);

	color = pow(color, vec3(2.2)) * pow(1.5, 2.2) * a;

	vec3 x = max(vec3(0.0),color - INVERSE_LIFT) + LIFT;
	vec3 outCol = pow((x * (6.2 * x + 0.4)) / (x * (6.2 * x + 1.56) + 0.2), vec3(b));
	return outCol;
}

vec3 reinhardTonemap(vec3 color)
{
	return color / (1.0 + color);
}

float ld(float dist) {
    return (2.0 * near) / (far + near - dist * (far - near));
}

#ifdef BLOOM

	vec3 getBloom(in vec2 bCoord){

		vec3 blur = vec3(0.0);

		float bloomPowMult = mix(1.0, 0.8, float(isEyeInWater));
		bloomPowMult = mix(bloomPowMult, 0.8, rainStrength * (1.0 - float(isEyeInWater)) * (1.0 - dynamicExposure));

		blur += pow(texture2D(composite,bCoord/pow(2.0,2.0) + vec2(0.0,0.0)).rgb,vec3(2.1) * bloomPowMult)*pow(8.0,1.0);
		blur += pow(texture2D(composite,bCoord/pow(2.0,3.0) + vec2(0.3,0.0)).rgb,vec3(2.1) * bloomPowMult)*pow(7.0,1.0);
		blur += pow(texture2D(composite,bCoord/pow(2.0,4.0) + vec2(0.0,0.3)).rgb,vec3(2.1) * bloomPowMult)*pow(6.0,1.0);
		blur += pow(texture2D(composite,bCoord/pow(2.0,5.0) + vec2(0.1,0.3)).rgb,vec3(2.1) * bloomPowMult)*pow(5.0,1.0);
		blur += pow(texture2D(composite,bCoord/pow(2.0,6.0) + vec2(0.2,0.3)).rgb,vec3(2.1) * bloomPowMult)*pow(4.0,1.0);

		return blur * 0.25;
	}

#endif

#ifdef VIGNETTE
	vec3 getVignette(vec3 color, vec2 pos){
		float factor = distance(pos, vec2(0.5));

		factor = pow(factor, 4.4);
		factor *= VIGNETTE_MULT;

		factor = clamp(1.0 - factor, 0.0, 1.0);

		return color * factor;
	}
#endif

#ifdef DOF
	//hexagon pattern
	const vec2 hex_offsets[60] = vec2[60]  (  vec2( 0.0000, 0.2500 ),
								vec2( -0.2165, 0.1250 ),
								vec2( -0.2165, -0.1250 ),
								vec2( -0.0000, -0.2500 ),
								vec2( 0.2165, -0.1250 ),
								vec2( 0.2165, 0.1250 ),
								vec2( 0.0000, 0.5000 ),
								vec2( -0.2500, 0.4330 ),
								vec2( -0.4330, 0.2500 ),
								vec2( -0.5000, 0.0000 ),
								vec2( -0.4330, -0.2500 ),
								vec2( -0.2500, -0.4330 ),
								vec2( -0.0000, -0.5000 ),
								vec2( 0.2500, -0.4330 ),
								vec2( 0.4330, -0.2500 ),
								vec2( 0.5000, -0.0000 ),
								vec2( 0.4330, 0.2500 ),
								vec2( 0.2500, 0.4330 ),
								vec2( 0.0000, 0.7500 ),
								vec2( -0.2565, 0.7048 ),
								vec2( -0.4821, 0.5745 ),
								vec2( -0.6495, 0.3750 ),
								vec2( -0.7386, 0.1302 ),
								vec2( -0.7386, -0.1302 ),
								vec2( -0.6495, -0.3750 ),
								vec2( -0.4821, -0.5745 ),
								vec2( -0.2565, -0.7048 ),
								vec2( -0.0000, -0.7500 ),
								vec2( 0.2565, -0.7048 ),
								vec2( 0.4821, -0.5745 ),
								vec2( 0.6495, -0.3750 ),
								vec2( 0.7386, -0.1302 ),
								vec2( 0.7386, 0.1302 ),
								vec2( 0.6495, 0.3750 ),
								vec2( 0.4821, 0.5745 ),
								vec2( 0.2565, 0.7048 ),
								vec2( 0.0000, 1.0000 ),
								vec2( -0.2588, 0.9659 ),
								vec2( -0.5000, 0.8660 ),
								vec2( -0.7071, 0.7071 ),
								vec2( -0.8660, 0.5000 ),
								vec2( -0.9659, 0.2588 ),
								vec2( -1.0000, 0.0000 ),
								vec2( -0.9659, -0.2588 ),
								vec2( -0.8660, -0.5000 ),
								vec2( -0.7071, -0.7071 ),
								vec2( -0.5000, -0.8660 ),
								vec2( -0.2588, -0.9659 ),
								vec2( -0.0000, -1.0000 ),
								vec2( 0.2588, -0.9659 ),
								vec2( 0.5000, -0.8660 ),
								vec2( 0.7071, -0.7071 ),
								vec2( 0.8660, -0.5000 ),
								vec2( 0.9659, -0.2588 ),
								vec2( 1.0000, -0.0000 ),
								vec2( 0.9659, 0.2588 ),
								vec2( 0.8660, 0.5000 ),
								vec2( 0.7071, 0.7071 ),
								vec2( 0.5000, 0.8660 ),
								vec2( 0.2588, 0.9659 ));

	vec3 getDof(inout vec3 color){

	const float focal = 0.05;
	float aperture = 0.002;
	const float sizemult = 50.0;

		float DoFGamma = 4.545;
				//Calculate pixel Circle of Confusion that will be used for bokeh depth of field
				float z = ld(texture2D(gdepthtex, vec2(newTexcoord.st)).r)*far;
				float focus = ld(texture2D(gdepthtex, vec2(0.5)).r)*far;
				float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,(1.0 / viewWidth)*5.0);
				vec4 sample = vec4(0.0);
				vec3 bcolor = vec3(0.0);
				float nb = 0.0;
				vec2 bcoord = vec2(0.0);

				for ( int i = 0; i < 60; i++) {
					sample = texture2D(gcolor, newTexcoord.xy + hex_offsets[i]*pcoc*vec2(1.0,aspectRatio),abs(pcoc * 125.0));

					sample.rgb *= MAX_COLOR_RANGE;

					bcolor += pow(sample.rgb, vec3(DoFGamma));
				}
		color.rgb = pow(bcolor/60.0, vec3(1.0/DoFGamma));

	return color;
	}
#endif

void main(){

	vec3 color = texture2D(gcolor, newTexcoord.st).rgb * MAX_COLOR_RANGE;

#ifdef DOF
	color = getDof(color);
#endif

	#ifdef BLOOM
		color.rgb = pow(color.rgb, vec3(2.2));
		color += pow(reinhardTonemap(getBloom(newTexcoord.st)) * MAX_COLOR_RANGE * 0.02 * BLOOM_MULT / reinhardTonemap(vec3(1.0)), vec3(2.2)) * 3.0;
		color.rgb = pow(color.rgb, vec3(0.4545));
	#endif

	color.r *= RED_MULT;
	color.g *= GREEN_MULT;
	color.b *= BLUE_MULT;

	color.rgb = tonemap(color.rgb);

	#ifdef VIGNETTE
		color = getVignette(color, newTexcoord);
	#endif

	gl_FragColor = vec4(color, 1.0);
}
