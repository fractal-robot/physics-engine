package main

import "core:math"

ParticleContact :: struct {
	particles:        [2]^Particle, // Particles involved in the contact
	// [1] to null if one of them is scenery
	restitution:      real,
	contactNormal:    v3,
	penetration:      real,
	particleMovement: [2]v3, // Amount of movement during interpenetration
}

contactResolve :: proc(using contact: ^ParticleContact) {
	contactResolveVelocity(contact)
	contactResolveInterpenetration(contact)
}

////////////////////////////////////////////////////////////////////////////////
//// Resolve velocity

contactCalculateSepVel :: proc(using contact: ^ParticleContact) -> real {
	relativeVel: v3 = particles[0].vel
	if particles[1] != nil do relativeVel -= particles[1].vel
	return dotPdt(relativeVel, contactNormal)
}

contactResolveVelocity :: proc(using contact: ^ParticleContact) {
	separatingVel: real = contactCalculateSepVel(contact)
	if separatingVel > 0 do return

	newSepVel := -separatingVel * restitution
	deltaVel := newSepVel - separatingVel // The change in velocity

	totalInverseMass := particles[0].inverseMass
	if particles[1] != nil do totalInverseMass += particles[1].inverseMass

	if totalInverseMass <= 0 do return // Both particle have infinite mass

	impulsePerIMass: v3 = contactNormal * (deltaVel / totalInverseMass)
	particles[0].vel += impulsePerIMass * particles[0].inverseMass
	if particles[1] != nil {
		particles[1].vel += impulsePerIMass * -particles[1].inverseMass
	}
}

////////////////////////////////////////////////////////////////////////////////
//// Resolve interpenetration

contactResolveInterpenetration :: proc(using contact: ^ParticleContact) {
	if penetration <= 0 do return

	totalInverseMass := particles[0].inverseMass
	if particles[1] != nil do totalInverseMass += particles[1].inverseMass
	if totalInverseMass <= 0 do return

	movePerIMass: v3 = contactNormal * (penetration / totalInverseMass)

	particleMovement[0] = movePerIMass * particles[0].inverseMass
	if particles[1] != nil {
		particleMovement[1] = movePerIMass * -particles[0].inverseMass
	} else {
		particleMovement[1] = 0
	}

	particles[0].pos += particleMovement[0]
	if particles[1] != nil do particles[1].pos += particleMovement[1]
}
