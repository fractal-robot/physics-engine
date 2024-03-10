package main

import "core:fmt"
import "core:log"
import glm "core:math/linalg/glsl"
import "core:time"
import gl "vendor:OpenGL"
import sdl "vendor:sdl2"

WINDOW_TITLE :: "window"
WINDOW_FLAGS :: sdl.WindowFlags{.SHOWN}

WINDOW_WIDTH :: 1024
WINDOW_HEIGHT :: 1024

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 4

CTX :: struct {
	window:      ^sdl.Window,
	renderer:    ^sdl.Renderer,
	event:       sdl.Event,
	keyboard:    []u8,
	shouldClose: bool,
	gl:          sdl.GLContext,
}

ctx: CTX

Vertex :: struct {
	pos: glm.vec3,
	col: glm.vec4,
}

////////////////////////////////////////////////////////////////////////////////
//// Init 

init :: proc() -> (ok: bool) {
	if sdlRes := sdl.Init(sdl.INIT_VIDEO); sdlRes < 0 {
		log.errorf("[ERROR] sdl.Init returned %v.", sdlRes)
		return false
	}

	ctx.window = sdl.CreateWindow(
		WINDOW_TITLE,
		sdl.WINDOWPOS_CENTERED,
		sdl.WINDOWPOS_CENTERED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		WINDOW_FLAGS,
	)
	if ctx.window == nil {
		log.errorf("[ERROR] sdl.CreateWindow failed.")
		return false
	}

	ctx.renderer = sdl.CreateRenderer(ctx.window, -1, {.ACCELERATED})
	if ctx.renderer == nil {
		log.errorf("[ERROR] sdl.CreateRenderer failed.")
		return false
	}

	ctx.keyboard = sdl.GetKeyboardStateAsSlice()
	if ctx.keyboard == nil {
		log.errorf("[ERROR] sdl.GetKeyboardState failed.")
		return false
	}

	sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK, i32(sdl.GLprofile.CORE))
	sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
	sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

	ctx.gl = sdl.GL_CreateContext(ctx.window)
	gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, sdl.gl_set_proc_address)

	return true
}

////////////////////////////////////////////////////////////////////////////////
//// 

processControls :: proc() -> (quit: bool) {
	for sdl.PollEvent(&ctx.event) {
		#partial switch ctx.event.type {
		case .KEYDOWN:
			#partial switch ctx.event.key.keysym.sym {
			case .ESCAPE:
				return true
			}
		case .QUIT:
			return true
		}
	}
	return
}

processMovements :: proc() {
	sdl.PumpEvents()

	if b8(ctx.keyboard[sdl.SCANCODE_A]) {
		gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
	} else do gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)

}


////////////////////////////////////////////////////////////////////////////////
//// Main 

main :: proc() {
	init()


	vertices := []Vertex {
		{{-0.5, +0.5, 0}, {1.0, 0.0, 0.0, 0.75}},
		{{-0.5, -0.5, 0}, {1.0, 1.0, 0.0, 0.75}},
		{{+0.5, -0.5, 0}, {0.0, 1.0, 0.0, 0.75}},
		{{+0.5, +0.5, 0}, {0.0, 0.0, 1.0, 0.75}},
	}

	indices := []u16{0, 1, 2, 2, 3, 0}

	vao: u32
	gl.GenVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	vbo, ebo: u32
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(vertices[0]),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)

	gl.EnableVertexAttribArray(0)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(
		0,
		3,
		gl.FLOAT,
		false,
		size_of(Vertex),
		offset_of(Vertex, pos),
	)

	gl.VertexAttribPointer(
		1,
		4,
		gl.FLOAT,
		false,
		size_of(Vertex),
		offset_of(Vertex, col),
	)


	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(indices[0]),
		raw_data(indices),
		gl.STATIC_DRAW,
	)

	shaderProgram, shaderProgramOk := gl.load_shaders_file(
		"../shader/vertex.glsl",
		"../shader/fragment.glsl",
	)

	if !shaderProgramOk {
		log.errorf("Failed to create GLSL program.")
		return
	}
	gl.UseProgram(shaderProgram)


	proj: glm.mat4 = glm.mat4Perspective(
		glm.radians(f32(45.0)),
		WINDOW_WIDTH / WINDOW_HEIGHT,
		0.1,
		100,
	)

	model: glm.mat4
	model = model * glm.mat4Rotate({1, 0, 0}, glm.radians(f32(45)))

	view: glm.mat4
	view = view * glm.mat4Translate({0, 0, -3})


	loop: for {
		if processControls() do break loop
		processMovements()

		gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.ClearColor(0.5, 0.7, 1.0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)
		gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)
		sdl.GL_SwapWindow(ctx.window)

	}


}
