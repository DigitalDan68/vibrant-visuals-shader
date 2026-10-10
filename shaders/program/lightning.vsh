#include "/shader.h"
varying vec4 boltColor;
void main() {
   gl_Position = ftransform();
   boltColor = gl_Color;
}
