package main

import "core:fmt"
import "core:log"
import "core:math"
import glm "core:math/linalg/glsl"
import "core:time"
import gl "vendor:OpenGL"
import sdl "vendor:sdl2"

processControls :: proc() -> (quit: bool) {
	for sdl.PollEvent(&ctx.event) {
		#partial switch ctx.event.type {
		case .KEYDOWN:
			#partial switch ctx.event.key.keysym.sym {
			case .ESCAPE:
				return true
			}
		case .MOUSEMOTION:
			handleCamera(ctx.event.motion.xrel, ctx.event.motion.yrel)
		case .QUIT:
			return true
		}
	}
	return
}

handleCamera :: proc(xOffset, yOffset: i32) {
	camera.yaw += f32(xOffset) * camera.sensivity
	camera.pitch -= f32(yOffset) * camera.sensivity

	if camera.pitch > 89 do camera.pitch = 89
	if camera.pitch < -89 do camera.pitch = -89

	direction: glm.vec3

	direction.x =
		math.cos(glm.radians(camera.yaw)) * math.cos(glm.radians(camera.pitch))
	direction.y = math.sin(glm.radians(camera.pitch))
	direction.z =
		math.sin(glm.radians(camera.yaw)) * math.cos(glm.radians(camera.pitch))

	camera.front = glm.normalize(direction)
	fmt.println(camera.front)
}

processMovements :: proc() {
	sdl.PumpEvents()

	if b8(ctx.keyboard[sdl.SCANCODE_Q]) {
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	} else do gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)

	// Camera movements
	if b8(ctx.keyboard[sdl.SCANCODE_W]) {
		camera.pos += camera.front * camera.speed * f32(deltaTime)
	}
	if b8(ctx.keyboard[sdl.SCANCODE_S]) {
		camera.pos -= camera.front * camera.speed * f32(deltaTime)
	}
	if b8(ctx.keyboard[sdl.SCANCODE_A]) {
		camera.pos -=
			glm.normalize(glm.cross(camera.front, camera.up)) *
			camera.speed *
			f32(deltaTime)
	}
	if b8(ctx.keyboard[sdl.SCANCODE_D]) {
		camera.pos +=
			glm.normalize(glm.cross(camera.front, camera.up)) *
			camera.speed *
			f32(deltaTime)
	}
}
