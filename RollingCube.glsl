#define MAX_STEPS 10000
#define MAX_DIST 100.
#define SURF_DIST .001

#define PI 3.1415926535897932384626433832795
#define ROLLSPEED iTime

#define CUBE_COLOUR vec3(.5, .933, .969)
#define PLANE_COLOUR vec3(.8, .843, .922)

mat2 Rot(float a) {
  float s = sin(a);
  float c = cos(a);
  return mat2(c, -s, s, c);
}

float smin(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0., 1.);
  return mix(b, a, h) - k * h * (1.0 - h);
}

vec3 rotation(vec3 point, vec3 axis, float angle){
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    mat4 rot= mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,0.0,0.0,1.0);
    return (rot*vec4(point,1.)).xyz;
}

float sdBox(vec3 p, vec3 s) {
  p = abs(p) - s;
  return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
}

vec4 GetCubeDist(vec3 p)
{
  float sqrt2 = 1.41421356237;
  float yMov = max(sin(2.*ROLLSPEED), sin(2.*ROLLSPEED + PI))/(sqrt2+1.) + 1.;
  vec3 rotatedCubePos = rotation(p-vec3(0,yMov,0), vec3(0,0,1), ROLLSPEED);
  rotatedCubePos-=vec3(0,-1,0);

  return vec4(CUBE_COLOUR, sdBox(rotatedCubePos - vec3(0, 1, 0), vec3(1)));
}
vec4 GetDist(vec3 p) {
  //Floor
  vec4 plane = vec4(PLANE_COLOUR, p.y);

  //Cube
  vec4 box = GetCubeDist(p);

  return plane.w < box.w ? plane : box;
}

vec4 RayMarch(vec3 ro, vec3 rd) {
  float dO = 0.;
  vec3 col = vec3(0);

  for (int i = 0; i < MAX_STEPS; i++) {
    vec3 p = ro + rd * dO;
    float dS = GetDist(p).w;
    dO += dS;
    if (dO > MAX_DIST || dS < SURF_DIST) {
      col = GetDist(p).xyz;
      break;
    }
  }

  return vec4(col, dO);
}

vec3 GetNormal(vec3 p) {
  float d = GetDist(p).w;
  vec2 e = vec2(.001, 0);

  vec3 n = d - vec3(GetCubeDist(p - e.xyy).w, GetCubeDist(p - e.yxy).w, GetCubeDist(p - e.yyx).w);

  return normalize(n);
}

float Shadow(vec3 p) {
  vec3 lightPos = vec3(0, 5, -25);
  vec3 l = normalize(lightPos - p);
  
  //Get Normal
  float d = GetDist(p).w;
  vec2 e = vec2(.001, 0);

  vec3 n = d - vec3(GetDist(p - e.xyy).w, GetDist(p - e.yxy).w, GetDist(p - e.yyx).w);
  n = normalize(n);

  float dif = 1.;

  // Shadow
  float d2 = RayMarch(p + n * SURF_DIST * 2., l).w;
  if(p.y<.01 && d2<length(lightPos-p)) dif *= .5;

  return dif;
}

float DiffuseLight(vec3 p){  
  vec3 lightPos = vec3(0, 5, -25);
  vec3 l = normalize(lightPos - p);

  //Get Normal
  float d = GetDist(p).w;
  vec2 e = vec2(.001, 0);

  vec3 n = d - vec3(GetCubeDist(p - e.xyy).w, GetCubeDist(p - e.yxy).w, GetCubeDist(p - e.yyx).w);
  n = normalize(n);

  float dif = clamp(dot(n, l) * .5 + .5, 0., 1.);

  return dif;
}


vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
  vec3 f = normalize(l - p), r = normalize(cross(vec3(0, 1, 0), f)),
       u = cross(f, r), c = p + f * z, i = c + uv.x * r + uv.y * u,
       d = normalize(i - p);
  return d;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
  vec2 m = iMouse.xy / iResolution.xy;

  vec3 col = vec3(0);

  vec3 ro = vec3(0, 4, -5);
  ro.yz *= Rot(-m.y * 3.14 + 1.);
  ro.xz *= Rot(-m.x * 6.2831);

  vec3 rd = R(uv, ro, vec3(0, 1, 0), 1.);

  vec4 d = RayMarch(ro, rd);

  if (d.w < MAX_DIST) {
    col = d.xyz;

    vec3 p = ro + rd * d.w;
    float dif = DiffuseLight(p);
    col.xyz *= dif;
    col.yz *= Shadow(p);
  }

  fragColor = vec4(col, 0.0);
}