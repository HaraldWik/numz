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
    const mat: nz.Mat4x4(f32) = .identity(1.0);
    const a: nz.Vec3(f32) = .{ 1, 2, 3 };
    const b: nz.Vec3(f32) = .{ 3, 2, 1 };

    const result = a + b; // They are SIMD which makes them support operations and some functions like @abs

    const arr = [3]f32{0, 1, 2};

    _ = nz.vec.normalize(arr); // All vector functions also support array vectors

    const c: nz.Vec2(u32) = undefined; // Support for Vec2
    const d: nz.Vec4(u32) = undefined; // Support for Vec4
    const e: @Vector(3, f32) = .{ 1, 2, 3 }; // Optioanly you can use this style
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
- forwardFromEuler

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

- Normal idk // This will change a lot

### Functions

- identity
- new
- mul
- conjugate
- fromEuler
- toEuler

> **Note:** The quaternions are under development, I do not recommend using this math library if you really need quaternion

## Transform

- 3D
- 2D

### Functions

- toMat4x4

## Colors

- Rgb
- Rgba

### Functions

- new
- eql
- alpha
- from
- to
- fromVec
- toVec
- fromHex
- toU32

### Constants

- len
- max
- min
- white
- black
- red
- green
- blue

## Feature requests

Feel free to make feature requests; I always want to know what can be improved.

But I won’t create hyper-specific features, nor will I implement algorithms.

### Planned features

- More and better quaternion types
- Mat3x3
- Mat2x2

## This math lib is tested in

- [WallensteinVR](https://github.com/LuEklund/WallensteinVR)
- [3d-opengl-exemple-zig](https://github.com/HaraldWik/3d-opengl-exemple-zig) // Made by me so doesn't realy count, and it doesnt even compile since breaking changes in 1.15...
