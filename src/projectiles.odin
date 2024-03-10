package main

ShotType :: enum {
	pistol,
	fireball,
	artillery,
}

getProjectile :: proc(type: ShotType) -> (projectile: Particle) {
	switch type {
	case .pistol:
		projectile := Particle {
			inverseMass = 1 / 2,
			damping     = 0.99,
			vel         = {0, 0, 35},
			acc         = {0, -1, 0},
		}
	case .fireball:
		projectile := Particle {
			inverseMass = 1 / 1,
			damping     = 0.9,
			vel         = {0, 0, 100},
			acc         = {0, 0, 0},
		}
	case .artillery:
		projectile := Particle {
			inverseMass = 1 / 200,
			damping     = 0.99,
			vel         = {0, 30, 40},
			acc         = {0, -20, 0},
		}
	}

	return
}
