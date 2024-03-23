package main

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

particleGravity :: struct {
	gravity: v3,
}

// Creates the generator with the given acceleration 


particleUpdateGravity :: proc(
	particle: ^Particle,
	using particleGravity: particleGravity,
) {
	if (particle.inverseMass == 0) do return

	particleAddForce(particle, gravity * particleGetMass(particle))
}

////////////////////////////////////////////////////////////////////////////////
//// Drag

particleDrag :: struct {
	k1: real,
	k2: real,
}

particleUpdateDrag :: proc(
	particle: ^Particle,
	using particleDrag: particleDrag,
) {
	force: v3 = particle.vel
	dragCoeff := magnitude(force)
	dragCoeff = k1 * dragCoeff + k2 * dragCoeff * dragCoeff
	normalize(&force)
	force *= -dragCoeff

	particleAddForce(particle, force)


}
