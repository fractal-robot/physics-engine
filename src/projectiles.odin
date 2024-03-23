package main

import "core:fmt"

ShotType :: enum {
	pistol,
	fireball,
	artillery,
	unused,
}

getProjectile :: proc(type: ShotType) -> (projectile: Particle) {
	#partial switch type {
	case .pistol:
		projectile = Particle {
			inverseMass = f32(1) / 2,
			damping     = 0.99,
			vel         = {0, 0, 400},
			acc         = {0, -1, 0},
		}
	case .fireball:
		projectile = Particle {
			inverseMass = f32(1) / 1,
			damping     = 0.9,
			vel         = {0, 100, 400},
			acc         = {0, 4, 10},
		}
	case .artillery:
		projectile = Particle {
			inverseMass = f32(1) / 200,
			damping     = 0.99,
			vel         = {0, 30, 40},
			acc         = {0, -20, 0},
		}
	}

	projectile.pos = {4, 20, 0}
	projectile.startTime = real(ctx.currentSecond)
	projectile.type = type

	return
}
