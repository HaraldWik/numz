const std = @import("std");
const math = @import("std").math;

pub fn Mat4(T: type) type {
    return struct {
        const Self = @This();

        d: [16]T,

        pub fn new(data: [16]T) Self {
            return Self{ .d = data };
        }

        pub fn identity(diagonal: T) Self {
            const zero = std.mem.zeroes(T);

            return .new(.{
                diagonal, zero,     zero,     zero,
                zero,     diagonal, zero,     zero,
                zero,     zero,     diagonal, zero,
                zero,     zero,     zero,     diagonal,
            });
        }

        pub fn mul(m1: Self, m2: Self) Self {
            var result_data: [16]T = std.mem.zeroes([16]T);
            inline for (0..4) |row| {
                inline for (0..4) |col| {
                    var sum: T = 0.0;
                    inline for (0..4) |k| {
                        sum += m1.d[row + k * 4] * m2.d[k + col * 4];
                    }
                    result_data[row + col * 4] = sum;
                }
            }
            return Self.new(result_data);
        }

        pub fn translate(v: Vec3(T)) Self {
            var m = Self.identity(1);
            m.d[12] = v[0];
            m.d[13] = v[1];
            m.d[14] = v[2];
            return m;
        }

        pub fn scale(v: Vec3(T)) Self {
            var m = Self.identity(1);
            m.d[0] = v[0];
            m.d[5] = v[1];
            m.d[10] = v[2];
            return m;
        }

        pub fn rotate(angle_rad: T, v: Vec3(T)) Self {
            if (@typeInfo(T) != .float) @compileError("rotate() is only supported for floating-point types.");
            var m = Self.identity(1);
            const c = math.cos(angle_rad);
            const s = math.sin(angle_rad);
            const C = 1.0 - c;

            var x = v[0];
            var y = v[1];
            var z = v[2];

            const axis_len_sq = x * x + y * y + z * z;
            const axis_len = math.sqrt(axis_len_sq);
            if (axis_len == 0.0) return Self.identity(1);

            x /= axis_len;
            y /= axis_len;
            z /= axis_len;

            m.d[0] = x * x * C + c;
            m.d[1] = y * x * C + z * s;
            m.d[2] = z * x * C - y * s;
            m.d[3] = 0.0;

            m.d[4] = x * y * C - z * s;
            m.d[5] = y * y * C + c;
            m.d[6] = z * y * C + x * s;
            m.d[7] = 0.0;

            m.d[8] = x * z * C + y * s;
            m.d[9] = y * z * C - x * s;
            m.d[10] = z * z * C + c;
            m.d[11] = 0.0;

            m.d[12] = 0.0;
            m.d[13] = 0.0;
            m.d[14] = 0.0;
            m.d[15] = 1.0;
            return m;
        }

        pub fn perspective(fovy_rad: T, aspect: T, near: T, far: T) Self {
            if (@typeInfo(T) != .float) @compileError("perspective() is only supported for floating-point types.");
            var m = Self.identity(1);
            const tan_half_fovy = math.tan(fovy_rad / 2.0);
            const fov_scale = 1.0 / tan_half_fovy;

            m.d[0] = fov_scale / aspect;
            m.d[1] = 0.0;
            m.d[2] = 0.0;
            m.d[3] = 0.0;

            m.d[4] = 0.0;
            m.d[5] = fov_scale;
            m.d[6] = 0.0;
            m.d[7] = 0.0;

            m.d[8] = 0.0;
            m.d[9] = 0.0;
            m.d[10] = far / (near - far);
            m.d[11] = -1.0;

            m.d[12] = 0.0;
            m.d[13] = 0.0;
            m.d[14] = (far * near) / (near - far);
            m.d[15] = 0.0;
            return m;
        }

        pub fn orthographic(left: T, right: T, bottom: T, top: T, near: T, far: T) Self {
            if (@typeInfo(T) != .float) @compileError("orthographic() is only supported for floating-point types.");
            var m = Self.identity(1);
            m.d[0] = 2.0 / (right - left);
            m.d[1] = 0.0;
            m.d[2] = 0.0;
            m.d[3] = 0.0;

            m.d[4] = 0.0;
            m.d[5] = 2.0 / (top - bottom);
            m.d[6] = 0.0;
            m.d[7] = 0.0;

            m.d[8] = 0.0;
            m.d[9] = 0.0;
            m.d[10] = -2.0 / (far - near);
            m.d[11] = 0.0;

            m.d[12] = -(right + left) / (right - left);
            m.d[13] = -(top + bottom) / (top - bottom);
            m.d[14] = -(far + near) / (far - near);
            m.d[15] = 1.0;
            return m;
        }

        fn crossProduct3D(a: Vec3(f32), b: Vec3(f32)) Vec3(f32) {
            return Vec3(f32){
                (a[1] * b[2]) - (a[2] * b[1]),
                (a[2] * b[0]) - (a[0] * b[2]),
                (a[0] * b[1]) - (a[1] * b[0]),
            };
        }

        pub fn lookAt(eye: Vec3(f32), target: Vec3(f32), up: Vec3(f32)) Self {
            if (@typeInfo(T) != .float) @compileError("lookAt() is only supported for floating-point types.");
            var m = Self.identity(1);

            var z_axis = Vec3(f32){ target[0] - eye[0], target[1] - eye[1], target[2] - eye[2] };
            const z_len_sq = z_axis[0] * z_axis[0] + z_axis[1] * z_axis[1] + z_axis[2] * z_axis[2];
            const z_len = math.sqrt(z_len_sq);
            if (z_len == 0.0) return Self.identity(1);
            z_axis[0] /= z_len;
            z_axis[1] /= z_len;
            z_axis[2] /= z_len;

            var x_axis = crossProduct3D(up, z_axis);
            const x_len_sq = x_axis[0] * x_axis[0] + x_axis[1] * x_axis[1] + x_axis[2] * x_axis[2];
            const x_len = math.sqrt(x_len_sq);
            if (x_len == 0.0) return Self.identity(1);
            x_axis[0] /= x_len;
            x_axis[1] /= x_len;
            x_axis[2] /= x_len;

            const y_axis = crossProduct3D(z_axis, x_axis);

            m.d[0] = x_axis[0];
            m.d[1] = y_axis[0];
            m.d[2] = z_axis[0];
            m.d[3] = 0.0;

            m.d[4] = x_axis[1];
            m.d[5] = y_axis[1];
            m.d[6] = z_axis[1];
            m.d[7] = 0.0;

            m.d[8] = x_axis[2];
            m.d[9] = y_axis[2];
            m.d[10] = z_axis[2];
            m.d[11] = 0.0;

            m.d[12] = -(x_axis[0] * eye.d[0] + x_axis[1] * eye.d[1] + x_axis[2] * eye.d[2]);
            m.d[13] = -(y_axis[0] * eye.d[0] + y_axis[1] * eye.d[1] + y_axis[2] * eye.d[2]);
            m.d[14] = -(z_axis[0] * eye.d[0] + z_axis[1] * eye.d[1] + z_axis[2] * eye.d[2]);
            m.d[15] = 1.0;
            return m;
        }

        pub fn transpose(m: Self) Self {
            var transposed_data: [16]T = undefined;
            inline for (0..4) |row| {
                inline for (0..4) |col| {
                    transposed_data[col * 4 + row] = m.d[row * 4 + col];
                }
            }
            return .new(transposed_data);
        }

        pub fn inverse(m: Self) Self {
            if (@typeInfo(T) != .float) @compileError("inverse() is only supported for floating-point types.");

            var inv: [16]T = undefined;

            inv[0] = m.d[5] * m.d[10] * m.d[15] - m.d[5] * m.d[11] * m.d[14] - m.d[9] * m.d[6] * m.d[15] + m.d[9] * m.d[7] * m.d[14] + m.d[13] * m.d[6] * m.d[11] - m.d[13] * m.d[7] * m.d[10];
            inv[4] = -m.d[4] * m.d[10] * m.d[15] + m.d[4] * m.d[11] * m.d[14] + m.d[8] * m.d[6] * m.d[15] - m.d[8] * m.d[7] * m.d[14] - m.d[12] * m.d[6] * m.d[11] + m.d[12] * m.d[7] * m.d[10];
            inv[8] = m.d[4] * m.d[9] * m.d[15] - m.d[4] * m.d[11] * m.d[13] - m.d[8] * m.d[5] * m.d[15] + m.d[8] * m.d[7] * m.d[13] + m.d[12] * m.d[5] * m.d[11] - m.d[12] * m.d[7] * m.d[9];
            inv[12] = -m.d[4] * m.d[9] * m.d[14] + m.d[4] * m.d[10] * m.d[13] + m.d[8] * m.d[5] * m.d[14] - m.d[8] * m.d[6] * m.d[13] - m.d[12] * m.d[5] * m.d[10] + m.d[12] * m.d[6] * m.d[9];

            inv[1] = -m.d[1] * m.d[10] * m.d[15] + m.d[1] * m.d[11] * m.d[14] + m.d[9] * m.d[2] * m.d[15] - m.d[9] * m.d[3] * m.d[14] - m.d[13] * m.d[2] * m.d[11] + m.d[13] * m.d[3] * m.d[10];
            inv[5] = m.d[0] * m.d[10] * m.d[15] - m.d[0] * m.d[11] * m.d[14] - m.d[8] * m.d[2] * m.d[15] + m.d[8] * m.d[3] * m.d[14] + m.d[12] * m.d[2] * m.d[11] - m.d[12] * m.d[3] * m.d[10];
            inv[9] = -m.d[0] * m.d[9] * m.d[15] + m.d[0] * m.d[11] * m.d[13] + m.d[8] * m.d[1] * m.d[15] - m.d[8] * m.d[3] * m.d[13] - m.d[12] * m.d[1] * m.d[11] + m.d[12] * m.d[3] * m.d[9];
            inv[13] = m.d[0] * m.d[9] * m.d[14] - m.d[0] * m.d[10] * m.d[13] - m.d[8] * m.d[1] * m.d[14] + m.d[8] * m.d[2] * m.d[13] + m.d[12] * m.d[1] * m.d[10] - m.d[12] * m.d[2] * m.d[9];

            inv[2] = m.d[1] * m.d[6] * m.d[15] - m.d[1] * m.d[7] * m.d[14] - m.d[5] * m.d[2] * m.d[15] + m.d[5] * m.d[3] * m.d[14] + m.d[13] * m.d[2] * m.d[7] - m.d[13] * m.d[3] * m.d[6];
            inv[6] = -m.d[0] * m.d[6] * m.d[15] + m.d[0] * m.d[7] * m.d[14] + m.d[4] * m.d[2] * m.d[15] - m.d[4] * m.d[3] * m.d[14] - m.d[12] * m.d[2] * m.d[7] + m.d[12] * m.d[3] * m.d[6];
            inv[10] = m.d[0] * m.d[5] * m.d[15] - m.d[0] * m.d[7] * m.d[13] - m.d[4] * m.d[1] * m.d[15] + m.d[4] * m.d[3] * m.d[13] + m.d[12] * m.d[1] * m.d[7] - m.d[12] * m.d[3] * m.d[5];
            inv[14] = -m.d[0] * m.d[5] * m.d[14] + m.d[0] * m.d[6] * m.d[13] + m.d[4] * m.d[1] * m.d[14] - m.d[4] * m.d[2] * m.d[13] - m.d[12] * m.d[1] * m.d[6] + m.d[12] * m.d[2] * m.d[5];

            inv[3] = -m.d[1] * m.d[6] * m.d[11] + m.d[1] * m.d[7] * m.d[10] + m.d[5] * m.d[2] * m.d[11] - m.d[5] * m.d[3] * m.d[10] - m.d[9] * m.d[2] * m.d[7] + m.d[9] * m.d[3] * m.d[6];
            inv[7] = m.d[0] * m.d[6] * m.d[11] - m.d[0] * m.d[7] * m.d[10] - m.d[4] * m.d[2] * m.d[11] + m.d[4] * m.d[3] * m.d[10] + m.d[8] * m.d[2] * m.d[7] - m.d[8] * m.d[3] * m.d[6];
            inv[11] = -m.d[0] * m.d[5] * m.d[11] + m.d[0] * m.d[7] * m.d[9] + m.d[4] * m.d[1] * m.d[11] - m.d[4] * m.d[3] * m.d[9] - m.d[8] * m.d[1] * m.d[7] + m.d[8] * m.d[3] * m.d[5];
            inv[15] = m.d[0] * m.d[5] * m.d[10] - m.d[0] * m.d[6] * m.d[9] - m.d[4] * m.d[1] * m.d[10] + m.d[4] * m.d[2] * m.d[9] + m.d[8] * m.d[1] * m.d[6] - m.d[8] * m.d[2] * m.d[5];

            const det = m.d[0] * inv[0] + m.d[1] * inv[4] + m.d[2] * inv[8] + m.d[3] * inv[12];

            if (det == 0) return .identity(1);

            const inv_det = 1.0 / det;
            var result_data: [16]T = undefined;
            inline for (0..16) |i| {
                result_data[i] = inv[i] * inv_det;
            }
            return .new(result_data);
        }

        pub fn fromQuaternion(q: Vec4(T)) Self {
            var m = identity(1);

            // Pre-calculate terms for efficiency
            const x2 = q[0] * q[0];
            const y2 = q[1] * q[1];
            const z2 = q[2] * q[2];
            const xy = q[0] * q[1];
            const xz = q[0] * q[2];
            const yz = q[1] * q[2];
            const wx = q[3] * q[0];
            const wy = q[3] * q[1];
            const wz = q[3] * q[2];

            // Column 0
            m.d[0] = 1.0 - 2.0 * (y2 + z2); // m00
            m.d[1] = 2.0 * (xy + wz); // m10
            m.d[2] = 2.0 * (xz - wy); // m20

            // Column 1
            m.d[4] = 2.0 * (xy - wz); // m01
            m.d[5] = 1.0 - 2.0 * (x2 + z2); // m11
            m.d[6] = 2.0 * (yz + wx); // m21

            m.d[8] = 2.0 * (xz + wy); // m02
            m.d[9] = 2.0 * (yz - wx); // m12
            m.d[10] = 1.0 - 2.0 * (x2 + y2); // m22

            return m;
        }
    };
}

