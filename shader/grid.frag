#version 450 core

in vec3 nearPoint;
in vec3 farPoint;

in mat4 fragView; 
in mat4 fragProj;

out vec4 outColor;

vec4 drawUnitAxes(vec3 fragPos3D, float lineWidth) {
    vec4 color = vec4(0.0); // Initialize color as black

    // Check if the fragment position is exactly on the x-axis or z-axis
    if (abs(fragPos3D.x) < lineWidth) {
        color = vec4(1.0, 0.0, 0.0, 1.0); // Red for x-axis
    }
    else if (abs(fragPos3D.z) < lineWidth) {
        color = vec4(0.0, 0.0, 1.0, 1.0); // Blue for z-axis
    }

    // Apply line width
    vec2 fragPos2D = fragPos3D.xz;
    float derivative = fwidth(dot(fragPos2D, fragPos2D));
    float line = min(abs(fwidth(fragPos2D.x)) + abs(fwidth(fragPos2D.y)), 1.0);

    return color;
}


vec4 grid(vec3 fragPos3D, float scale) {
    vec2 coord = fragPos3D.xz * scale;
    vec2 derivative = fwidth(coord);
    vec2 grid = abs(fract(coord - 0.5) - 0.5) / max(derivative, 0.001);
    float line = min(grid.x, grid.y);
    float minimumz = min(derivative.y, 1);
    float minimumx = min(derivative.x, 1);

    vec4 color = vec4(0.2, 0.2, 0.2, 1.0 - min(line, 1.0));

    return color;
}

float computeDepth(vec3 pos) {
    vec4 clip_space_pos = fragProj * fragView * vec4(pos.xyz, 1.0);
    return (clip_space_pos.z / clip_space_pos.w);
}
float computeLinearDepth(vec3 pos) {
    float near = 0.01;
    float far = 50;

    vec4 clip_space_pos = fragProj * fragView * vec4(pos.xyz, 1.0);
    float clip_space_depth = (clip_space_pos.z / clip_space_pos.w) * 2.0 - 1.0;   
    float linearDepth = (2.0 * near * far) / 
        (far + near - clip_space_depth * (far - near));
    return linearDepth / far; 
}

void main() {
    float t = -nearPoint.y / (farPoint.y - nearPoint.y);
    vec3 fragPos3D = nearPoint + t * (farPoint - nearPoint);

    gl_FragDepth = computeDepth(fragPos3D);

    float linearDepth = computeLinearDepth(fragPos3D);
    float fading = max(0, (0.5 - linearDepth));

    vec4 gridColor = grid(fragPos3D, .1) * float(t > 0);
    gridColor.a *= fading;

    vec4 unitAxisColor = drawUnitAxes(fragPos3D, .5) * float(t > 0); 
    unitAxisColor.a;

    outColor = unitAxisColor + gridColor;
}
