package main

import "core:math"

// So we can switch easily between f32 and f64
real :: f32


v3 :: distinct [3]real

Particle :: struct {
	pos:         v3,
	vel:         v3,
	acc:         v3,
	damping:     real, // Constant drag
	inverseMass: real, // Support infinite mass, integration is easier
}

particles: [dynamic]Particle

// Newton-Euler integration method, linear approximation to the correct integral
particuleIntegrate :: proc(duration: real, particle: ^Particle) {
	if particle.inverseMass <= 0 do return
	assert(duration > 0)

	particle.pos += particle.vel * duration
	resultingAcc := particle.acc
	particle.vel += resultingAcc * duration
	particle.vel *= math.pow(particle.damping, duration)
	clearAccumulator(particle)

	clearAccumulator :: proc(particle: ^Particle) {

	}
}

particleKineticEnergy :: proc(particle: Particle) -> (energy: real) {
	mass := 1 / particle.inverseMass
	return mass * math.pow(math.abs(magnitude(particle.vel)), 2) / 2
}
