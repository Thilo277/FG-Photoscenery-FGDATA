#version 120

uniform float fg_Fcoef;

uniform sampler2D baseTexture;
varying float fogFactor;

varying vec3 hazeColor;

varying float flogz;

vec3 filter_combined (in vec3 color) ;

void main(void)
{
      vec4 base = texture2D( baseTexture, gl_TexCoord[0].st);
      if (base.a < 0.02)
        discard;

      vec4 finalColor = base * gl_Color;
	
      finalColor.rgb = mix(hazeColor, finalColor.rgb, fogFactor ); 
      finalColor.rgb = filter_combined(finalColor.rgb);

      gl_FragColor.rgb = finalColor.rgb;
      gl_FragColor.a = mix(0.0, finalColor.a, 1.0 - 0.5 * (1.0 - fogFactor));
      // logarithmic depth
      gl_FragDepth = log2(flogz) * fg_Fcoef * 0.5;
}

