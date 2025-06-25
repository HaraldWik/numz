const std = @import("std");
const math = @import("std").math;
const root = @import("root");

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

        pub fn translate(v: root.Vec3(T)) Self {
            var m = Self.identity(1);
            m.d[12] = v.d[0];
            m.d[13] = v.d[1];
            m.d[14] = v.d[2];
            return m;
        }

        pub fn scale(v: root.Vec3(T)) Self {
            var m = Self.identity(1);
            m.d[0] = v.d[0];
            m.d[5] = v.d[1];
            m.d[10] = v.d[2];
            return m;
        }

        pub fn rotate(angle_rad: T, v: root.Vec3(T)) Self {
            if (!@typeInfo(T).isFloat) @compileError("rotate() is only supported for floating-point types.");
            var m = Self.identity(1);
            const c = math.cos(angle_rad);
            const s = math.sin(angle_rad);
            const C = 1.0 - c;

            var x = v.d[0];
            var y = v.d[1];
            var z = v.d[2];

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
            if (!@typeInfo(T).isFloat) @compileError("perspective() is only supported for floating-point types.");
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
            if (!@typeInfo(T).isFloat) @compileError("orthographic() is only supported for floating-point types.");
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

        fn crossProduct3D(a: root.Vec3(f32), b: root.Vec3(f32)) root.Vec3(f32) {
            return .new(
                (a[1] * b[2]) - (a[2] * b[1]),
                (a[2] * b[0]) - (a[0] * b[2]),
                (a[0] * b[1]) - (a[1] * b[0]),
            );
        }

        pub fn lookAt(eye: root.Vec3(f32), target: root.Vec3(f32), up: root.Vec3(f32)) Self {
            if (!@typeInfo(T).isFloat) @compileError("lookAt() is only supported for floating-point types.");
            var m = Self.identity(1);

            var z_axis = root.Vec3(f32).new(target.d[0] - eye.d[0], target.d[1] - eye.d[1], target.d[2] - eye.d[2]);
            const z_len_sq = z_axis[0] * z_axis[0] + z_axis[1] * z_axis[1] + z_axis[2] * z_axis[2];
            const z_len = math.sqrt(z_len_sq);
            if (z_len == 0.0) return Self.identity(1);
            z_axis.d[0] /= z_len;
            z_axis.d[1] /= z_len;
            z_axis.d[2] /= z_len;

            var x_axis = crossProduct3D(up, z_axis);
            const x_len_sq = x_axis.d[0] * x_axis.d[0] + x_axis.d[1] * x_axis.d[1] + x_axis.d[2] * x_axis.d[2];
            const x_len = math.sqrt(x_len_sq);
            if (x_len == 0.0) return Self.identity(1);
            x_axis.d[0] /= x_len;
            x_axis.d[1] /= x_len;
            x_axis.d[2] /= x_len;

            const y_axis = crossProduct3D(z_axis, x_axis);

            m.d[0] = x_axis.d[0];
            m.d[1] = y_axis.d[0];
            m.d[2] = z_axis.d[0];
            m.d[3] = 0.0;

            m.d[4] = x_axis.d[1];
            m.d[5] = y_axis.d[1];
            m.d[6] = z_axis.d[1];
            m.d[7] = 0.0;

            m.d[8] = x_axis.d[2];
            m.d[9] = y_axis.d[2];
            m.d[10] = z_axis.d[2];
            m.d[11] = 0.0;

            m.d[12] = -(x_axis.d[0] * eye.d[0] + x_axis.d[1] * eye.d[1] + x_axis.d[2] * eye.d[2]);
            m.d[13] = -(y_axis.d[0] * eye.d[0] + y_axis.d[1] * eye.d[1] + y_axis.d[2] * eye.d[2]);
            m.d[14] = -(z_axis.d[0] * eye.d[0] + z_axis.d[1] * eye.d[1] + z_axis.d[2] * eye.d[2]);
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
            if (!@typeInfo(T).isFloat) @compileError("inverse() is only supported for floating-point types.");

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
    };
}
const testing = @import("std").testing;
