# numz

**A linear algebra math lib for Zig**

## Installation

```bash
zig fetch --save git+https://github.com/HaraldWik/numz
```

```rust
const numz_mod = b.dependency("numz", .{
    .target = target,
    .optimize = optimize,
}).module("numz");
```

```rust
// How I recommend making the import
const nz = @import("numz");

pub fn main() !void {
    const mat: nz.mat.@"4x4"(f32) = .identity(1.0);
    const vec3: nz.vec.@"3" = .{ 1, 2, 3 };
}
```

## Vectors

- Vec2
- Vec3
- Vec4

### Functions

- eql
- scale
- dot
- cross
- length
- normalize
- negate
- distance
- distanceSquared
- reflect
- mix
- forward

## Matrices

- Mat4x4 <-- Column mayor so it works with OpenGL and Vulkan

### Functions

- new
- identity
- mul
- translate
- scale
- rotate Standard Rodrigues’ rotation
- perspective
- orthographic
- crossProduct3D
- lookAt
- transpose
- inverse
- fromQuaternion

## Quaternions

- Normal idk

### Functions

- new
- identity
- mul
- conjugate
- fromEuler
- toEuler

> **Note:** The quaternions are under development, I do not recommend using this math library if you really need quaternion

## Feature requests

Feel free to make feature requests; I always want to what can be improved.

But I won’t create hyper-specific features, nor will I implement algorithms.

### Planned features

- More and better quaternion types
- Mat3x3
- Mat2x2

## This math lib is tested in

- [WallensteinVR](https://github.com/LuEklund/WallensteinVR)
- [3d-opengl-exemple-zig](https://github.com/HaraldWik/3d-opengl-exemple-zig) // Made by me so doesn't realy count, and it doesnt even compile since breaking changes in 1.15...