test "Mat4" {
    _ = Mat4(f32).identity(1.0);
    _ = Mat4(f32).mul(.identity(1.0), .identity(1.0));
    _ = Mat4(f32).translate(.{ 1, 2, 3 });
    _ = Mat4(f32).scale(.{ 1, 2, 3 });
    _ = Mat4(f32).rotate(std.math.degreesToRadians(90), .{ 1, 2, 3 });
}

pub fn Vec2(T: type) type {
    return @Vector(2, T);
}
pub fn Vec3(T: type) type {
    return @Vector(3, T);
}
pub fn Vec4(T: type) type {
    return @Vector(4, T);
}

pub fn eql(a: anytype, b: anytype) bool {
    return switch (@typeInfo(@TypeOf(a))) {
        .vector => |info| blk: {
            for (0..info.len) |i| {
                if (a[i] != b[i]) return false;
            }
            break :blk true;
        },
        .array => |info| blk: {
            for (0..info.len) |i| {
                if (a[i] != b[i]) return false;
            }
            break :blk true;
        },
        else => @compileError("Unsupported type in eql()"),
    };
}

pub fn scale(v: anytype, s: @TypeOf(v[0])) @TypeOf(v) {
    return switch (@typeInfo(@TypeOf(v))) {
        .vector => |info| blk: {
            var result: @TypeOf(v) = undefined;
            for (0..info.len) |i| {
                result[i] = v[i] * s;
            }
            break :blk result;
        },
        .array => |info| blk: {
            var result: [info.len]info.child = undefined;
            for (0..info.len) |i| {
                result[i] = v[i] * s;
            }
            break :blk result;
        },
        else => @compileError("Unsupported type in scale()"),
    };
}

