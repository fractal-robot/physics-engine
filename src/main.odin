package main

import "core:fmt"
import "core:log"
import "core:math"
import glm "core:math/linalg/glsl"
import "core:time"

import gl "vendor:OpenGL"
import sdl "vendor:sdl2"

import im "vendor:imgui"
import "vendor:imgui/imgui_impl_opengl3"
import "vendor:imgui/imgui_impl_sdl2"


WINDOW_TITLE :: "window"
WINDOW_FLAGS :: sdl.WindowFlags{.SHOWN}

WINDOW_WIDTH :: 1024
WINDOW_HEIGHT :: 1024

GL_VERSION_MAJOR :: 4
GL_VERSION_MINOR :: 4

deltaTime: f64

CTX :: struct {
	window:        ^sdl.Window,
	renderer:      ^sdl.Renderer,
	event:         sdl.Event,
	keyboard:      []u8,
	shouldClose:   bool,
	gl:            sdl.GLContext,
	currentTime:   i64,
	currentSecond: f64,
	shaderID:      u32,
	gridShaderID:  u32,
	relativeMode:  sdl.bool,
	imIO:          ^im.IO,
	frameDuration: f64,
}
ctx: CTX

Camera :: struct {
	pos:        glm.vec3,
	front:      glm.vec3,
	up:         glm.vec3,
	view:       glm.mat4,
	speed:      f32,
	speedShift: bool,
	sensivity:  f32,
	yaw:        f32,
	pitch:      f32,
	firstMouse: b8,
}
camera: Camera

Vertex :: struct {
	pos: glm.vec3,
	col: glm.vec3,
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

	sdl.SetWindowFullscreen(ctx.window, nil)

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

	gl.Enable(gl.DEPTH_TEST)

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	gl.Viewport(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

	gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	{
		camera.pos = {-4, 0, 0}
		camera.front = {1, 0, 0}
		up: glm.vec3 = {0, 1, 0}
		camera.speed = .0220
		camera.up = {0, 1, 0}
		camera.sensivity = .05
	}

	{
		im.CHECKVERSION()
		im.CreateContext()

		ctx.imIO = im.GetIO()
		im.FontAtlas_AddFontFromFileTTF(
			ctx.imIO.Fonts,
			"../font/SauceCodeProNerdFont-Regular.ttf",
			16,
		)
		im.StyleColorsDark()

		imgui_impl_sdl2.InitForOpenGL(ctx.window, ctx.gl)
		imgui_impl_opengl3.Init(nil)
	}

	return true
}

createGrid :: proc() -> (vao: u32) {
	gridPlaneVertices := []f32 {
		1,
		1,
		0,
		-1,
		-1,
		0,
		-1,
		1,
		0,
		-1,
		-1,
		0,
		1,
		1,
		0,
		1,
		-1,
		0,
	}
	vbo: u32
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.BindVertexArray(vao)
	defer gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	defer gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(gridPlaneVertices) * size_of(f32),
		raw_data(gridPlaneVertices),
		gl.STATIC_DRAW,
	)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	return
}

drawGrid :: proc(vao: u32, proj: ^glm.mat4) {
	gl.UseProgram(ctx.gridShaderID)
	defer gl.UseProgram(0)
	uniformsGrid := gl.get_uniforms_from_program(ctx.gridShaderID)


	gl.UniformMatrix4fv(
		uniformsGrid["view"].location,
		1,
		false,
		&camera.view[0, 0],
	)
	gl.UniformMatrix4fv(
		uniformsGrid["projection"].location,
		1,
		false,
		&proj[0, 0],
	)

	gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
	gl.BindVertexArray(vao)
	gl.DrawArrays(gl.TRIANGLES, 0, 6)
	gl.BindVertexArray(0)
	gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
}

drawIm :: proc() {
	imgui_impl_opengl3.NewFrame()
	imgui_impl_sdl2.NewFrame()
	im.NewFrame()

	flags: im.WindowFlags = im.WindowFlags_NoDecoration

	im.SetNextWindowPos({20, 20})
	im.SetNextWindowBgAlpha(1)
	im.SetNextWindowSize({400, 80})


	if im.Begin("controls", nil, flags) {
		im.Text(
			"Application average %.3f ms/frame (%.1f FPS)",
			1000.0 / ctx.imIO.Framerate,
			ctx.imIO.Framerate,
		)
		im.Text("Physics instances: %i", len(particles))
	}

	im.End()
	im.Render()
	imgui_impl_opengl3.RenderDrawData(im.GetDrawData())


}

////////////////////////////////////////////////////////////////////////////////
//// Main 

main :: proc() {
	init()

	cube = createCube()

	vao := createGrid()

	shaderProgramOk: bool
	ctx.shaderID, shaderProgramOk = gl.load_shaders_file(
		"../shader/main.vert",
		"../shader/main.frag",
	)
	if !shaderProgramOk {
		log.errorf("Failed to create GLSL program.")
		return
	}
	gl.UseProgram(ctx.shaderID)


	ctx.gridShaderID, shaderProgramOk = gl.load_shaders_file(
		"../shader/grid.vert",
		"../shader/grid.frag",
	)
	if !shaderProgramOk {
		log.errorf("Failed to create GLSL program.")
		return
	}

	proj := glm.mat4Perspective(
		glm.radians(f32(45.0)),
		WINDOW_WIDTH / WINDOW_HEIGHT,
		0.1,
		1000,
	)

	gl.UseProgram(ctx.shaderID)

	uniforms := gl.get_uniforms_from_program(ctx.shaderID)
	gl.UniformMatrix4fv(uniforms["projection"].location, 1, false, &proj[0, 0])


	currentFrame, lastFrame: i64


	newTime: i64
	timer: time.Stopwatch
	time.stopwatch_start(&timer)

	frameDuration: time.Stopwatch

	refCube := createCube()
	cube = createCube()

	initTestParticle()

	counter := 1

	loop: for {
		time.stopwatch_start(&frameDuration)
		newTime := time.tick_now()._nsec
		deltaTime = f64(newTime - ctx.currentTime) / 100000
		ctx.currentTime = newTime

		ctx.currentSecond = time.duration_seconds(time.stopwatch_duration(timer))

		if processControls() do break loop
		processMovements()

		gl.UseProgram(ctx.shaderID)
		{
			camera.view = glm.mat4LookAt(
				camera.pos,
				camera.pos + camera.front,
				camera.up,
			)
			gl.UniformMatrix4fv(
				uniforms["view"].location,
				1,
				false,
				&camera.view[0, 0],
			)
		}


		gl.ClearColor(0, 0, 0, 1)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		drawGrid(vao, &proj)
		drawParticles()

		drawIm()


		if ctx.relativeMode == true do updateParticles()
		if counter % 15000 == 0 do initTestParticle()


		sdl.GL_SwapWindow(ctx.window)
		counter += 1

		ctx.frameDuration = time.duration_seconds(
			time.stopwatch_duration(frameDuration),
		)
		time.stopwatch_reset(&frameDuration)
	}
}
