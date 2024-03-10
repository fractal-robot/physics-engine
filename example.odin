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

main :: proc() {
	init()


	program, program_ok := gl.load_shaders_source(
		vertex_source,
		fragment_source,
	)
	if !program_ok {
		fmt.eprintln("Failed to create GLSL program")
		return
	}
	defer gl.DeleteProgram(program)

	gl.UseProgram(program)

	uniforms := gl.get_uniforms_from_program(program)
	defer delete(uniforms)

	vao: u32
	gl.GenVertexArrays(1, &vao);defer gl.DeleteVertexArrays(1, &vao)
	gl.BindVertexArray(vao)

	// initialization of OpenGL buffers
	vbo, ebo: u32
	gl.GenBuffers(1, &vbo);defer gl.DeleteBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo);defer gl.DeleteBuffers(1, &ebo)

	// struct declaration
	Vertex :: struct {
		pos: glm.vec3,
		col: glm.vec4,
	}

	vertices := []Vertex {
		{{-0.5, +0.5, 0}, {1.0, 0.0, 0.0, 0.75}},
		{{-0.5, -0.5, 0}, {1.0, 1.0, 0.0, 0.75}},
		{{+0.5, -0.5, 0}, {0.0, 1.0, 0.0, 0.75}},
		{{+0.5, +0.5, 0}, {0.0, 0.0, 1.0, 0.75}},
	}

	indices := []u16{0, 1, 2, 2, 3, 0}

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

	// high precision timer
	start_tick := time.tick_now()

	loop: for {
		duration := time.tick_since(start_tick)
		t := f32(time.duration_seconds(duration))

		// event polling
		event: sdl.Event
		for sdl.PollEvent(&event) {
			// #partial switch tells the compiler not to error if every case is not present
			#partial switch event.type {
			case .KEYDOWN:
				#partial switch event.key.keysym.sym {
				case .ESCAPE:
					// labelled control flow
					break loop
				}
			case .QUIT:
				// labelled control flow
				break loop
			}
		}

		// Native support for GLSL-like functionality
		pos := glm.vec3{glm.cos(t * 2), glm.sin(t * 2), 0}

		// array programming support
		pos *= 0.3

		// matrix support
		// model matrix which a default scale of 0.5
		model := glm.mat4{0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 1}

		// matrix indexing and array short with `.x`
		model[0, 3] = -pos.x
		model[1, 3] = -pos.y
		model[2, 3] = -pos.z

		// native swizzling support for arrays
		model[3].yzx = pos.yzx

		model = model * glm.mat4Rotate({0, 1, 1}, t)

		view := glm.mat4LookAt({0, -1, +1}, {0, 0, 0}, {0, 0, 1})
		proj := glm.mat4Perspective(45, 1.3, 0.1, 100.0)

		// matrix multiplication
		u_transform := proj * view * model

		// matrix types in Odin are stored in column-major format but written as you'd normal write them
		gl.UniformMatrix4fv(
			uniforms["u_transform"].location,
			1,
			false,
			&u_transform[0, 0],
		)

		gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
		gl.ClearColor(0.5, 0.7, 1.0, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_SHORT, nil)

		sdl.GL_SwapWindow(ctx.window)
	}
}
