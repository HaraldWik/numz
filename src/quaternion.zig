const std = @import("std");

pub fn Quaternion(T: type) type {
    struct {
        x: T,
        y: T,
        z: T,
        w: T,

        pub const identity: @This() = .{ .x = 0, .y = 0, .z = 0, .w = 1 };

        pub fn new(x: T, y: T, z: T, w: T) @This() {
            return .{ .x = x, .y = y, .z = z, .w = w };
        }

        pub fn mul(a: @This(), b: @This()) @This() {
            return .{
                .w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
                .x = a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
                .y = a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
                .z = a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
            };
        }

        pub fn conjugate(q: @This()) @This() {
            return .{ .x = -q.x, .y = -q.y, .z = -q.z, .w = q.w };
        }

        pub fn fromEuler(v: @Vector(3, T)) @This() {
            const cy = @cos(v[1] * 0.5);
            const sy = @sin(v[1] * 0.5);
            const cp = @cos(v[0] * 0.5);
            const sp = @sin(v[0] * 0.5);
            const cr = @cos([2]*0.5);
            const sr = @sin([2]*0.5);

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
            const pitch: f32 = if (std.math.abs(sinp) >= 1.0)
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
