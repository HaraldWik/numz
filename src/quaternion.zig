const std = @import("std");
const vec = @import("vector.zig");

/// Quaternion using Hamiltonian (w-first) convention
pub fn Hamiltonian(T: type) type {
    return struct {
        w: T,
        x: T,
        y: T,
        z: T,

        pub const identity: @This() = .{ .x = 0, .y = 0, .z = 0, .w = 1 };

        pub fn new(w: T, x: T, y: T, z: T) @This() {
            return .{ .w = w, .x = x, .y = y, .z = z };
        }

        pub fn mul(a: @This(), b: @This()) @This() {
            return .{
                .x = a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
                .y = a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
                .z = a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
                .w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
            };
        }

        pub fn conjugate(q: @This()) @This() {
            return .{ .w = q.w, .x = -q.x, .y = -q.y, .z = -q.z };
        }

        pub fn fromVec(v: @Vector(4, T)) @This() {
            return .{ .w = v[0], .x = v[1], .y = v[2], .z = v[3] };
        }

        pub fn toVec(self: @This()) @Vector(4, T) {
            return .{ self.w, self.x, self.y, self.z };
        }

        pub fn fromEuler(euler: @Vector(3, T)) @This() {
            const pitch, const yaw, const roll = euler;

            const cy = @cos(yaw * 0.5);
            const sy = @sin(yaw * 0.5);
            const cp = @cos(pitch * 0.5);
            const sp = @sin(pitch * 0.5);
            const cr = @cos(roll * 0.5);
            const sr = @sin(roll * 0.5);

            return .{
                .w = cr * cp * cy + sr * sp * sy,
                .x = sr * cp * cy - cr * sp * sy,
                .y = cr * sp * cy + sr * cp * sy,
                .z = cr * cp * sy - sr * sp * cy,
            };
        }

        /// Reference: https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
        pub fn toEuler(q: @This()) !@Vector(3, T) {
            const sinr_cosp = 2.0 * (q.w * q.x + q.y * q.z);
            const cosr_cosp = 1.0 - 2.0 * (q.x * q.x + q.y * q.y);
            const roll = std.math.atan2(sinr_cosp, cosr_cosp);

            const sinp = 2.0 * (q.w * q.y - q.z * q.x);
            const pitch: f32 = if (@abs(sinp) >= 1.0)
                std.math.copysign(@floatCast(std.math.pi / 2), sinp)
            else
                std.math.asin(sinp);

            const siny_cosp = 2.0 * (q.w * q.z + q.x * q.y);
            const cosy_cosp = 1.0 - 2.0 * (q.y * q.y + q.z * q.z);
            const yaw = std.math.atan2(siny_cosp, cosy_cosp);

            return .{ pitch, yaw, roll };
        }
    };
}

test Hamiltonian {
    const euler: @Vector(3, f32) = .{ 0, 270, 360 };
    const quat: Hamiltonian(f32) = .fromEuler(euler);
    try std.testing.expect(vec.eql(quat.toEuler(), euler));
}
