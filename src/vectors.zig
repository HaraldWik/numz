const std = @import("std");
const math = @import("std").math;

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

pub fn scale(comptime T: type, v: anytype, s: T) @TypeOf(v) {
    return switch (@typeInfo(@TypeOf(v))) {
        .vector => |info| blk: {
            var result: @TypeOf(v) = undefined;
            for (0..info.len) |i| {
                result[i] = v[i] * s;
            }
            break :blk result;
        },
        .array => |info| blk: {
            var result: [info.len]T = undefined;
            for (0..info.len) |i| {
                result[i] = v[i] * s;
            }
            break :blk result;
        },
        else => @compileError("Unsupported type in scale()"),
    };
}

pub fn dot(comptime T: type, a: anytype, b: anytype) T {
    return switch (@typeInfo(@TypeOf(a))) {
        .vector => |info| blk: {
            var acc: T = 0;
            for (0..info.len) |i| acc += a[i] * b[i];
            break :blk acc;
        },
        .array => |info| blk: {
            var acc: T = 0;
            for (0..info.len) |i| acc += a[i] * b[i];
            break :blk acc;
        },
        else => @compileError("Unsupported type in dot()"),
    };
}

pub fn length(comptime T: type, v: anytype) T {
    return std.math.sqrt(dot(T, v, v));
}

pub fn normalize(comptime T: type, v: anytype) @TypeOf(v) {
    const len = length(T, v);
    if (len == 0) return v;
    return scale(T, v, 1 / len);
}

pub fn cross(comptime T: type, a: anytype, b: anytype) @TypeOf(a) {
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

            break :blk [_]T{
                a[1] * b[2] - a[2] * b[1],
                a[2] * b[0] - a[0] * b[2],
                a[0] * b[1] - a[1] * b[0],
            };
        },
        else => @compileError("Unsupported type in cross()"),
    };
}

pub fn componentwiseOp(comptime T: type, v: anytype, op: fn (T) T) @TypeOf(v) {
    return switch (@typeInfo(@TypeOf(v))) {
        .vector => |info| blk: {
            var result: @TypeOf(v) = undefined;
            for (0..info.len) |i| result[i] = op(v[i]);
            break :blk result;
        },
        .array => |info| blk: {
            var result: [info.len]T = undefined;
            for (0..info.len) |i| result[i] = op(v[i]);
            break :blk result;
        },
        else => @compileError("Unsupported type in componentwiseOp()"),
    };
}

pub fn abs(v: anytype) @TypeOf(v) {
    return switch (@typeInfo(@TypeOf(v))) {
        .vector => |info| blk: {
            var result: @TypeOf(v) = undefined;
            for (0..info.len) |i| {
                result[i] = @abs(@as(info.child, v[i]));
            }
            break :blk result;
        },
        .array => |info| blk: {
            var result: [info.len]info.child = undefined;
            for (0..info.len) |i| {
                result[i] = @abs(@as(info.child, v[i]));
            }
            break :blk result;
        },
        else => @compileError("Unsupported type in abs()"),
    };
}

pub fn floor(comptime T: type, v: anytype) @TypeOf(v) {
    return componentwiseOp(T, v, std.math.floor);
}

pub fn ceil(comptime T: type, v: anytype) @TypeOf(v) {
    return componentwiseOp(T, v, std.math.ceil);
}

pub fn round(comptime T: type, v: anytype) @TypeOf(v) {
    return componentwiseOp(T, v, std.math.round);
}

pub fn sign(comptime T: type, v: anytype) @TypeOf(v) {
    return componentwiseOp(T, v, std.math.sign);
}

pub fn min(comptime T: type, a: anytype, b: anytype) @TypeOf(a) {
    return switch (@typeInfo(@TypeOf(a))) {
        .vector => |info| blk: {
            var result: @TypeOf(a) = undefined;
            for (0..info.len) |i| {
                result[i] = if (a[i] < b[i]) a[i] else b[i];
            }
            break :blk result;
        },
        .array => |info| blk: {
            var result: [info.len]T = undefined;
            for (0..info.len) |i| {
                result[i] = if (a[i] < b[i]) a[i] else b[i];
            }
            break :blk result;
        },
        else => @compileError("Unsupported type in min()"),
    };
}

