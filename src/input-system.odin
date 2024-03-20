package main

import "core:fmt"
import "core:log"
import "core:math"
import glm "core:math/linalg/glsl"
import "core:time"

import gl "vendor:OpenGL"
import sdl "vendor:sdl2"

import "vendor:imgui/imgui_impl_sdl2"

processControls :: proc() -> (quit: bool) {
	for sdl.PollEvent(&ctx.event) {
		imgui_impl_sdl2.ProcessEvent(&ctx.event)

		#partial switch ctx.event.type {
		case .KEYDOWN:
			#partial switch ctx.event.key.keysym.sym {
			case .ESCAPE:
				return true
			case .V:
				// Set cursor to center and disable camera if true 
				ctx.relativeMode = !ctx.relativeMode
				sdl.SetRelativeMouseMode(ctx.relativeMode)
				if ctx.relativeMode == false {
					sdl.WarpMouseInWindow(
						ctx.window,
						WINDOW_WIDTH / 2,
						WINDOW_HEIGHT / 2,
					)
				}
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
	if ctx.relativeMode == false do return

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

	if b8(ctx.keyboard[sdl.SCANCODE_LSHIFT]) {
		camera.speed *= 2
		camera.speedShift = true
	}

	lookingSpeed := camera.speed * f32(deltaTime)

	if b8(ctx.keyboard[sdl.SCANCODE_W]) do camera.pos += fixedFront * lookingSpeed
	if b8(ctx.keyboard[sdl.SCANCODE_S]) do camera.pos -= fixedFront * lookingSpeed
	if b8(ctx.keyboard[sdl.SCANCODE_A]) do camera.pos -= fixedRight * lookingSpeed
	if b8(ctx.keyboard[sdl.SCANCODE_D]) do camera.pos += fixedRight * lookingSpeed
	if b8(ctx.keyboard[sdl.SCANCODE_E]) do camera.pos -= camera.up * lookingSpeed
	if b8(ctx.keyboard[sdl.SCANCODE_SPACE]) {
		camera.pos += camera.up * lookingSpeed
	}

	if camera.speedShift == true {
		camera.speed /= 2
		camera.speedShift = false
	}
}
