const std = @import("std");
const vec = @import("vector.zig");
const Mat4x4 = @import("matrix.zig").@"4x4";

/// Quaternion using Jolt (x,y,z,w) convention
pub fn Hamiltonian(T: type) type {
    return struct {
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
                .x = a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
                .y = a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
                .z = a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
                .w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
            };
        }
        pub fn normalize(q: @This()) @This() {
            const magnitude = @sqrt(q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z);
            if (magnitude == 0.0) return .{ .w = 1, .x = 0, .y = 0, .z = 0 };

            const inv_mag = 1.0 / magnitude;
            return .{
                .w = q.w * inv_mag,
                .x = q.x * inv_mag,
                .y = q.y * inv_mag,
                .z = q.z * inv_mag,
            };
        }
        pub fn conjugate(q: @This()) @This() {
            return .{ .x = -q.x, .y = -q.y, .z = -q.z, .w = q.w };
        }

        pub fn inverse(q: @This()) @This() {
            const mag_sq = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w;
            const inv = 1.0 / mag_sq;
            return .{ .x = -q.x * inv, .y = -q.y * inv, .z = -q.z * inv, .w = q.w * inv };
        }

        pub fn dot(a: @This(), b: @This()) T {
            return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
        }

        pub fn slerp(a: @This(), b_in: @This(), t: T) @This() {
            var d = dot(a, b_in);
            var b = b_in;
            if (d < 0.0) {
                b = .{ .x = -b.x, .y = -b.y, .z = -b.z, .w = -b.w };
                d = -d;
            }
            if (d > 0.9995) {
                return nlerp(a, b, t);
            }
            const theta = std.math.acos(d);
            const sin_theta = @sin(theta);
            const wa = @sin((1.0 - t) * theta) / sin_theta;
            const wb = @sin(t * theta) / sin_theta;
            return .{
                .x = a.x * wa + b.x * wb,
                .y = a.y * wa + b.y * wb,
                .z = a.z * wa + b.z * wb,
                .w = a.w * wa + b.w * wb,
            };
        }

        pub fn nlerp(a: @This(), b_in: @This(), t: T) @This() {
            var b = b_in;
            if (dot(a, b) < 0.0) {
                b = .{ .x = -b.x, .y = -b.y, .z = -b.z, .w = -b.w };
            }
            const one_minus_t = 1.0 - t;
            return (@This(){
                .x = a.x * one_minus_t + b.x * t,
                .y = a.y * one_minus_t + b.y * t,
                .z = a.z * one_minus_t + b.z * t,
                .w = a.w * one_minus_t + b.w * t,
            }).normalize();
        }

        pub fn rotateVec(self: @This(), v: @Vector(3, T)) @Vector(3, T) {
            const qv = @Vector(3, T){ self.x, self.y, self.z };
            const uv = vec.cross(qv, v);
            const uuv = vec.cross(qv, uv);
            return v + (uv * @as(@Vector(3, T), @splat(self.w)) + uuv) * @as(@Vector(3, T), @splat(2));
        }

        pub fn fromVec(v: @Vector(4, T)) @This() {
            return .{ .x = v[0], .y = v[1], .z = v[2], .w = v[3] };
        }

        pub fn toVec(self: @This()) @Vector(4, T) {
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

        /// Shortest-arc rotation that maps `from_in` onto `to_in`.
        pub fn fromTo(from_in: @Vector(3, T), to_in: @Vector(3, T)) @This() {
            const from = vec.normalize(from_in);
            const to = vec.normalize(to_in);
            const d = vec.dot(from, to);

            if (d >= 0.999999) return identity;
            if (d <= -0.999999) {
                var axis = vec.cross(from, @Vector(3, T){ 1, 0, 0 });
                if (vec.length(axis) < 1.0e-6) {
                    axis = vec.cross(from, @Vector(3, T){ 0, 1, 0 });
                }
                return angleAxis(std.math.pi, axis);
            }

            const axis = vec.cross(from, to);
            const s = @sqrt((d) * 2.0);
            const inv_s = 1.0 / s;
            return .{
                .w = s * 0.5,
                .x = axis[0] * inv_s,
                .y = axis[1] * inv_s,
                .z = axis[2] * inv_s,
            };
        }

        /// Orients local forward `(0, 0, -1)` toward `forward_in`, keeping local up
        /// `(0, 1, 0)` aligned as closely as possible with `up_hint`.
        pub fn lookAt(forward_in: @Vector(3, T), up_hint: @Vector(3, T)) @This() {
            const f = vec.normalize(forward_in);

            const proj = vec.dot(up_hint, f);
            var u_raw = up_hint - f * @as(@Vector(3, T), @splat(proj));
            if (vec.length(u_raw) < 1.0e-6) {
                u_raw = if (@abs(f[0]) < 0.9)
                    vec.cross(f, @Vector(3, T){ 1, 0, 0 })
                else
                    vec.cross(f, @Vector(3, T){ 0, 1, 0 });
            }
            const u = vec.normalize(u_raw);
            const r = vec.cross(u, -f);
            const back = -f;

            const m: Mat4x4(T) = .new(.{
                r[0],    r[1],    r[2],    0,
                u[0],    u[1],    u[2],    0,
                back[0], back[1], back[2], 0,
                0,       0,       0,       1,
            });
            return fromMat4x4(m);
        }

        /// Extracts a quaternion from a column-major 4x4 rotation matrix.
        /// Column-major: R[row, col] = d[row + col * 4]
        pub fn fromMat4x4(m: Mat4x4(T)) @This() {
            // R[0,0] = d[0], R[1,1] = d[5], R[2,2] = d[10]
            const trace = m.d[0] + m.d[5] + m.d[10];
            var w: T = 0;
            var x: T = 0;
            var y: T = 0;
            var z: T = 0;

            if (trace > @as(T, 0)) {
                const s = @sqrt(trace + @as(T, 1.0)) * @as(T, 2.0);
                w = 0.25 * s;
                x = (m.d[6] - m.d[9]) / s; // R[2,1] - R[1,2]
                y = (m.d[8] - m.d[2]) / s; // R[0,2] - R[2,0]
                z = (m.d[1] - m.d[4]) / s; // R[1,0] - R[0,1]
            } else if ((m.d[0] > m.d[5]) and (m.d[0] > m.d[10])) {
                const s = @sqrt(@as(T, 1.0) + m.d[0] - m.d[5] - m.d[10]) * @as(T, 2.0);
                w = (m.d[6] - m.d[9]) / s;
                x = 0.25 * s;
                y = (m.d[4] + m.d[1]) / s; // R[0,1] + R[1,0]
                z = (m.d[8] + m.d[2]) / s; // R[0,2] + R[2,0]
            } else if (m.d[5] > m.d[10]) {
                const s = @sqrt(@as(T, 1.0) + m.d[5] - m.d[0] - m.d[10]) * @as(T, 2.0);
                w = (m.d[8] - m.d[2]) / s;
                x = (m.d[4] + m.d[1]) / s;
                y = 0.25 * s;
                z = (m.d[9] + m.d[6]) / s; // R[1,2] + R[2,1]
            } else {
                const s = @sqrt(@as(T, 1.0) + m.d[10] - m.d[0] - m.d[5]) * @as(T, 2.0);
                w = (m.d[1] - m.d[4]) / s;
                x = (m.d[8] + m.d[2]) / s;
                y = (m.d[9] + m.d[6]) / s;
                z = 0.25 * s;
            }

            return .{ .x = x, .y = y, .z = z, .w = w };
        }

        /// Converts quaternion to a column-major 4x4 rotation matrix.
        /// Each group of 4 values is one column.
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
                1 - 2 * (yy + zz), 2 * (xy + wz),     2 * (xz - wy),     0,
                2 * (xy - wz),     1 - 2 * (xx + zz), 2 * (yz + wx),     0,
                2 * (xz + wy),     2 * (yz - wx),     1 - 2 * (xx + yy), 0,
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
