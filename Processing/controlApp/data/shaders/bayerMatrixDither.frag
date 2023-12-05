#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

// From Processing 2.1 and up, this line is optional
#define PROCESSING_COLOR_SHADER

// if you are using the filter() function, replace the above with
// #define PROCESSING_TEXTURE_SHADER

// ----------------------
//  SHADERTOY UNIFORMS  -
// ----------------------

uniform vec3      iResolution;           // viewport resolution (in pixels)
uniform float     iTime;                 // shader playback time (in seconds) (replaces iGlobalTime which is now obsolete)
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

uniform float gamma = 0.5;
uniform float contrast = 1.3;
uniform int invert = 0;

void mainImage( out vec4 fragColor, in vec2 fragCoord );

void main() {
    mainImage(gl_FragColor,gl_FragCoord.xy);
}

// ------------------------------
//  SHADERTOY CODE BEGINS HERE  -
// ------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float pixelSize = 1.0;
    
    int vignette = 0;
    
    float vsize = 1.5;
    
    float valpha = 0.5;
    float vouter = 0.8;
    float vfalloff = 0.2;
    
    vec2 uv = fragCoord.xy / iResolution.xy; 
    
    float center = vsize - distance(vec2(0.5), uv);
    
    vec2 pseudoPixel = floor( fragCoord.xy / pixelSize );
	vec2 pseudoResolution = floor( iResolution.xy / pixelSize );
	vec2 pseudoUv = pseudoPixel / pseudoResolution;
    
    vec4 color = texture( iChannel0, pseudoUv );
    float alpha = 1.0;
    
    vec2 tuv = fragCoord.xy / 8.0 / pixelSize;
	tuv = fract(tuv);
    
    vec4 tdither = texture( iChannel1, tuv );
	
	vec4 lum = vec4(0.299, 0.587, 0.114, 0);
    
    if(vignette == 1) {
        vec3 vcol = vec3(smoothstep(vouter, vouter + vfalloff, center));
        color.rgb = mix(color.rgb, color.rgb * vcol, valpha);
    }
    
    float dither = dot(tdither, lum);
	float grayscale = dot(color, lum) * gamma;
	grayscale = (grayscale - 0.5) * contrast + 0.5;
    
    vec3 col = vec3(step(dither,grayscale));
    
    if(invert == 0) {
		fragColor = vec4(col, alpha);
	} else {
		fragColor = vec4(1.0 - col, alpha);
	}
}