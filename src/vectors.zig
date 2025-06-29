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

pub fn distance(a: anytype, b: anytype) @TypeOf(a[0], b[0]) {
    return length(scale(a, 1) - scale(b, 1));
}

pub fn distanceSquared(a: anytype, b: anytype) @TypeOf(a[0], b[0]) {
    return dot(scale(a, 1) - scale(b, 1), scale(a, 1) - scale(b, 1));
}

pub fn reflect(i: anytype, n: anytype) @TypeOf(i) {
    return i - scale(n, 2 * dot(i, n));
}

pub fn mix(a: anytype, b: anytype, t: @TypeOf(b[0], b[0])) @TypeOf(a, b) {
    return scale(a, (1 - t)) + scale(b, t);
}

pub fn faceforward(n: anytype, i: anytype, n_ref: anytype) @TypeOf(n) {
    return if (dot(i, n_ref) < 0) n else scale(n, -1);
}

pub fn forward(from: anytype, to: anytype) @TypeOf(from) {
    return normalize(to - from);
}

pub fn negate(v: anytype) @TypeOf(v) {
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
