// -*-C++-*-

// Shader that uses OpenGL state values to do per-pixel lighting
//
// The only light used is gl_LightSource[0], which is assumed to be
// directional.
//
// Diffuse colors come from the gl_Color, ambient from the material. This is
// equivalent to osg::Material::DIFFUSE.
#version 120
#define MODE_OFF 0
#define MODE_DIFFUSE 1
#define MODE_AMBIENT_AND_DIFFUSE 2

// The constant term of the lighting equation that doesn't depend on
// the surface normal is passed in gl_{Front,Back}Color. The alpha
// component is set to 1 for front, 0 for back in order to work around
// bugs with gl_FrontFacing in the fragment shader.
varying vec4 diffuse_term;
varying vec3 normal;
varying vec3 ecViewDir;
varying vec3 VTangent;

uniform float fg_Fcoef;

uniform int colorMode;

attribute vec3 tangent;//, binormal;



void main()
{

    vec4 ep = gl_ModelViewMatrixInverse * vec4(0.0,0.0,0.0,1.0);
    ecViewDir = (gl_ModelViewMatrix * (ep - gl_Vertex)).xyz;
	
    gl_Position = ftransform();
    // logarithmic depth
    gl_Position.z = (log2(max(1e-6, 1.0 + gl_Position.w)) * fg_Fcoef - 1.0) * gl_Position.w;
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
    normal = gl_NormalMatrix * gl_Normal;
    VTangent  = gl_NormalMatrix * tangent;
	vec4 ambient_color, diffuse_color;
    if (colorMode == MODE_DIFFUSE) {
        diffuse_color = gl_Color;
        ambient_color = gl_FrontMaterial.ambient;
    } else if (colorMode == MODE_AMBIENT_AND_DIFFUSE) {
        diffuse_color = gl_Color;
        ambient_color = gl_Color;
    } else {
        diffuse_color = gl_FrontMaterial.diffuse;
        ambient_color = gl_FrontMaterial.ambient;
    }
    vec4 light_diffuse = vec4 (1.0,1.0,1.0,1.0);
    vec4 light_ambient = vec4 (0.03, 0.03, 0.03, 1.0);
   
    diffuse_term = diffuse_color *  light_diffuse;//gl_LightSource[0].diffuse;
    vec4 constant_term = gl_FrontMaterial.emission + ambient_color *
        (gl_LightModel.ambient +  light_ambient);
    // Super hack: if diffuse material alpha is less than 1, assume a
    // transparency animation is at work
    if (gl_FrontMaterial.diffuse.a < 1.0)
        diffuse_term.a = gl_FrontMaterial.diffuse.a;
    else
        diffuse_term.a = gl_Color.a;
    // Another hack for supporting two-sided lighting without using
    // gl_FrontFacing in the fragment shader.
    gl_FrontColor.rgb = constant_term.rgb;  gl_FrontColor.a = 1.0;
    gl_BackColor.rgb = constant_term.rgb; gl_BackColor.a = 0.0;
    //fogCoord = abs(ecPosition.z / ecPosition.w);
		//fog_Func(fogType);
}
