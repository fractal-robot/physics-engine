package main

import "core:math"

ParticleForceGenerator :: struct {}

ParticleForceRegistration :: struct {
	particle: ^Particle,
	fg:       ^ParticleForceGenerator,
}

ParticlesRegistry :: struct {
	registry: [dynamic]ParticleForceRegistration,
}

addParticle :: proc(particle: ^Particle, fg: ParticleForceGenerator) {

}

removeParticle :: proc(particle: ^Particle, fg: ParticleForceGenerator) {

}

// Clear the record of the connections of the particles
clear :: proc() {

}

updateForces :: proc(particles: ParticlesRegistry) {
	for &particle in particles.registry {
		updateForce(particle.particle)
	}
}


updateForce :: proc(particle: ^Particle) {
	duration := f32(ctx.frameDuration) // Needed for some generators

}

////////////////////////////////////////////////////////////////////////////////
//// Gravity

ParticleGravity :: struct {
	gravity: v3,
}

// Creates the generator with the given acceleration 


particleUpdateGravity :: proc(
	particle: ^Particle,
	using particleGravity: ParticleGravity,
) {
	if (particle.inverseMass == 0) do return

	particleAddForce(particle, gravity * particleGetMass(particle))
}

////////////////////////////////////////////////////////////////////////////////
//// Drag

ParticleDrag :: struct {
	k1: real,
	k2: real,
}

particleUpdateDrag :: proc(
	particle: ^Particle,
	using particleDrag: ParticleDrag,
) {
	force: v3 = particle.vel
	dragCoeff := magnitude(force)
	dragCoeff = k1 * dragCoeff + k2 * dragCoeff * dragCoeff
	normalize(&force)
	force *= -dragCoeff

	particleAddForce(particle, force)
}

////////////////////////////////////////////////////////////////////////////////
//// Spring

// Hook's law
// We'll need to create and register a generator for each

ParticleSpring :: struct {
	other:          ^Particle, // The particle at the other end
	springConstant: real,
	restLength:     real,
}

particleUpdateSpring :: proc(
	particle: ^Particle,
	using particleSpring: ParticleSpring,
) {
	force: v3 = particle.pos - other.pos
	magnitude: real = math.abs(magnitude(force) - restLength) * springConstant
	normalize(&force)
	force *= -magnitude
	particleAddForce(particle, force)
}

////////////////////////////////////////////////////////////////////////////////
//// Anchored spring

ParticleEnchoredSpring :: struct {
	anchor:         v3, // The location of the anchored end of the spring
	springConstant: real,
	restLength:     real,
}

particleUpdateEnchoredSpring :: proc(
	particle: ^Particle,
	using particleEnchoredSpring: ParticleEnchoredSpring,
) {
	force: v3 = particle.pos - particleEnchoredSpring.anchor
	magnitude: real = math.abs(magnitude(force) - restLength) * springConstant
	normalize(&force)
	force *= -magnitude
	particleAddForce(particle, force)
}

////////////////////////////////////////////////////////////////////////////////
//// Bungee

// Only produce pulling force

ParticleBungee :: struct {
	other:          ^Particle,
	springConstant: real,
	restLength:     real, // At the point it begins to generate a force
}

particleUpdateBungee :: proc(
	particle: ^Particle,
	using particleBungee: ParticleBungee,
) {
	force: v3 = particle.pos - other.pos
	magnitude: real = magnitude(force)
	if magnitude <= restLength do return
	magnitude = math.abs(magnitude - restLength) * springConstant
	normalize(&force)
	force *= -magnitude
	particleAddForce(particle, force)
}