pub fn dot(a: anytype, b: anytype) @TypeOf(a[0], b[0]) {
    return switch (@typeInfo(@TypeOf(a))) {
        .vector => |info| blk: {
            var acc: info.child = 0;
            for (0..info.len) |i| acc += a[i] * b[i];
            break :blk acc;
        },
        .array => |info| blk: {
            var acc: info.child = 0;
            for (0..info.len) |i| acc += a[i] * b[i];
            break :blk acc;
        },
        else => @compileError("Unsupported type in dot()"),
    };
}

pub fn length(v: anytype) @TypeOf(v[0]) {
    return std.math.sqrt(dot(v, v));
}

pub fn normalize(v: anytype) @TypeOf(v) {
    const len = length(v);
    if (len == 0) return v;
    return scale(v, 1 / len);
}

pub fn cross(a: anytype, b: anytype) @TypeOf(a) {
    return switch (@typeInfo(@TypeOf(a))) {
        .vector => |info| blk: {
            if (info.len != 3) @compileError("cross() only supports 3D vectors");

            break :blk @as(@TypeOf(a), .{
                a[1] * b[2] - a[2] * b[1],
                a[2] * b[0] - a[0] * b[2],
                a[0] * b[1] - a[1] * b[0],
            });
        },
        .array => |info| blk: {
            if (info.len != 3) @compileError("cross() only supports 3D vectors");

            break :blk [_]info.child{
                a[1] * b[2] - a[2] * b[1],
                a[2] * b[0] - a[0] * b[2],
                a[0] * b[1] - a[1] * b[0],
            };
        },
        else => @compileError("Unsupported type in cross()"),
    };
}

