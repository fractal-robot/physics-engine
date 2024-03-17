package main

import "core:fmt"
import "core:math"
import gl "vendor:OpenGL"

Shape :: struct {
	vao, vbo, ebo: u32,
	indicesCount:  int,
}

createCube :: proc() -> Shape {
	cube: Shape

	indices := []u16 {
		0,
		1,
		2,
		2,
		3,
		0,
		4,
		5,
		6,
		6,
		7,
		4,
		8,
		9,
		10,
		10,
		11,
		8,
		12,
		13,
		14,
		14,
		15,
		12,
		16,
		17,
		18,
		18,
		19,
		16,
		20,
		21,
		22,
		22,
		23,
		20,
	}

	vertices := []f32 {
		-0.5,
		-0.5,
		0.5,
		0.5,
		-0.5,
		0.5,
		0.5,
		0.5,
		0.5,
		-0.5,
		0.5,
		0.5,
		0.5,
		-0.5,
		-0.5,
		-0.5,
		-0.5,
		-0.5,
		-0.5,
		0.5,
		-0.5,
		0.5,
		0.5,
		-0.5,
		-0.5,
		-0.5,
		-0.5,
		-0.5,
		-0.5,
		0.5,
		-0.5,
		0.5,
		0.5,
		-0.5,
		0.5,
		-0.5,
		0.5,
		-0.5,
		0.5,
		0.5,
		-0.5,
		-0.5,
		0.5,
		0.5,
		-0.5,
		0.5,
		0.5,
		0.5,
		-0.5,
		0.5,
		0.5,
		0.5,
		0.5,
		0.5,
		0.5,
		0.5,
		-0.5,
		-0.5,
		0.5,
		-0.5,
		-0.5,
		-0.5,
		-0.5,
		0.5,
		-0.5,
		-0.5,
		0.5,
		-0.5,
		0.5,
		-0.5,
		-0.5,
		0.5,
	}

	cube.indicesCount = len(indices)

	gl.GenVertexArrays(1, &cube.vao)
	gl.BindVertexArray(cube.vao)

	gl.GenBuffers(1, &cube.vbo)
	gl.GenBuffers(1, &cube.ebo)

	gl.BindBuffer(gl.ARRAY_BUFFER, cube.vbo)
	gl.BufferData(
		gl.ARRAY_BUFFER,
		len(vertices) * size_of(vertices[0]),
		raw_data(vertices),
		gl.STATIC_DRAW,
	)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, 3 * size_of(f32), 0)


	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, cube.ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(indices[0]),
		raw_data(indices),
		gl.STATIC_DRAW,
	)

	gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)

	return cube
}

drawShape :: proc(shape: Shape) {
	gl.BindVertexArray(shape.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, shape.vbo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, shape.ebo)

	gl.DrawElements(
		gl.TRIANGLES,
		i32(shape.indicesCount),
		gl.UNSIGNED_SHORT,
		nil,
	)

	gl.BindVertexArray(0)
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
}
