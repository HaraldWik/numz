const std = @import("std");

pub const vec = @import("vector.zig");
pub const mat = @import("matrix.zig");
pub const color = @import("color.zig");
pub const quat = @import("quaternion.zig");

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
pub const Quat = quat.Hamiltonian;
pub const Rotor = @import("rotors.zig");

pub fn Transform3D(T: type) type {
    return struct {
        position: Vec3(T) = @splat(0),
        rotation: Quat(T) = Quat(T).identity,
        scale: Vec3(T) = @splat(1),

        pub fn toMat4x4(self: @This()) Mat4x4(T) {
            return Mat4x4(T)
                .translate(self.position)
                .mul(self.rotation.toMat4x4())
                .mul(.scale(self.scale));
        }

        pub fn fromMat4x4(m: Mat4x4(T)) @This() {
            return .{
                .position = m.vecPosition(),
                .rotation = Quat(T).fromMat4x4(m),
                .scale = m.vecScale(),
            };
        }

        pub fn forward(self: @This()) Vec3(T) {
            const f: Vec3(T) = .{ 0, 0, -1 };
            return vec.normalize(self.rotation.rotateVec(f));
        }

        pub fn right(self: *@This()) Vec3(T) {
            const r: Vec3(f32) = .{ 1, 0, 0 };
            return vec.normalize(self.rotation.rotateVec(r));
        }

        pub fn up(self: *@This()) Vec3(T) {
            const u: Vec3(f32) = .{ 0, 1, 0 };
            return vec.normalize(self.rotation.rotateVec(u));
        }
    };
}

pub fn Transform2D(T: type) type {
    return struct {
        position: Vec2(T) = @splat(0),
        rotation: T = 0,
        scale: Vec2(T) = @splat(1),

        pub fn toMat4x4(self: @This()) Mat4x4(T) {
            return Mat4x4(T)
                .translate(.{ self.position[0], self.position[1], 0.0 })
                .mul(.rotate(std.math.degreesToRadians(self.rotation), .{ 1, 0, 1 }))
                .mul(.scale(.{ self.scale[0], self.scale[1], 1 }));
        }

        pub fn fromMat4x4(m: Mat4x4(T)) @This() {
            const position = m.vecPosition();
            const rotation = m.vecRotation();
            const scale = m.vecScale();
            return .{
                .position = .{ position[0], position[1] },
                .rotation = rotation[2],
                .scale = .{ scale[0], scale[1] },
            };
        }
    };
}

test Transform3D {
    const rotation = Quat(f32).angleAxis(std.math.pi / 4.0, .{ 0, 1, 0 });
    var transform: Transform3D(f32) = .{ .position = .{ 10.0, 20.0, 30.0 }, .rotation = rotation, .scale = .{ 1.0, 2.0, 3.0 } };
    const reconstructed = Transform3D(f32).fromMat4x4(transform.toMat4x4());
    try std.testing.expectApproxEqAbs(reconstructed.position[0], transform.position[0], 0.001);
    try std.testing.expectApproxEqAbs(reconstructed.position[1], transform.position[1], 0.001);
    try std.testing.expectApproxEqAbs(reconstructed.position[2], transform.position[2], 0.001);
    try std.testing.expectApproxEqAbs(reconstructed.scale[0], transform.scale[0], 0.001);
    try std.testing.expectApproxEqAbs(reconstructed.scale[1], transform.scale[1], 0.001);
    try std.testing.expectApproxEqAbs(reconstructed.scale[2], transform.scale[2], 0.001);
}

test Transform2D {
    var transform: Transform2D(f32) = .{ .position = .{ 10.0, 20.0 }, .rotation = 270, .scale = .{ 1.0, 2.0 } };
    try std.testing.expect(std.meta.eql(Transform2D(f32).fromMat4x4(transform.toMat4x4()), transform));
}
