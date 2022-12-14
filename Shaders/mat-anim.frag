// -*-C++-*-
#version 120

// Shader for use with material animations
varying vec4 diffuse, constantColor, matSpecular;
varying vec3 normal;
//varying float fogCoord, alpha;
varying float alpha;

uniform sampler2D texture;

////fog "include" /////
uniform int fogType;

vec3 fog_Func(vec3 color, int type);
//////////////////////

void main()
{
    vec3 n, halfV;
    float NdotL, NdotHV, fogFactor;
    vec4 color = constantColor;
    vec3 lightDir = gl_LightSource[0].position.xyz;
    vec3 halfVector = gl_LightSource[0].halfVector.xyz;
    vec4 texel;
    vec4 fragColor;
    vec4 specular = vec4(0.0);
    n = normalize(normal);
    if (!gl_FrontFacing)
        n = -n;
    NdotL = max(dot(n, lightDir), 0.0);
    if (NdotL > 0.0) {
        color += diffuse * NdotL;
        halfV = normalize(halfVector);
        NdotHV = max(dot(n, halfV), 0.0);
        if (gl_FrontMaterial.shininess > 0.0)
            specular.rgb = (matSpecular.rgb
                            * gl_LightSource[0].specular.rgb
                            * pow(NdotHV, gl_FrontMaterial.shininess));
    }
    color.a = alpha;
    // This shouldn't be necessary, but our lighting becomes very
    // saturated. Clamping the color before modulating by the texture
    // is closer to what the OpenGL fixed function pipeline does.
    color = clamp(color, 0.0, 1.0);
    texel = texture2D(texture, gl_TexCoord[0].st);
    fragColor = color * texel + specular;
    //fogFactor = exp(-gl_Fog.density * gl_Fog.density * fogCoord * fogCoord);
    //gl_FragColor = mix(gl_Fog.color, fragColor, fogFactor);
		fragColor.rgb = fog_Func(fragColor.rgb, fogType);
		gl_FragColor = fragColor;
}
