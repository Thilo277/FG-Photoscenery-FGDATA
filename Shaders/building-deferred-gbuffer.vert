// -*- mode: C; -*-
// Licence: GPL v2
// Author: Frederic Bouvier.
//
#version 120
#extension GL_EXT_draw_instanced : enable

attribute vec3 instancePosition; // (x,y,z)
attribute vec3 instanceScaleRotate; // (width, depth, height)
attribute vec3 attrib1;          // Generic packed attributes
attribute vec3 attrib2;

varying vec3 ecNormal;
varying float alpha;

const float c_precision = 128.0;
const float c_precisionp1 = c_precision + 1.0;

vec3 float2vec(float value) {
	vec3 val;
	val.x = mod(value, c_precisionp1) / c_precision;
	val.y = mod(floor(value / c_precisionp1), c_precisionp1) / c_precision;
	val.z = floor(value / (c_precisionp1 * c_precisionp1)) / c_precision;
	return val;
}

void main() {
  // Unpack generic attributes
  vec3 attr1 = float2vec(attrib1.x);
  vec3 attr2 = float2vec(attrib1.z);
  vec3 attr3 = float2vec(attrib2.x);

  // Determine the rotation for the building.
  float sr = sin(6.28 * attr1.x);
  float cr = cos(6.28 * attr1.x);

  vec3 position = gl_Vertex.xyz;
  // Adjust the very top of the roof to match the rooftop scaling.  This shapes
  // the rooftop - gambled, gabled etc.  These vertices are identified by gl_Color.z
  position.x = (1.0 - gl_Color.z) * position.x + gl_Color.z * ((position.x + 0.5) * attr3.z - 0.5);
  position.y = (1.0 - gl_Color.z) * position.y + gl_Color.z * (position.y * attrib2.y );

  // Adjust pitch of roof to the correct height. These vertices are identified by gl_Color.z
  // Scale down by the building height (instanceScaleRotate.z) because
  // immediately afterwards we will scale UP the vertex to the correct scale.
  position.z = position.z + gl_Color.z * attrib1.y / instanceScale.z;
  position = position * instanceScaleRotate.xyz;

  // Rotation of the building and movement into position
  position.xy = vec2(dot(position.xy, vec2(cr, sr)), dot(position.xy, vec2(-sr, cr)));
  position = position + instancePosition.xyz;

  gl_Position = gl_ModelViewProjectionMatrix * vec4(position,1.0);

  // Texture coordinates are stored as:
  // - a separate offset (x0, y0) for the wall (wtex0x, wtex0y), and roof (rtex0x, rtex0y)
  // - a semi-shared (x1, y1) so that the front and side of the building can have
  //   different texture mappings
  //
  // The vertex color value selects between them:
  // gl_Color.x=1 indicates front/back walls
  // gl_Color.y=1 indicates roof
  // gl_Color.z=1 indicates top roof vertexs (used above)
  // gl_Color.a=1 indicates sides
  // Finally, the roof texture is on the right of the texture sheet
  float wtex0x = attr1.y; // Front/Side texture X0
  float wtex0y = attr1.z; // Front/Side texture Y0
  float rtex0x = attr2.z; // Roof texture X0
  float rtex0y = attr3.x; // Roof texture Y0
  float wtex1x = attr2.x; // Front/Roof texture X1
  float stex1x = attr3.y; // Side texture X1
  float wtex1y = attr2.y; // Front/Roof/Side texture Y1
  vec2 tex0 = vec2(sign(gl_MultiTexCoord0.x) * (gl_Color.x*wtex0x + gl_Color.y*rtex0x + gl_Color.a*wtex0x),
                   gl_Color.x*wtex0y + gl_Color.y*rtex0y + gl_Color.a*wtex0y);

   vec2 tex1 = vec2(gl_Color.x*wtex1x + gl_Color.y*wtex1x + gl_Color.a*stex1x,
                    wtex1y);

   gl_TexCoord[0].x = tex0.x + gl_MultiTexCoord0.x * tex1.x;
   gl_TexCoord[0].y = tex0.y + gl_MultiTexCoord0.y * tex1.y;

  // Rotate the normal.
  ecNormal = gl_Normal;
  ecNormal.xy = vec2(dot(ecNormal.xy, vec2(cr, sr)), dot(ecNormal.xy, vec2(-sr, cr)));
  ecNormal = gl_NormalMatrix * ecNormal;

  gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
  gl_FrontColor = vec4(1.0, 1.0, 1.0, 1.0);
  gl_BackColor = vec4(1.0, 1.0, 1.0, 1.0);
  alpha = 1.0;
}