pub fn max(comptime T: type, a: anytype, b: anytype) @TypeOf(a) {
    return switch (@typeInfo(@TypeOf(a))) {
        .vector => |info| blk: {
            var result: @TypeOf(a) = undefined;
            for (0..info.len) |i| {
                result[i] = if (a[i] > b[i]) a[i] else b[i];
            }
            break :blk result;
        },
        .array => |info| blk: {
            var result: [info.len]T = undefined;
            for (0..info.len) |i| {
                result[i] = if (a[i] > b[i]) a[i] else b[i];
            }
            break :blk result;
        },
        else => @compileError("Unsupported type in max()"),
    };
}

pub fn clamp(comptime T: type, v: anytype, lower: anytype, upper: anytype) @TypeOf(v) {
    return switch (@typeInfo(@TypeOf(v))) {
        .vector => |info| blk: {
            var result: @TypeOf(v) = undefined;

            const lower_is_vector = @typeInfo(@TypeOf(lower)) == .vector;
            const upper_is_vector = @typeInfo(@TypeOf(upper)) == .vector;

            for (0..info.len) |i| {
                const val = v[i];
                const lo = if (lower_is_vector) lower[i] else lower;
                const hi = if (upper_is_vector) upper[i] else upper;

                if (val < lo) {
                    result[i] = lo;
                } else if (val > hi) {
                    result[i] = hi;
                } else {
                    result[i] = val;
                }
            }
            break :blk result;
        },
        .array => |info| blk: {
            var result: [info.len]T = undefined;

            const lower_is_array = @typeInfo(@TypeOf(lower)) == .array;
            const upper_is_array = @typeInfo(@TypeOf(upper)) == .array;

            for (0..info.len) |i| {
                const val = v[i];
                const lo = if (lower_is_array) lower[i] else lower;
                const hi = if (upper_is_array) upper[i] else upper;

                if (val < lo) {
                    result[i] = lo;
                } else if (val > hi) {
                    result[i] = hi;
                } else {
                    result[i] = val;
                }
            }
            break :blk result;
        },
        else => @compileError("Unsupported type in clamp()"),
    };
}

pub fn distance(comptime T: type, a: anytype, b: anytype) T {
    return length(T, scale(T, a, 1) - scale(T, b, 1));
}

pub fn distanceSquared(comptime T: type, a: anytype, b: anytype) T {
    return dot(T, scale(T, a, 1) - scale(T, b, 1), scale(T, a, 1) - scale(T, b, 1));
}

pub fn reflect(comptime T: type, i: anytype, n: anytype) @TypeOf(i) {
    const two = @as(T, 2);
    return i - scale(T, n, two * dot(T, i, n));
}

pub fn mix(comptime T: type, a: anytype, b: anytype, t: T) @TypeOf(a) {
    return scale(T, a, (1 - t)) + scale(T, b, t);
}

pub fn faceforward(comptime T: type, n: anytype, i: anytype, n_ref: anytype) @TypeOf(n) {
    return if (dot(T, i, n_ref) < 0) n else scale(T, n, -1);
}

pub fn negate(comptime T: type, v: anytype) @TypeOf(v) {
    return scale(T, v, @as(T, -1));
}

test "scale" {
    const s: f32 = 3.0;

    const v2: Vec2(f32) = .{ 1, 2 };
    const v3: Vec3(f32) = .{ 1, 2, 3 };
    const v4: Vec4(f32) = .{ 1, 2, 3, 4 };

    try std.testing.expect(eql(scale(f32, v2, s), Vec2(f32){ 3, 6 }));
    try std.testing.expect(eql(scale(f32, v3, s), Vec3(f32){ 3, 6, 9 }));
    try std.testing.expect(eql(scale(f32, v4, s), Vec4(f32){ 3, 6, 9, 12 }));
}
test "dot" {
    const a2: Vec2(f32) = .{ 1, 2 };
    const b2: Vec2(f32) = .{ 3, 4 };
    const a3: Vec3(f32) = .{ 1, 2, 3 };
    const b3: Vec3(f32) = .{ 4, 5, 6 };
    const a4: Vec4(f32) = .{ 1, 2, 3, 4 };
    const b4: Vec4(f32) = .{ 5, 6, 7, 8 };

    try std.testing.expect(dot(f32, a2, b2) == 11);
    try std.testing.expect(dot(f32, a3, b3) == 32);
    try std.testing.expect(dot(f32, a4, b4) == 70);
}

