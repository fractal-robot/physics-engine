#version 450 core

layout(location=0) in vec3 aPos;

uniform mat4 view; 
uniform mat4 projection;

out vec3 nearPoint;
out vec3 farPoint;

out mat4 fragView; 
out mat4 fragProj;

vec3 unprojectPoint(float x, float y, float z) {
		mat4 viewInv = inverse(view);
		mat4 projectionInv = inverse(projection);
		vec4 unprojectedPoint = viewInv * projectionInv * vec4(x, y, z, 1);
		return unprojectedPoint.xyz / unprojectedPoint.w; // Don't need to do that
}

void main() {
		vec3 point = aPos;

	nearPoint = unprojectPoint(point.x, point.y, 0);
	farPoint = unprojectPoint(point.x, point.y, 1);

	fragView = view;
	fragProj = projection;

	gl_Position = vec4(point, 1.);
}
