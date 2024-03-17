package main

import "core:fmt"
import "core:math"
import glm "core:math/linalg/glsl"
import rand "core:math/rand"
import gl "vendor:OpenGL"

// So we can switch easily between f32 and f64
real :: f32


v3 :: distinct [3]real

Particle :: struct {
	pos:         v3,
	vel:         v3,
	acc:         v3,
	damping:     real, // Constant drag
	inverseMass: real, // Support infinite mass, integration is easier
	startTime:   real,
	type:        ShotType,
}

particles: [dynamic]Particle

// Newton-Euler integration method, linear approximation to the correct integral
particleIntegrate :: proc(particle: ^Particle) {
	duration := real(ctx.currentSecond) / 100000

	if particle.inverseMass <= 0 do return
	assert(duration > 0)

	particle.pos += particle.vel * duration
	particle.vel += particle.acc * duration
	particle.vel *= math.pow(particle.damping, duration)

	clearAccumulator(particle)

	clearAccumulator :: proc(particle: ^Particle) {

	}
}

particleKineticEnergy :: proc(particle: Particle) -> (energy: real) {
	mass := 1 / particle.inverseMass
	return mass * math.pow(math.abs(magnitude(particle.vel)), 2) / 2
}

updateParticles :: proc() {
	for i in 0 ..< len(particles) {
		currentParticle: ^Particle = &particles[i]
		if currentParticle.type == .unused do unordered_remove(&particles, i)

		particleIntegrate(currentParticle)

		if currentParticle.pos.y < 0 ||
		   currentParticle.startTime + 50 > real(ctx.currentSecond) ||
		   currentParticle.pos.z > 200 {
			particles[i].type = .unused
			updateParticles()
		}
	}
}

cube: Shape


drawParticles :: proc() {
	uniforms := gl.get_uniforms_from_program(ctx.shaderID)

	for i in 0 ..< len(particles) {
		model := glm.mat4(1)
		model = glm.mat4Translate(particles[i].pos.xyz) * model
		gl.UniformMatrix4fv(uniforms["model"].location, 1, false, &model[0, 0])

		switch particles[i].type {
		case .pistol:
			gl.Uniform3f(uniforms["color"].location, 1, 1, 1)
		case .artillery:
			gl.Uniform3f(uniforms["color"].location, 0, 1, 1)
		case .fireball:
			gl.Uniform3f(uniforms["color"].location, 1, 0, 1)
		case .unused:
			gl.Uniform3f(uniforms["color"].location, 1, 1, 1)

		}

		drawShape(cube)
	}
}

initTestParticle :: proc() {
	append(&particles, getProjectile(rand.choice_enum(ShotType)))
}
