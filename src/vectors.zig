const std = @import("std");
const math = @import("std").math;

pub const X = 0;
pub const Y = 1;
pub const Z = 2;
pub const W = 3;

pub const R = 0;
pub const G = 1;
pub const B = 2;
pub const A = 3;

pub fn Vec2(T: type) type {
    return struct {
        const Self = @This();

        pub const Simd = @Vector(2, T);

        d: Simd = std.mem.zeroes(Simd),

        pub const zero = std.mem.zeroes(Self);

        pub inline fn new(x: T, y: T) Self {
            return .{ .d = .{ x, y } };
        }

        pub inline fn one(s: T) Self {
            return .{ .d = .{ s, s } };
        }

        pub inline fn toArray(v: Self) [2]T {
            return @as([2]T, v);
        }

        pub inline fn fromArray(v: [2]T) Self {
            return .new(v[X], v[Y]);
        }

        pub inline fn scale(v: Self, s: T) Self {
            return .new(v[X] * s, v[Y] * s);
        }

        // zig fmt: off
        pub inline fn xyz(v: Self) Vec3(T) { return .new(v.d[X], v.d[Y], 0); }
        pub inline fn xyzw(v: Self) Vec4(T) { return .new(v.d[Y], v.d[Z], 0, 0); }
        // zig fmt: on

        pub inline fn dot(self: Self, other: Self) T {
            return (self.d * other.d)[X] + (self.d * other.d)[Y];
        }

        pub inline fn cross(self: Self, other: Self) T {
            return (self.d[X] * other.d[Y]) - (self.d[Y] * other.d[X]);
        }

        pub inline fn lengthSq(self: Self) T {
            return self.dot(self);
        }

        pub inline fn length(self: Self) T {
            if (@typeInfo(T) != .float) @panic("length() is only supported for floating-point vector types");

            return math.sqrt(self.lengthSq());
        }
    };
}

pub fn Vec3(T: type) type {
    return struct {
        const Self = @This();

        pub const Simd = @Vector(3, T);

        d: Simd = std.mem.zeroes(Simd),

        pub const zero = std.mem.zeroes(Self);

        pub inline fn new(x: T, y: T, z: T) Self {
            return .{ .d = .{ x, y, z } };
        }

        pub inline fn one(s: T) Self {
            return .{ .d = .{ s, s, s } };
        }

        pub inline fn toArray(v: Self) [3]T {
            return @as([3]T, v);
        }

        pub inline fn fromArray(v: [3]T) Self {
            return .new(v[X], v[Y], v[Z]);
        }

        pub inline fn scale(v: Self, s: T) Self {
            return .new(v[X] * s, v[Y] * s, v[Z] * s);
        }

        // zig fmt: off
        pub inline fn xy(v: Self) Vec2(T) { return .new(v.d[X], v.d[Y]); }
        pub inline fn yz(v: Self) Vec2(T) { return .new(v.d[Y], v.d[Z]); }
        pub inline fn xz(v: Self) Vec2(T) { return .new(v.d[X], v.d[Z]); }

        pub inline fn xyzw(v: Self) Vec4(T) { return .new(v.d[X], v.d[Z], 0, 0); }
        // zig fmt: on

        pub inline fn dot(self: Self, other: Self) T {
            return (self.d * other.d)[X] + (self.d * other.d)[Y];
        }

        pub inline fn cross(self: Self, other: Self) T {
            return (self.d[X] * other.d[Y]) - (self.d[Y] * other.d[X]);
        }

        pub inline fn lengthSq(self: Self) T {
            return self.dot(self);
        }

        pub inline fn length(self: Self) T {
            if (@typeInfo(T) != .float) @panic("length() is only supported for floating-point vector types");

            return math.sqrt(self.lengthSq());
        }

        pub inline fn normalize(self: Self) Self {
            if (@typeInfo(T) != .float) @panic("normalize() is only supported for floating-point vector types");

            const len = self.length();
            if (len == 0) return self;
            return .{ .d = self.d / @as(@Vector(3, T), @splat(len)) };
        }
    };
}

