
#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform vec3 col;
uniform sampler2D texture; //default texture passed from processing

uniform vec2 texOffset;
varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
  vec4 currcol = texture2D(texture, vertTexCoord.st) * vertColor;
  gl_FragColor = vec4(currcol.x*col.x,currcol.y*col.y,currcol.z*col.z,currcol.w);
}