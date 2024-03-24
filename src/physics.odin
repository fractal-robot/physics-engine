package main

import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"
import rand "core:math/rand"
import gl "vendor:OpenGL"

// So we can switch easily between f32 and f64
real :: f32


v3 :: [3]real

Particle :: struct {
	pos:         v3,
	vel:         v3,
	acc:         v3,
	damping:     real, // Constant drag
	inverseMass: real, // Support infinite mass, integration is easier
	startTime:   real,
	type:        ShotType,
	forceAccum:  v3,
}

particles: [dynamic]Particle

clearAccumulator :: proc(particle: ^Particle) {
	particle.forceAccum = 0
}

// Newton-Euler integration method, linear approximation to the correct integral
particleIntegrate :: proc(particle: ^Particle) {
	duration := real(ctx.frameDuration)

	if particle.inverseMass <= 0 do return

	particle.pos += particle.vel * duration

	resultingAcc: v3 = particle.forceAccum * particle.inverseMass

	// particle.vel += resultingAcc * duration
	particle.vel += particle.acc * duration

	particle.vel *= math.pow(particle.damping, duration)

	clearAccumulator(particle)
}

particleAddForce :: proc(particle: ^Particle, force: v3) {
	particle.forceAccum += force
}

particleGetMass :: proc(particle: ^Particle) -> real {
	return 1 / particle.inverseMass
}

updateParticles :: proc() {
	if len(particles) == 0 do return

	// Traversal in reverse so we don't have to call updateParticle again when
	// removing element
	#reverse for &currentParticle, index in particles {
		if real(ctx.currentSecond) - real(currentParticle.startTime) > 50 ||
		   currentParticle.pos.y <= 0 {
			unordered_remove(&particles, index)
		}

		particleIntegrate(&currentParticle)
	}
}

cube: Shape

drawParticles :: proc() {
	if len(particles) == 0 do return

	gl.UseProgram(ctx.shaderID)
	uniforms := gl.get_uniforms_from_program(ctx.shaderID)

	for i in 0 ..< len(particles) {
		if particles[i].type == .unused do continue
		model := glm.mat4(1)
		particlePos: glm.vec3 =  {
			f32(particles[i].pos.x),
			f32(particles[i].pos.y),
			f32(particles[i].pos.z),
		}
		model = glm.mat4Translate(particlePos) * model
		gl.UniformMatrix4fv(uniforms["model"].location, 1, false, &model[0, 0])

		switch particles[i].type {
		case .pistol:
			gl.Uniform3f(uniforms["color"].location, 1, 1, 1)
		case .artillery:
			gl.Uniform3f(uniforms["color"].location, 0, 1, 1);case .fireball:
			gl.Uniform3f(uniforms["color"].location, 1, 0, 1)
		case .unused:
			gl.Uniform3f(uniforms["color"].location, 1, 1, 1)

		}

		drawShape(cube)
	}
}

initTestParticle :: proc() {
	type := rand.choice_enum(ShotType)
	if type == ShotType.unused do initTestParticle()
	append(&particles, getProjectile(type))
}