pub fn Vec4(T: type) type {
    return struct {
        const Self = @This();

        pub const Simd = @Vector(4, T);

        d: Simd = std.mem.zeroes(Simd),

        pub const zero = std.mem.zeroes(Self);

        pub inline fn new(x: T, y: T, z: T, w: T) Self {
            return .{ .d = .{ x, y, z, w } };
        }

        pub inline fn one(s: T) Self {
            return .{ .d = .{ s, s, s, s } };
        }

        pub inline fn toArray(v: Self) [4]T {
            return @as([4]T, v);
        }

        pub inline fn fromArray(v: [4]T) Self {
            return .new(v[X], v[Y], v[Z], v[W]);
        }

        pub inline fn scale(v: Self, s: T) Self {
            return .new(v[X] * s, v[Y] * s, v[Z] * s, v[W] * s);
        }

        // zig fmt: off
        pub inline fn xy(v: Self) Vec2(T) { return .new(v.d[X], v.d[Y]); }
        pub inline fn yz(v: Self) Vec2(T) { return .new(v.d[Y], v.d[Z]); }
        pub inline fn xz(v: Self) Vec2(T) { return .new(v.d[X], v.d[Z]); }
        pub inline fn xw(v: Self) Vec2(T) { return .new(v.d[X], v.d[W]); }
        pub inline fn yw(v: Self) Vec2(T) { return .new(v.d[Y], v.d[W]); }
        pub inline fn zw(v: Self) Vec2(T) { return .new(v.d[Z], v.d[W]); }

        pub inline fn xyz(v: Self) Vec3(T) { return .new(v.d[X], v.d[Y], v.d[Z]); }
        pub inline fn xzw(v: Self) Vec3(T) { return .new(v.d[X], v.d[Z], v.d[W]); }
        pub inline fn yzw(v: Self) Vec3(T) { return .new(v.d[Y], v.d[Z], v.d[W]); }
        pub inline fn xyw(v: Self) Vec3(T) { return .new(v.d[X], v.d[Y], v.d[W]); }
        // zig fmt: on

        pub inline fn dot(self: Self, other: Self) T {
            return (self.d * other.d)[X] + (self.d * other.d)[Y] + (self.d * other.d)[Z] + (self.d * other.d)[W];
        }

        pub inline fn lengthSq(self: Self) T {
            return self.dot(self);
        }

        pub inline fn length(self: Self) T {
            if (@typeInfo(T) != .float) @panic("length() is only supported for floating-point vector types");

            return math.sqrt(self.lengthSq());
        }

        pub inline fn normalize(self: Self) Self {
            if (@typeInfo(T) != .float) @panic("normalize() is only supported for floating-point vector types");

            const len = self.length();
            if (len == 0) return self;
            return .{ .d = self.d / @as(@Vector(4, T), @splat(len)) };
        }
    };
}