pub inline fn distance(a: anytype, b: anytype) @TypeOf(a[0], b[0]) {
    return length(scale(a, 1) - scale(b, 1));
}

pub inline fn distanceSquared(a: anytype, b: anytype) @TypeOf(a[0], b[0]) {
    return dot(scale(a, 1) - scale(b, 1), scale(a, 1) - scale(b, 1));
}

pub inline fn reflect(i: anytype, n: anytype) @TypeOf(i) {
    return i - scale(n, 2 * dot(i, n));
}

pub inline fn mix(a: anytype, b: anytype, t: @TypeOf(b[0], b[0])) @TypeOf(a, b) {
    return scale(a, (1 - t)) + scale(b, t);
}

pub inline fn faceforward(n: anytype, i: anytype, n_ref: anytype) @TypeOf(n) {
    return if (dot(i, n_ref) < 0) n else scale(n, -1);
}

pub inline fn forward(from: anytype, to: anytype) @TypeOf(from) {
    return normalize(to - from);
}

pub inline fn negate(v: anytype) @TypeOf(v) {
    return scale(@TypeOf(v[0]), v, @as(@TypeOf(v[0]), -1));
}

test "scale" {
    const s: f32 = 3.0;

    const v2: Vec2(f32) = .{ 1, 2 };
    const v3: Vec3(f32) = .{ 1, 2, 3 };
    const v4: Vec4(f32) = .{ 1, 2, 3, 4 };

    try std.testing.expect(eql(scale(v2, s), Vec2(f32){ 3, 6 }));
    try std.testing.expect(eql(scale(v3, s), Vec3(f32){ 3, 6, 9 }));
    try std.testing.expect(eql(scale(v4, s), Vec4(f32){ 3, 6, 9, 12 }));
}
test "dot" {
    const a2: Vec2(f32) = .{ 1, 2 };
    const b2: Vec2(f32) = .{ 3, 4 };
    const a3: Vec3(f32) = .{ 1, 2, 3 };
    const b3: Vec3(f32) = .{ 4, 5, 6 };
    const a4: Vec4(f32) = .{ 1, 2, 3, 4 };
    const b4: Vec4(f32) = .{ 5, 6, 7, 8 };

    try std.testing.expect(dot(a2, b2) == 11);
    try std.testing.expect(dot(a3, b3) == 32);
    try std.testing.expect(dot(a4, b4) == 70);
}

