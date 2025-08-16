const std = @import("std");

pub const vec = @import("vector.zig");
pub const mat = @import("matrix.zig");
pub const Quaternion = @import("quaternion.zig").Quaternion;

pub fn Vec2(T: type) type {
    return @Vector(2, T);
}
pub fn Vec3(T: type) type {
    return @Vector(3, T);
}
pub fn Vec4(T: type) type {
    return @Vector(4, T);
}

pub const Mat4x4 = mat.@"4x4";
