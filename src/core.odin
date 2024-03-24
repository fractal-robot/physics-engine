package main

import "core:math"

magnitude :: proc(v: v3) -> (magnitude: real) {
	return math.sqrt(v.x * v.x + v.y * v.y + v.z + v.z)
}

// Useful for comparing 
squareMagnitude :: proc(v: v3) -> (magnitude: real) {
	return v.x * v.x + v.y * v.y + v.z + v.z
}

normalize :: proc(v: ^v3) {
	v^ /= magnitude(v^)
}

dotPdt :: proc(v1, v2: v3) -> real {
	return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
}