test "length" {
    const v2: Vec2(f32) = .{ 3, 4 };
    const v3: Vec3(f32) = .{ 1, 2, 2 };

    try std.testing.expect(@abs(length(v2) - 5) < 0.0001);
    try std.testing.expect(@abs(length(v3) - 3) < 0.0001);
}

test "normalize" {
    const v2: Vec2(f32) = .{ 3, 0 };
    const v3: Vec3(f32) = .{ 0, 4, 0 };
    const v4: Vec4(f32) = .{ 0, 0, 0, 5 };

    try std.testing.expect(eql(normalize(v2), Vec2(f32){ 1, 0 }));
    try std.testing.expect(eql(normalize(v3), Vec3(f32){ 0, 1, 0 }));
    try std.testing.expect(eql(normalize(v4), Vec4(f32){ 0, 0, 0, 1 }));
}

test "cross" {
    const a: Vec3(f32) = .{ 1, 0, 0 };
    const b: Vec3(f32) = .{ 0, 1, 0 };
    try std.testing.expect(eql(cross(a, b), Vec3(f32){ 0, 0, 1 }));
}

test "eql" {
    const a2: Vec2(f32) = .{ 1, 2 };
    const b2: Vec2(f32) = .{ 1, 2 };
    const c2: Vec2(f32) = .{ 3, 4 };

    const a3: Vec3(f32) = .{ 1, 2, 3 };
    const b3: Vec3(f32) = .{ 1, 2, 3 };
    const c3: Vec3(f32) = .{ 4, 5, 6 };

    const a4: Vec4(f32) = .{ 1, 2, 3, 4 };
    const b4: Vec4(f32) = .{ 1, 2, 3, 4 };
    const c4: Vec4(f32) = .{ 5, 6, 7, 8 };

    try std.testing.expect(eql(a2, b2));
    try std.testing.expect(!eql(a2, c2));

    try std.testing.expect(eql(a3, b3));
    try std.testing.expect(!eql(a3, c3));

    try std.testing.expect(eql(a4, b4));
    try std.testing.expect(!eql(a4, c4));
}

