const std = @import("std");

pub fn @"4x4"(T: type) type {
    return struct {
        d: [16]T,

        pub fn new(data: [16]T) @This() {
            return .{ .d = data };
        }

        pub fn identity(diagonal: T) @This() {
            const zero = std.mem.zeroes(T);

            return .new(.{
                diagonal, zero,     zero,     zero,
                zero,     diagonal, zero,     zero,
                zero,     zero,     diagonal, zero,
                zero,     zero,     zero,     diagonal,
            });
        }

        pub fn mul(m1: @This(), m2: @This()) @This() {
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
            return .new(result_data);
        }

        pub fn translate(v: @Vector(3, T)) @This() {
            var m: @This() = .identity(1);
            m.d[12] = v[0];
            m.d[13] = v[1];
            m.d[14] = v[2];
            return m;
        }

        pub fn scale(v: @Vector(3, T)) @This() {
            var m: @This() = .identity(1);
            m.d[0] = v[0];
            m.d[5] = v[1];
            m.d[10] = v[2];
            return m;
        }

        /// Standard Rodrigues’ rotation matrix.
        /// Creates a 4×4 rotation matrix from an axis and angle (in radians),
        /// normalizing the axis internally. Follows the right-hand rule and
        /// returns the identity matrix if the axis length is zero.
        pub fn rotate(angle_rad: T, v: @Vector(3, T)) @This() {
            if (@typeInfo(T) != .float) @compileError("rotate() is only supported for floating-point types.");
            const cos = std.math.cos(angle_rad);
            const sin = std.math.sin(angle_rad);
            const c = 1.0 - cos;

            const axis_len_sq = v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
            const axis_len = std.math.sqrt(axis_len_sq);
            if (axis_len == 0.0) return @This().identity(1);

            v[0] /= axis_len;
            v[1] /= axis_len;
            v[2] /= axis_len;

            return .new(.{
                v[0] * v[0] * c + cos,        v[1] * v[0] * c + v[2] * sin, v[2] * v[0] * c - v[1] * sin, 0.0,
                v[0] * v[1] * c - v[2] * sin, v[1] * v[1] * c + cos,        v[2] * v[1] * c + v[0] * sin, 0.0,
                v[0] * v[2] * c + v[1] * sin, v[1] * v[2] * c - v[0] * sin, v[2] * v[2] * c + cos,        0.0,
                0.0,                          0.0,                          0.0,                          1.0,
            });
        }

        /// Creates a standard right-handed perspective projection matrix.
        ///
        /// Parameters:
        /// - `fovy_rad`: Vertical field of view, in radians.
        /// - `aspect`: Aspect ratio (width / height).
        /// - `near`: Distance to the near clipping plane (must be > 0).
        /// - `far`: Distance to the far clipping plane.
        ///
        /// Produces a 4×4 matrix suitable for projecting 3D coordinates into
        /// normalized device coordinates (NDC) in Vulkan-style clip space,
        /// where Z ranges from 0 to 1 and Y is up.
        pub fn perspective(fovy_rad: T, aspect: T, near: T, far: T) @This() {
            if (@typeInfo(T) != .float) @compileError("perspective() is only supported for floating-point types.");
            const fov_scale = 1.0 / std.math.tan(fovy_rad / 2.0);

            return .new(.{
                fov_scale / aspect, 0.0,       0.0,                         0.0,
                0.0,                fov_scale, 0.0,                         0.0,
                0.0,                0.0,       far / (near - far),          -1.0,
                0.0,                0.0,       (far * near) / (near - far), 0.0,
            });
        }

        /// Creates a right-handed orthographic projection matrix.
        ///
        /// Parameters:
        /// - `left`, `right`: The left and right bounds of the view volume.
        /// - `bottom`, `top`: The bottom and top bounds of the view volume.
        /// - `near`, `far`: The distances to the near and far clipping planes.
        ///
        /// Produces a 4×4 matrix that maps the specified cuboid volume
        /// into normalized device coordinates (NDC) in Vulkan-style clip space,
        /// where X, Y ∈ [-1, 1] and Z ∈ [0, 1].
        ///
        /// Unlike perspective projection, this maintains parallel lines without
        /// introducing perspective distortion.
        pub fn orthographic(left: T, right: T, bottom: T, top: T, near: T, far: T) @This() {
            if (@typeInfo(T) != .float) @compileError("orthographic() is only supported for floating-point types.");
            return .new(.{
                2.0 / (right - left),             0.0,                              0.0,                          0.0,
                0.0,                              2.0 / (top - bottom),             0.0,                          0.0,
                0.0,                              0.0,                              -2.0 / (far - near),          0.0,
                -(right + left) / (right - left), -(top + bottom) / (top - bottom), -(far + near) / (far - near), 1.0,
            });
        }

        /// Computes the 3D cross product of two vectors.
        ///
        /// The result is a vector perpendicular to both `a` and `b`,
        /// with a direction given by the right-hand rule and a magnitude
        /// equal to `|a| * |b| * sin(theta)`, where `theta` is the angle
        /// between them.
        ///
        /// Parameters:
        /// - `a`: First input vector.
        /// - `b`: Second input vector.
        ///
        /// Returns:
        /// - A new vector representing `a × b`.
        fn crossProduct3D(a: @Vector(3, f32), b: @Vector(3, f32)) @Vector(3, f32) {
            return .new(.{
                (a[1] * b[2]) - (a[2] * b[1]),
                (a[2] * b[0]) - (a[0] * b[2]),
                (a[0] * b[1]) - (a[1] * b[0]),
            });
        }

        pub fn lookAt(eye: @Vector(3, f32), target: @Vector(3, f32), up: @Vector(3, f32)) @This() {
            if (@typeInfo(T) != .float) @compileError("lookAt() is only supported for floating-point types.");
            var m: @This() = .identity(1);

            var z_axis = @Vector(3, f32){ target[0] - eye[0], target[1] - eye[1], target[2] - eye[2] };
            const z_len_sq = z_axis[0] * z_axis[0] + z_axis[1] * z_axis[1] + z_axis[2] * z_axis[2];
            const z_len = std.math.sqrt(z_len_sq);
            if (z_len == 0.0) return .identity(1);
            z_axis[0] /= z_len;
            z_axis[1] /= z_len;
            z_axis[2] /= z_len;

            var x_axis = crossProduct3D(up, z_axis);
            const x_len_sq = x_axis[0] * x_axis[0] + x_axis[1] * x_axis[1] + x_axis[2] * x_axis[2];
            const x_len = std.math.sqrt(x_len_sq);
            if (x_len == 0.0) return .identity(1);
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

        pub fn transpose(m: @This()) @This() {
            var transposed_data: [16]T = undefined;
            inline for (0..4) |row| {
                inline for (0..4) |col| {
                    transposed_data[col * 4 + row] = m.d[row * 4 + col];
                }
            }
            return .new(transposed_data);
        }

        pub fn inverse(m: @This()) @This() {
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

        pub fn fromQuaternion(q: @Vector(4, T)) @This() {
            var m: @This() = .identity(1);

            // Pre-calculate terms for efficiency
            const x2 = q[0] * q[0];
            const y2 = q[1] * q[1];
            const z2 = q[2] * q[2];
            const _xy = q[0] * q[1];
            const _xz = q[0] * q[2];
            const _yz = q[1] * q[2];
            const _wx = q[3] * q[0];
            const _wy = q[3] * q[1];
            const _wz = q[3] * q[2];

            // Column 0
            m.d[0] = 1.0 - 2.0 * (y2 + z2); // m00
            m.d[1] = 2.0 * (_xy + _wz); // m10
            m.d[2] = 2.0 * (_xy - _wy); // m20

            // Column 1
            m.d[4] = 2.0 * (_xy - _wz); // m01
            m.d[5] = 1.0 - 2.0 * (x2 + z2); // m11
            m.d[6] = 2.0 * (_yz + _wx); // m21

            m.d[8] = 2.0 * (_xz + _wy); // m02
            m.d[9] = 2.0 * (_yz - _wx); // m12
            m.d[10] = 1.0 - 2.0 * (x2 + y2); // m22

            return m;
        }

        pub fn toQuaternion(m: @This()) @Vector(4, T) {
            var q: @Vector(4, T) = undefined;

            const trace = m.d[0] + m.d[5] + m.d[10]; // sum of diagonal elements

            if (trace > 0) {
                const s = @sqrt(trace + 1.0) * 2.0;
                q[3] = 0.25 * s; // w
                q[0] = (m.d[9] - m.d[6]) / s; // x
                q[1] = (m.d[2] - m.d[8]) / s; // y
                q[2] = (m.d[4] - m.d[1]) / s; // z
            } else if ((m.d[0] > m.d[5]) and (m.d[0] > m.d[10])) {
                const s = @sqrt(1.0 + m.d[0] - m.d[5] - m.d[10]) * 2.0;
                q[3] = (m.d[9] - m.d[6]) / s; // w
                q[0] = 0.25 * s; // x
                q[1] = (m.d[1] + m.d[4]) / s; // y
                q[2] = (m.d[2] + m.d[8]) / s; // z
            } else if (m.d[5] > m.d[10]) {
                const s = @sqrt(1.0 + m.d[5] - m.d[0] - m.d[10]) * 2.0;
                q[3] = (m.d[2] - m.d[8]) / s; // w
                q[0] = (m.d[1] + m.d[4]) / s; // x
                q[1] = 0.25 * s; // y
                q[2] = (m.d[6] + m.d[9]) / s; // z
            } else {
                const s = @sqrt(1.0 + m.d[10] - m.d[0] - m.d[5]) * 2.0;
                q[3] = (m.d[4] - m.d[1]) / s; // w
                q[0] = (m.d[2] + m.d[8]) / s; // x
                q[1] = (m.d[6] + m.d[9]) / s; // y
                q[2] = 0.25 * s; // z
            }

            return q;
        }
    };
}

test "Mat4" {
    _ = @"4x4"(f32).identity(1.0);
    _ = @"4x4"(f32).mul(.identity(1.0), .identity(1.0));
    _ = @"4x4"(f32).translate(.{ 1, 2, 3 });
    _ = @"4x4"(f32).scale(.{ 1, 2, 3 });
    _ = @"4x4"(f32).rotate(std.math.degreesToRadians(90), .{ 1, 2, 3 });
}
