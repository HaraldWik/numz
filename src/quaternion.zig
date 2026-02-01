const std = @import("std");
const vec = @import("vector.zig");
const Mat4x4 = @import("matrix.zig").@"4x4";

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
        pub fn fromVecReversed(v: @Vector(4, T)) @This() {
            return .{ .w = v[0], .x = v[1], .y = v[2], .z = v[3] };
        }
        pub fn toVecReversed(self: @This()) @Vector(4, T) {
            return .{ self.x, self.y, self.z, self.w };
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
                .z = sr * cp * cy - cr * sp * sy,
                .x = cr * sp * cy + sr * cp * sy,
                .y = cr * cp * sy - sr * sp * cy,
            };
        }

        pub fn toEuler(q: @This()) @Vector(3, T) {
            // Pitch (X axis)
            const sinp = 2.0 * (q.w * q.x - q.z * q.y);
            const pitch: T = if (@abs(sinp) >= 1.0)
                std.math.copysign(@as(T, std.math.pi / 2.0), sinp)
            else
                std.math.asin(sinp);

            // Yaw (Y axis)
            const siny = 2.0 * (q.w * q.y + q.x * q.z);
            const cosy = 1.0 - 2.0 * (q.x * q.x + q.y * q.y);
            const yaw = std.math.atan2(siny, cosy);

            // Roll (Z axis)
            const sinr = 2.0 * (q.w * q.z + q.x * q.y);
            const cosr = 1.0 - 2.0 * (q.z * q.z + q.x * q.x);
            const roll = std.math.atan2(sinr, cosr);

            return .{ pitch, yaw, roll };
        }

        pub fn angleAxis(angle: T, axis_in: @Vector(3, T)) @This() {
            const axis = vec.normalize(axis_in);

            const half = angle * @as(T, 0.5);
            const s = @sin(half);

            return .{
                .w = @cos(half),
                .x = axis[0] * s,
                .y = axis[1] * s,
                .z = axis[2] * s,
            };
        }

        pub fn fromMat4x4(m: Mat4x4(T)) @This() {
            const trace = m.d[0 * 4 + 0] + m.d[1 * 4 + 1] + m.d[2 * 4 + 2];
            var w: T = 0;
            var x: T = 0;
            var y: T = 0;
            var z: T = 0;

            if (trace > @as(T, 0)) {
                const s = @sqrt(trace + @as(T, 1.0)) * @as(T, 2.0); // s = 4 * w
                w = 0.25 * s;
                x = (m.d[2 * 4 + 1] - m.d[1 * 4 + 2]) / s;
                y = (m.d[0 * 4 + 2] - m.d[2 * 4 + 0]) / s;
                z = (m.d[1 * 4 + 0] - m.d[0 * 4 + 1]) / s;
            } else if ((m.d[0 * 4 + 0] > m.d[1 * 4 + 1]) and (m.d[0 * 4 + 0] > m.d[2 * 4 + 2])) {
                const s = @sqrt(@as(T, 1.0) + m.d[0 * 4 + 0] - m.d[1 * 4 + 1] - m.d[2 * 4 + 2]) * @as(T, 2.0); // s = 4 * x
                w = (m.d[2 * 4 + 1] - m.d[1 * 4 + 2]) / s;
                x = 0.25 * s;
                y = (m.d[0 * 4 + 1] + m.d[1 * 4 + 0]) / s;
                z = (m.d[0 * 4 + 2] + m.d[2 * 4 + 0]) / s;
            } else if (m.d[1 * 4 + 1] > m.d[2 * 4 + 2]) {
                const s = @sqrt(@as(T, 1.0) + m.d[1 * 4 + 1] - m.d[0 * 4 + 0] - m.d[2 * 4 + 2]) * @as(T, 2.0); // s = 4 * y
                w = (m.d[0 * 4 + 2] - m.d[2 * 4 + 0]) / s;
                x = (m.d[0 * 4 + 1] + m.d[1 * 4 + 0]) / s;
                y = 0.25 * s;
                z = (m.d[1 * 4 + 2] + m.d[2 * 4 + 1]) / s;
            } else {
                const s = @sqrt(@as(T, 1.0) + m.d[2 * 4 + 2] - m.d[0 * 4 + 0] - m.d[1 * 4 + 1]) * @as(T, 2.0); // s = 4 * z
                w = (m.d[1 * 4 + 0] - m.d[0 * 4 + 1]) / s;
                x = (m.d[0 * 4 + 2] + m.d[2 * 4 + 0]) / s;
                y = (m.d[1 * 4 + 2] + m.d[2 * 4 + 1]) / s;
                z = 0.25 * s;
            }

            return .{ .w = w, .x = x, .y = y, .z = z };
        }

        pub fn toMat4x4(self: @This()) Mat4x4(T) {
            const xx = self.x * self.x;
            const yy = self.y * self.y;
            const zz = self.z * self.z;
            const xy = self.x * self.y;
            const xz = self.x * self.z;
            const yz = self.y * self.z;
            const wx = self.w * self.x;
            const wy = self.w * self.y;
            const wz = self.w * self.z;

            return .new(.{
                1 - 2 * (yy + zz), 2 * (xy - wz),     2 * (xz + wy),     0,
                2 * (xy + wz),     1 - 2 * (xx + zz), 2 * (yz - wx),     0,
                2 * (xz - wy),     2 * (yz + wx),     1 - 2 * (xx + yy), 0,
                0,                 0,                 0,                 1,
            });
        }
    };
}

test Hamiltonian {
    // const euler: @Vector(3, f32) = .{ 0, 270, 360 };
    // const quat: Hamiltonian(f32) = .fromEuler(euler);
    // const quat_euler = quat.toEuler();
    // std.debug.print("{any} vs {any}\n", .{ euler, quat_euler });
    // try std.testing.expectApproxEqAbs(quat_euler[0], euler[0], 0.5);
    // try std.testing.expectApproxEqAbs(quat_euler[1], euler[1], 0.5);
    // try std.testing.expectApproxEqAbs(quat_euler[2], euler[2], 0.5);

    const mat: Mat4x4(f32) = .identity;
    const quat: Hamiltonian(f32) = .fromMat4x4(mat);
    try std.testing.expect(mat.eql(quat.toMat4x4()));
}
