# numz

**A linear algebra math lib for Zig**

Simd support.
1D arrays for mat4x4

## Installation

```bash
zig fetch --save git+https://github.com/HaraldWik/numz
```

```rust
const numz_dep = b.dependency("numz", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("numz", numz_dep.module("numz"));
```
