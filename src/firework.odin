package main

// type of firework, its age, payload (subset of rockets)

FireworkPayload :: struct {
	type:  uint,
	count: uint,
}

Firework :: struct {
	type:         uint,
	age:          real,
	particle:     Particle,
	minAge:       real,
	maxAge:       real,
	maxVel:       v3,
	damping:      real,
	payloadCount: uint,
	payload:      FireworkPayload,
}

createFireworkPayload :: proc(type, count: uint) -> FireworkPayload {
	return FireworkPayload{type, count}
}

initFireworkRules :: proc() {

}
