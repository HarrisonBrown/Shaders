// Raymarch settings
#define MAX_STEPS 1000
#define MAX_DIST 100.
#define SURF_DIST .001

// Colours
#define SKY_COLOUR vec3(.678, .259, .196)
#define FLOOR_COLOUR vec3(.129, .125, .157)

float sdBox(vec3 p, vec3 s) {
  p = abs(p) - s;
  return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
}

vec4 GetDist(vec3 p) {
  vec4 box = vec4(FLOOR_COLOUR, sdBox(p - vec3(0, 1, 0), vec3(1,1,2)));

  return box;
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

  vec3 n = d - vec3(GetDist(p - e.xyy).w, GetDist(p - e.yxy).w, GetDist(p - e.yyx).w);

  return normalize(n);
}

float GetLight(vec3 p) {
  vec3 lightPos = vec3(3, 5, 4);
  vec3 l = normalize(lightPos - p);
  vec3 n = GetNormal(p);

  float dif = clamp(dot(n, l) * .5 + .5, 0., 1.);

  // Shadow
  float d = RayMarch(p + n * SURF_DIST * 2., l).w;
  if(p.y<.01 && d<length(lightPos-p)) dif *= .5;

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

  vec3 col = SKY_COLOUR;

  vec3 ro = vec3(0, 3, -2);

  vec3 rd = R(uv, ro, vec3(0, 2, 2), 1.);

  vec4 d = RayMarch(ro, rd);

  if (d.w < MAX_DIST) {
    vec3 p = ro + rd * d.w;

    float dif = GetLight(p);
    col = d.xyz * dif;
  }

  // Sun
  col += .05/length(uv - vec2(0,.25));


  // Construction grid
  vec2 gv = fract(uv*6.);

  //col.rg = gv; 
  fragColor = vec4(col, 0.0);
}