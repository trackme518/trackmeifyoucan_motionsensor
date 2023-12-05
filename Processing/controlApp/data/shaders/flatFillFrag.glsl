
#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform vec3 col;
//uniform sampler2D texture; //default texture passed from processing

uniform vec2 texOffset;
varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
  gl_FragColor = vec4(col.x,col.y,col.z,1.0);
}