pub fn Mat4(T: type) type {
    return struct {
        const Self = @This();
        data: [16]T,

        pub fn new(data: [16]T) Self {
            return Self{ .data = data };
        }

        pub fn identity() Self {
            var data: [16]T = std.mem.zeroes([16]T);
            data[0] = 1.0;
            data[5] = 1.0;
            data[10] = 1.0;
            data[15] = 1.0;
            return Self.new(data);
        }

        pub fn mul(self: Self, other: Self) Self {
            var result_data: [16]T = std.mem.zeroes([16]T);
            inline for (0..4) |row| {
                inline for (0..4) |col| {
                    var sum: T = 0.0;
                    inline for (0..4) |k| {
                        sum += self.data[row + k * 4] * other.data[k + col * 4];
                    }
                    result_data[row + col * 4] = sum;
                }
            }
            return Self.new(result_data);
        }

        pub fn translate(vec: [3]T) Self {
            var m = Self.identity();
            m.data[12] = vec[0];
            m.data[13] = vec[1];
            m.data[14] = vec[2];
            return m;
        }

        pub fn scale(vec: [3]T) Self {
            var m = Self.identity();
            m.data[0] = vec[0];
            m.data[5] = vec[1];
            m.data[10] = vec[2];
            return m;
        }

        pub fn rotate(angle_rad: T, axis: [3]T) Self {
            if (!@typeInfo(T).isFloat) @compileError("rotate() is only supported for floating-point types.");
            var m = Self.identity();
            const c = math.cos(angle_rad);
            const s = math.sin(angle_rad);
            const C = 1.0 - c;

            var x = axis[0];
            var y = axis[1];
            var z = axis[2];

            const axis_len_sq = x * x + y * y + z * z;
            const axis_len = math.sqrt(axis_len_sq);
            if (axis_len == 0.0) return Self.identity();

            x /= axis_len;
            y /= axis_len;
            z /= axis_len;

            m.data[0] = x * x * C + c;
            m.data[1] = y * x * C + z * s;
            m.data[2] = z * x * C - y * s;
            m.data[3] = 0.0;

            m.data[4] = x * y * C - z * s;
            m.data[5] = y * y * C + c;
            m.data[6] = z * y * C + x * s;
            m.data[7] = 0.0;

            m.data[8] = x * z * C + y * s;
            m.data[9] = y * z * C - x * s;
            m.data[10] = z * z * C + c;
            m.data[11] = 0.0;

            m.data[12] = 0.0;
            m.data[13] = 0.0;
            m.data[14] = 0.0;
            m.data[15] = 1.0;
            return m;
        }

        pub fn perspective(fovy_rad: T, aspect: T, near: T, far: T) Self {
            if (!@typeInfo(T).isFloat) @compileError("perspective() is only supported for floating-point types.");
            var m = Self.identity();
            const tan_half_fovy = math.tan(fovy_rad / 2.0);
            const fov_scale = 1.0 / tan_half_fovy;

            m.data[0] = fov_scale / aspect;
            m.data[1] = 0.0;
            m.data[2] = 0.0;
            m.data[3] = 0.0;

            m.data[4] = 0.0;
            m.data[5] = fov_scale;
            m.data[6] = 0.0;
            m.data[7] = 0.0;

            m.data[8] = 0.0;
            m.data[9] = 0.0;
            m.data[10] = far / (near - far);
            m.data[11] = -1.0;

            m.data[12] = 0.0;
            m.data[13] = 0.0;
            m.data[14] = (far * near) / (near - far);
            m.data[15] = 0.0;
            return m;
        }

        pub fn orthographic(left: T, right: T, bottom: T, top: T, near: T, far: T) Self {
            if (!@typeInfo(T).isFloat) @compileError("orthographic() is only supported for floating-point types.");
            var m = Self.identity();
            m.data[0] = 2.0 / (right - left);
            m.data[1] = 0.0;
            m.data[2] = 0.0;
            m.data[3] = 0.0;

            m.data[4] = 0.0;
            m.data[5] = 2.0 / (top - bottom);
            m.data[6] = 0.0;
            m.data[7] = 0.0;

            m.data[8] = 0.0;
            m.data[9] = 0.0;
            m.data[10] = -2.0 / (far - near);
            m.data[11] = 0.0;

            m.data[12] = -(right + left) / (right - left);
            m.data[13] = -(top + bottom) / (top - bottom);
            m.data[14] = -(far + near) / (far - near);
            m.data[15] = 1.0;
            return m;
        }

        fn cross_product_3d_helper(a: [3]T, b: [3]T) [3]T {
            return .{
                (a[1] * b[2]) - (a[2] * b[1]),
                (a[2] * b[0]) - (a[0] * b[2]),
                (a[0] * b[1]) - (a[1] * b[0]),
            };
        }

        pub fn lookAt(eye: [3]T, target: [3]T, up: [3]T) Self {
            if (!@typeInfo(T).isFloat) @compileError("lookAt() is only supported for floating-point types.");
            var m = Self.identity();

            var z_axis = [3]T{ target[0] - eye[0], target[1] - eye[1], target[2] - eye[2] };
            const z_len_sq = z_axis[0] * z_axis[0] + z_axis[1] * z_axis[1] + z_axis[2] * z_axis[2];
            const z_len = math.sqrt(z_len_sq);
            if (z_len == 0.0) return Self.identity();
            z_axis[0] /= z_len;
            z_axis[1] /= z_len;
            z_axis[2] /= z_len;

            var x_axis = Self.cross_product_3d_helper(up, z_axis);
            const x_len_sq = x_axis[0] * x_axis[0] + x_axis[1] * x_axis[1] + x_axis[2] * x_axis[2];
            const x_len = math.sqrt(x_len_sq);
            if (x_len == 0.0) return Self.identity();
            x_axis[0] /= x_len;
            x_axis[1] /= x_len;
            x_axis[2] /= x_len;

            const y_axis = Self.cross_product_3d_helper(z_axis, x_axis);

            m.data[0] = x_axis[0];
            m.data[1] = y_axis[0];
            m.data[2] = z_axis[0];
            m.data[3] = 0.0;

            m.data[4] = x_axis[1];
            m.data[5] = y_axis[1];
            m.data[6] = z_axis[1];
            m.data[7] = 0.0;

            m.data[8] = x_axis[2];
            m.data[9] = y_axis[2];
            m.data[10] = z_axis[2];
            m.data[11] = 0.0;

            m.data[12] = -(x_axis[0] * eye[0] + x_axis[1] * eye[1] + x_axis[2] * eye[2]);
            m.data[13] = -(y_axis[0] * eye[0] + y_axis[1] * eye[1] + y_axis[2] * eye[2]);
            m.data[14] = -(z_axis[0] * eye[0] + z_axis[1] * eye[1] + z_axis[2] * eye[2]);
            m.data[15] = 1.0;
            return m;
        }

        pub fn transpose(self: Self) Self {
            var transposed_data: [16]T = undefined;
            inline for (0..4) |row| {
                inline for (0..4) |col| {
                    transposed_data[col * 4 + row] = self.data[row * 4 + col];
                }
            }
            return Self.new(transposed_data);
        }

        pub fn inverse(self: Self) Self {
            if (!@typeInfo(T).isFloat) @compileError("inverse() is only supported for floating-point types.");

            const m = self.data;

            var inv: [16]T = undefined;

            inv[0] = m[5] * m[10] * m[15] - m[5] * m[11] * m[14] - m[9] * m[6] * m[15] + m[9] * m[7] * m[14] + m[13] * m[6] * m[11] - m[13] * m[7] * m[10];
            inv[4] = -m[4] * m[10] * m[15] + m[4] * m[11] * m[14] + m[8] * m[6] * m[15] - m[8] * m[7] * m[14] - m[12] * m[6] * m[11] + m[12] * m[7] * m[10];
            inv[8] = m[4] * m[9] * m[15] - m[4] * m[11] * m[13] - m[8] * m[5] * m[15] + m[8] * m[7] * m[13] + m[12] * m[5] * m[11] - m[12] * m[7] * m[9];
            inv[12] = -m[4] * m[9] * m[14] + m[4] * m[10] * m[13] + m[8] * m[5] * m[14] - m[8] * m[6] * m[13] - m[12] * m[5] * m[10] + m[12] * m[6] * m[9];

            inv[1] = -m[1] * m[10] * m[15] + m[1] * m[11] * m[14] + m[9] * m[2] * m[15] - m[9] * m[3] * m[14] - m[13] * m[2] * m[11] + m[13] * m[3] * m[10];
            inv[5] = m[0] * m[10] * m[15] - m[0] * m[11] * m[14] - m[8] * m[2] * m[15] + m[8] * m[3] * m[14] + m[12] * m[2] * m[11] - m[12] * m[3] * m[10];
            inv[9] = -m[0] * m[9] * m[15] + m[0] * m[11] * m[13] + m[8] * m[1] * m[15] - m[8] * m[3] * m[13] - m[12] * m[1] * m[11] + m[12] * m[3] * m[9];
            inv[13] = m[0] * m[9] * m[14] - m[0] * m[10] * m[13] - m[8] * m[1] * m[14] + m[8] * m[2] * m[13] + m[12] * m[1] * m[10] - m[12] * m[2] * m[9];

            inv[2] = m[1] * m[6] * m[15] - m[1] * m[7] * m[14] - m[5] * m[2] * m[15] + m[5] * m[3] * m[14] + m[13] * m[2] * m[7] - m[13] * m[3] * m[6];
            inv[6] = -m[0] * m[6] * m[15] + m[0] * m[7] * m[14] + m[4] * m[2] * m[15] - m[4] * m[3] * m[14] - m[12] * m[2] * m[7] + m[12] * m[3] * m[6];
            inv[10] = m[0] * m[5] * m[15] - m[0] * m[7] * m[13] - m[4] * m[1] * m[15] + m[4] * m[3] * m[13] + m[12] * m[1] * m[7] - m[12] * m[3] * m[5];
            inv[14] = -m[0] * m[5] * m[14] + m[0] * m[6] * m[13] + m[4] * m[1] * m[14] - m[4] * m[2] * m[13] - m[12] * m[1] * m[6] + m[12] * m[2] * m[5];

            inv[3] = -m[1] * m[6] * m[11] + m[1] * m[7] * m[10] + m[5] * m[2] * m[11] - m[5] * m[3] * m[10] - m[9] * m[2] * m[7] + m[9] * m[3] * m[6];
            inv[7] = m[0] * m[6] * m[11] - m[0] * m[7] * m[10] - m[4] * m[2] * m[11] + m[4] * m[3] * m[10] + m[8] * m[2] * m[7] - m[8] * m[3] * m[6];
            inv[11] = -m[0] * m[5] * m[11] + m[0] * m[7] * m[9] + m[4] * m[1] * m[11] - m[4] * m[3] * m[9] - m[8] * m[1] * m[7] + m[8] * m[3] * m[5];
            inv[15] = m[0] * m[5] * m[10] - m[0] * m[6] * m[9] - m[4] * m[1] * m[10] + m[4] * m[2] * m[9] + m[8] * m[1] * m[6] - m[8] * m[2] * m[5];

            const det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];

            if (det == 0) return Self.identity();

            const inv_det = 1.0 / det;
            var result_data: [16]T = undefined;
            inline for (0..16) |i| {
                result_data[i] = inv[i] * inv_det;
            }
            return Self.new(result_data);
        }
    };
}
