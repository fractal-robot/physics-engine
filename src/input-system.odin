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
}

processMovements :: proc() {
	sdl.PumpEvents()

	/*
	if b8(ctx.keyboard[sdl.SCANCODE_Q]) {
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	} else do gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
*/

	fixedFront := glm.normalize(glm.vec3{camera.front.x, 0, camera.front.z})
	fixedRight := glm.normalize(glm.cross(fixedFront, camera.up))
	lookingSpeed := camera.speed * f32(deltaTime)

	// Camera movements
	if b8(ctx.keyboard[sdl.SCANCODE_W]) do camera.pos += fixedFront * lookingSpeed
	if b8(ctx.keyboard[sdl.SCANCODE_S]) do camera.pos -= fixedFront * lookingSpeed
	if b8(ctx.keyboard[sdl.SCANCODE_A]) do camera.pos -= fixedRight * lookingSpeed
	if b8(ctx.keyboard[sdl.SCANCODE_D]) do camera.pos += fixedRight * lookingSpeed
	if b8(ctx.keyboard[sdl.SCANCODE_E]) do camera.pos -= camera.up * lookingSpeed
	if b8(ctx.keyboard[sdl.SCANCODE_SPACE]) {
		camera.pos += camera.up * lookingSpeed
	}

}