test "length" {
    const v2: Vec2(f32) = .{ 3, 4 };
    const v3: Vec3(f32) = .{ 1, 2, 2 };

    try std.testing.expect(@abs(length(f32, v2) - 5) < 0.0001);
    try std.testing.expect(@abs(length(f32, v3) - 3) < 0.0001);
}

test "normalize" {
    const v2: Vec2(f32) = .{ 3, 0 };
    const v3: Vec3(f32) = .{ 0, 4, 0 };
    const v4: Vec4(f32) = .{ 0, 0, 0, 5 };

    try std.testing.expect(eql(normalize(f32, v2), Vec2(f32){ 1, 0 }));
    try std.testing.expect(eql(normalize(f32, v3), Vec3(f32){ 0, 1, 0 }));
    try std.testing.expect(eql(normalize(f32, v4), Vec4(f32){ 0, 0, 0, 1 }));
}

test "cross" {
    const a: Vec3(f32) = .{ 1, 0, 0 };
    const b: Vec3(f32) = .{ 0, 1, 0 };
    try std.testing.expect(eql(cross(f32, a, b), Vec3(f32){ 0, 0, 1 }));
}

test "min" {
    const a2: Vec2(f32) = .{ 3, 5 };
    const b2: Vec2(f32) = .{ 2, 6 };
    const a3: Vec3(f32) = .{ 1, 7, 3 };
    const b3: Vec3(f32) = .{ 4, 5, 9 };
    const a4: Vec4(f32) = .{ 8, 2, 3, 7 };
    const b4: Vec4(f32) = .{ 5, 9, 1, 8 };

    try std.testing.expect(eql(min(f32, a2, b2), Vec2(f32){ 2, 5 }));
    try std.testing.expect(eql(min(f32, a3, b3), Vec3(f32){ 1, 5, 3 }));
    try std.testing.expect(eql(min(f32, a4, b4), Vec4(f32){ 5, 2, 1, 7 }));
}

test "max" {
    const a2: Vec2(f32) = .{ 3, 5 };
    const b2: Vec2(f32) = .{ 2, 6 };
    const a3: Vec3(f32) = .{ 1, 7, 3 };
    const b3: Vec3(f32) = .{ 4, 5, 9 };
    const a4: Vec4(f32) = .{ 8, 2, 3, 7 };
    const b4: Vec4(f32) = .{ 5, 9, 1, 8 };

    try std.testing.expect(eql(max(f32, a2, b2), Vec2(f32){ 3, 6 }));
    try std.testing.expect(eql(max(f32, a3, b3), Vec3(f32){ 4, 7, 9 }));
    try std.testing.expect(eql(max(f32, a4, b4), Vec4(f32){ 8, 9, 3, 8 }));
}

test "clamp" {
    const v2: Vec2(f32) = .{ 3, 5 };
    const min_v2: Vec2(f32) = .{ 2, 6 };
    const max_v2: Vec2(f32) = .{ 4, 7 };

    const v3: Vec3(f32) = .{ 1, 7, 3 };
    const min_v3: Vec3(f32) = .{ 0, 5, 2 };
    const max_v3: Vec3(f32) = .{ 4, 8, 5 };

    const v4: Vec4(f32) = .{ 8, 2, 3, 7 };
    const min_v4: Vec4(f32) = .{ 5, 1, 1, 6 };
    const max_v4: Vec4(f32) = .{ 9, 3, 4, 8 };

    try std.testing.expect(eql(clamp(f32, v2, min_v2, max_v2), Vec2(f32){
        3,
        6,
    }));
    try std.testing.expect(eql(clamp(f32, v3, min_v3, max_v3), Vec3(f32){ 1, 7, 3 }));
    try std.testing.expect(eql(clamp(f32, v4, min_v4, max_v4), Vec4(f32){ 8, 2, 3, 7 }));
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
