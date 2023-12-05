#version 150

#define PROCESSING_TEXTURE_SHADER

uniform mat4 transform;

in vec4 vertex;
in vec4 color;

out vec4 vertColor;

void main() {
  gl_Position = transform * vertex;    
  vertColor = color;
}