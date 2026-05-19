shader_type particles;

uniform float spark_speed : hint_range(1.0, 20.0) = 8.0;
uniform float gravity_strength : hint_range(0.0, 20.0) = 9.8;
uniform float drag : hint_range(0.0, 5.0) = 1.2;
uniform float spread_angle : hint_range(0.0, 180.0) = 60.0;
uniform vec4 color_hot : source_color = vec4(1.0, 0.95, 0.4, 1.0);
uniform vec4 color_cool : source_color = vec4(1.0, 0.2, 0.0, 0.0);
uniform float size_start : hint_range(0.01, 0.5) = 0.08;
uniform float size_end : hint_range(0.0, 0.5) = 0.01;
uniform float turbulence : hint_range(0.0, 5.0) = 1.5;

float rand(vec2 seed) {
    return fract(sin(dot(seed, vec2(127.1, 311.7))) * 43758.5453);
}

vec3 random_hemisphere_direction(vec2 seed, float half_angle_deg) {
    float half_angle = radians(half_angle_deg);
    float theta = rand(seed) * TAU;
    float phi = rand(seed + 0.5) * half_angle;
    return vec3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta));
}

void start() {
    vec2 seed = vec2(float(INDEX), TIME);

    vec3 dir = random_hemisphere_direction(seed, spread_angle * 0.5);
    VELOCITY = dir * (spark_speed * (0.5 + rand(seed + 1.3) * 0.5));

    CUSTOM.x = rand(seed + 2.7);
    CUSTOM.y = 0.0;

    TRANSFORM[3].xyz = EMISSION_TRANSFORM[3].xyz;
    COLOR = color_hot;
}

void process() {
    float life = CUSTOM.y / LIFETIME;

    vec3 noise_offset = vec3(
        sin(TIME * 7.3 + float(INDEX) * 1.1),
        cos(TIME * 5.9 + float(INDEX) * 2.3),
        sin(TIME * 6.1 + float(INDEX) * 0.7)
    ) * turbulence;

    VELOCITY += noise_offset * DELTA * (1.0 - life);
    VELOCITY.y -= gravity_strength * DELTA;
    VELOCITY -= VELOCITY * drag * DELTA;

    float size = mix(size_start, size_end, life);
    TRANSFORM[0][0] = size;
    TRANSFORM[1][1] = size;
    TRANSFORM[2][2] = size;

    COLOR = mix(color_hot, color_cool, pow(life, 0.6));

    CUSTOM.y += DELTA;
}
