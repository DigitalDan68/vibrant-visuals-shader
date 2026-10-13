uniform sampler2D colortex0;
uniform sampler2D depthtex0;
varying vec2 texUV;
void main() {
   /* DRAWBUFFERS:89 */
   gl_FragData[0]=texture2D(colortex0,texUV);
   gl_FragData[1]=vec4(texture2D(depthtex0,texUV).x);
}