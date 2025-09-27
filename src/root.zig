const std = @import("std");

pub const vec = @import("vector.zig");
pub const mat = @import("matrix.zig");
pub const color = @import("color.zig");
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

/// Column mayor
pub const Mat4x4 = mat.@"4x4";

pub fn Transform3D(T: type) type {
    return struct {
        position: Vec3(T) = @splat(0),
        rotation: Vec3(T) = @splat(0),
        scale: Vec3(T) = @splat(1),

        pub fn toMat4x4(self: @This()) Mat4x4(T) {
            return Mat4x4(T)
                .translate(self.position)
                .mul(.rotate(std.math.degreesToRadians(self.rotation[0]), .{ 1, 0, 0 }))
                .mul(.rotate(std.math.degreesToRadians(self.rotation[1]), .{ 0, 1, 0 }))
                .mul(.rotate(std.math.degreesToRadians(self.rotation[2]), .{ 0, 0, 1 }))
                .mul(.scale(self.scale));
        }
    };
}

pub fn Transform2D(T: type) type {
    return struct {
        position: Vec2(T) = @splat(0),
        rotation: T = 0.0,
        scale: Vec2(T) = 1.0,

        pub fn toMat4x4(self: @This()) Mat4x4(T) {
            return Mat4x4(T)
                .translate(.{ self.position[0], self.position[1], 0.0 })
                .mul(.rotate(std.math.degreesToRadians(self.rotation), .{ 1, 0, 1 }))
                .mul(.scale(.{ self.scale[0], self.scale[1], 1 }));
        }
    };
}