test "distance" {
    const a: Vec2(f32) = .{ 0, 0 };
    const b: Vec2(f32) = .{ 3, 4 };
    try std.testing.expect(distance(a, b) == 5);
}

test "distanceSquared" {
    const a: Vec3(f32) = .{ 1, 2, 3 };
    const b: Vec3(f32) = .{ 4, 6, 3 };
    try std.testing.expect(distanceSquared(a, b) == 25);
}

test "reflect" {
    const i: Vec2(f32) = .{ 1, -1 };
    const n: Vec2(f32) = .{ 0, 1 };
    try std.testing.expect(eql(reflect(i, n), Vec2(f32){ 1, 1 }));
}

test "mix" {
    const a: Vec3(f32) = .{ 0, 0, 0 };
    const b: Vec3(f32) = .{ 10, 10, 10 };
    try std.testing.expect(eql(mix(a, b, 0.5), Vec3(f32){ 5, 5, 5 }));
}

test "faceforward" {
    const n: Vec3(f32) = .{ 0, 0, 1 };
    const i: Vec3(f32) = .{ 0, 0, -1 };
    const n_ref: Vec3(f32) = .{ 0, 0, 1 };
    try std.testing.expect(eql(faceforward(n, i, n_ref), Vec3(f32){ 0, 0, -1 }));
}

test "forward" {
    const from: Vec3(f32) = .{ 0, 0, 0 };
    const to: Vec3(f32) = .{ 0, 0, 1 };

    const dir = forward(from, to);
    try std.testing.expect(eql(dir, Vec3(f32){ 0, 0, 1 }));
}

test "negate" {
    const v: Vec4(f32) = .{ 1, -2, 3, -4 };
    try std.testing.expect(eql(negate(v), Vec4(f32){ -1, 2, -3, 4 }));
}
