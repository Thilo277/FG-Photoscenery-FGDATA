// -*-C++-*-
#version 120

varying float fogFactor;
varying vec3 hazeColor;

varying float flogz;

uniform float terminator;
uniform float altitude;
uniform float cloud_self_shading;
uniform float moonlight;
uniform float air_pollution;
uniform float range;
uniform float visibility;

const float shade = 1.0;
const float cloud_height = 1000.0;
const float EarthRadius = 5800000.0;

vec3 moonlight_perception (in vec3 light);

// light_func is a generalized logistic function fit to the light intensity as a function
// of scaled terminator position obtained from Flightgear core

float light_func (in float x, in float a, in float b, in float c, in float d, in float e)
{
x = x-0.5;

// use the asymptotics to shorten computations
if (x > 30.0) {return e;}
if (x < -15.0) {return 0.03;}


return e / pow((1.0 + a * exp(-b * (x-c)) ),(1.0/d));
}

void main(void)
{	

  vec3 shadedFogColor = vec3 (0.55, 0.67, 0.88);
  vec3 moonLightColor = vec3 (0.095, 0.095, 0.15) * moonlight;
  moonLightColor = moonlight_perception (moonLightColor);

  gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
  //gl_TexCoord[0] = gl_MultiTexCoord0 + vec4(textureIndexX, textureIndexY, 0.0, 0.0);
  vec4 ep = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);
  vec4 l  = gl_ModelViewMatrixInverse * vec4(0.0,0.0,1.0,1.0);
  vec3 u = normalize(ep.xyz - l.xyz);

  gl_Position = vec4(0.0, 0.0, 0.0, 1.0);
  gl_Position.x = gl_Vertex.x;
  gl_Position.y += gl_Vertex.y;
  gl_Position.z += gl_Vertex.z;
  gl_Position.xyz += gl_Color.xyz;


  // Determine a lighting normal based on the vertex position from the
  // center of the cloud, so that sprite on the opposite side of the cloud to the sun are darker.
  float n = dot(normalize(-gl_LightSource[0].position.xyz),
                normalize(mat3x3(gl_ModelViewMatrix) * (- gl_Position.xyz)));;

  // Determine the position - used for fog and shading calculations
  vec3 ecPosition = vec3(gl_ModelViewMatrix * gl_Position);
  float fogCoord = abs(ecPosition.z);
  float fract = smoothstep(0.0, cloud_height, gl_Position.z + cloud_height);

  vec3 relVector = gl_Position.xyz - ep.xyz;
  gl_Position = gl_ModelViewProjectionMatrix * gl_Position;
  // logarithmic depth
  flogz = 1.0 + gl_Position.w;

 // Light at the final position

 // first obtain normal to sun position

  vec3 lightFull = (gl_ModelViewMatrixInverse * gl_LightSource[0].position).xyz;
  vec3 lightHorizon = normalize(vec3(lightFull.x,lightFull.y, 0.0));

 // yprime is the distance of the vertex into sun direction, corrected for altitude
  //float vertex_alt = max(altitude * 0.30480 + relVector.z,100.0); 
  float vertex_alt = altitude + relVector.z; 
  float yprime = -dot(relVector, lightHorizon);
  float yprime_alt = yprime -sqrt(2.0 * EarthRadius * vertex_alt);

  // compute the light at the position
  vec4 light_diffuse;
  
  float lightArg = (terminator-yprime_alt)/100000.0;

  light_diffuse.b = light_func(lightArg -1.2 * air_pollution, 1.330e-05, 0.264, 2.227, 1.08e-05, 1.0);
  light_diffuse.g = light_func(lightArg -0.6 * air_pollution, 3.931e-06, 0.264, 3.827, 7.93e-06, 1.0);
  light_diffuse.r = light_func(lightArg, 8.305e-06, 0.161, 3.827, 3.04e-05, 1.0);
  light_diffuse.a = 1.0;

  
  // two times terminator width governs how quickly light fades into shadow
  float terminator_width = 200000.0;
  float earthShade = 0.9 * smoothstep(terminator_width+ terminator, -terminator_width + terminator, yprime_alt) + 0.1;
  
  float intensity = (1.0 - (0.8 * (1.0 - earthShade))) *  length(light_diffuse.rgb);
  
  light_diffuse.rgb = intensity * normalize(mix(light_diffuse.rgb, shadedFogColor, (1.0 - smoothstep(0.5,0.9, cloud_self_shading  ))));  
  if (earthShade < 0.6)
	{
	intensity = length(light_diffuse.rgb); 
	light_diffuse.rgb = intensity * normalize(mix(light_diffuse.rgb,  shadedFogColor, 1.0 -smoothstep(0.1, 0.6,earthShade ) ));
	}
  


  gl_FrontColor = light_diffuse;


  // As we get within 100m of the sprite, it is faded out. Equally at large distances it also fades out.
  gl_FrontColor.a = min(smoothstep(100.0, 250.0, fogCoord), 1.0 - smoothstep(0.9 * range, range, fogCoord));
  
  
  
  gl_FrontColor.a = gl_FrontColor.a * (1.0 - smoothstep(visibility, 3.0* visibility, fogCoord));

  // Fog doesn't affect rain as much as other objects.

float fadeScale = 0.05 + 0.2 * log(fogCoord/1000.0);
  if (fadeScale < 0.05) fadeScale = 0.05;
  fogFactor = exp( -gl_Fog.density * 0.5* fogCoord * fadeScale);

  hazeColor = light_diffuse.rgb;
  hazeColor.r = hazeColor.r * 0.83;
  hazeColor.g = hazeColor.g * 0.9; 

  


  gl_FrontColor.rgb = gl_FrontColor.rgb +  moonLightColor * (1.0 - smoothstep(0.4, 0.5, earthShade));
  hazeColor.rgb = hazeColor.rgb + moonLightColor * (1.0 - smoothstep(0.4, 0.5, earthShade));
  gl_BackColor = gl_FrontColor;

}
