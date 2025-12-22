const std = @import("std");

fn info(v: type) struct { usize, type } {
    return switch (@typeInfo(v)) {
        .vector => |i| .{ i.len, i.child },
        .array => |i| .{ i.len, i.child },
        else => |T| @compileError("must be of type of vector or array and not type of '" ++ @tagName(T) ++ "'"),
    };
}

// pub fn xy(v: anytype) @"2"(@TypeOf(v[0])) {
//     return .{ v[0], v[1] };
// }

// pub fn yz(v: anytype) @"2"(@TypeOf(v[0])) {
//     const len, _ = info(@TypeOf(v));
//     if (len < 2) @compileError("Vector must have z");
//     return .{ v[1], v[2] };
// }

// pub fn xz(v: anytype) @"2"(@TypeOf(v[0])) {
//     const len, _ = info(@TypeOf(v));
//     if (len < 2) @compileError("Vector must have z");
//     return .{ v[0], v[2] };
// }

pub fn xyz(v: anytype) @TypeOf(v) {
    const len, _ = info(@TypeOf(v));

    return switch (len) {
        2 => .{ v[0], v[1], 0 },
        3 => v,
        4 => .{ v[0], v[1], v[2] },
        else => unreachable,
    };
}

pub fn xyzw(v: anytype) @TypeOf(v) {
    const len, _ = info(@TypeOf(v));

    return switch (len) {
        2 => .{ v[0], v[1], 0, 0 },
        3 => .{ v[0], v[1], v[2], 0 },
        4 => v,
        else => unreachable,
    };
}

pub fn eql(a: anytype, b: @TypeOf(a)) bool {
    const len, _ = info(@TypeOf(a));
    inline for (0..len) |i| if (a[i] != b[i]) return false;
    return true;
}

pub fn scale(v: anytype, s: @TypeOf(v[0])) @TypeOf(v) {
    var ret: @TypeOf(v) = undefined;
    const len, _ = info(@TypeOf(v));
    inline for (0..len) |i| ret[i] = v[i] * s;
    return ret;
}

pub fn dot(a: anytype, b: @TypeOf(a)) @TypeOf(a[0]) {
    const len, const T = info(@TypeOf(a));
    var acc: T = std.mem.zeroes(T);
    inline for (0..len) |i| acc += a[i] * b[i];
    return acc;
}

pub fn cross(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    const len, _ = info(@TypeOf(a));
    if (len != 3) @compileError("cross() only supports vec3");
    return .{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
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

pub inline fn negate(v: anytype) @TypeOf(v) {
    var ret: @TypeOf(v) = undefined;
    const len, _ = info(@TypeOf(v));
    inline for (0..len) |i| ret[i] = -v[i];
    return ret;
}

pub inline fn distance(a: anytype, b: @TypeOf(a)) @TypeOf(a[0], b[0]) {
    return length(scale(a, 1) - scale(b, 1));
}

pub inline fn distanceSquared(a: anytype, b: @TypeOf(a)) @TypeOf(a[0], b[0]) {
    return dot(scale(a, 1) - scale(b, 1), scale(a, 1) - scale(b, 1));
}

pub inline fn reflect(i: anytype, n: anytype) @TypeOf(i) {
    return i - scale(n, 2 * dot(i, n));
}

pub inline fn mix(a: anytype, b: anytype, t: @TypeOf(b[0], b[0])) @TypeOf(a, b) {
    return scale(a, (1 - t)) + scale(b, t);
}

pub inline fn forward(from: anytype, to: anytype) @TypeOf(from) {
    return normalize(to - from);
}

pub fn forwardFromEuler(rotation: anytype) @TypeOf(rotation) {
    const len, _ = info(rotation);
    if (len != 3) @compileError("forwardFromEuler() only supports vec3");

    const pitch = std.math.degreesToRadians(rotation[0]); // rotation around X
    const yaw = std.math.degreesToRadians(rotation[1]); // rotation around Y

    return .{
        std.math.sin(yaw) * std.math.cos(pitch), // X
        -std.math.sin(pitch), // Y
        -std.math.cos(yaw) * std.math.cos(pitch), // Z
    };
}

// test "swizzle functions" {
//     const v4: @Vector(4, f32) = .{ 1.0, 2.0, 3.0, 4.0 };

//     try std.testing.expectEqual(@Vector(2, f32){ 1.0, 2.0 }, xy(v4));
//     try std.testing.expectEqual(@Vector(2, f32){ 2.0, 3.0 }, yz(v4));
//     try std.testing.expectEqual(@Vector(2, f32){ 1.0, 3.0 }, xz(v4));
//     try std.testing.expectEqual(@Vector(4, f32){ 1.0, 2.0, 3.0, 4.0 }, xyzw(v4));
// }

test "scale" {
    const s: f32 = 3.0;

    const v2: @Vector(2, f32) = .{ 1, 2 };
    const v3: @Vector(3, f32) = .{ 1, 2, 3 };
    const v4: @Vector(4, f32) = .{ 1, 2, 3, 4 };

    try std.testing.expect(eql(scale(v2, s), .{ 3, 6 }));
    try std.testing.expect(eql(scale(v3, s), .{ 3, 6, 9 }));
    try std.testing.expect(eql(scale(v4, s), .{ 3, 6, 9, 12 }));
}

test "dot" {
    const a2: @Vector(2, f32) = .{ 1, 2 };
    const b2: @Vector(2, f32) = .{ 3, 4 };
    const a3: @Vector(3, f32) = .{ 1, 2, 3 };
    const b3: @Vector(3, f32) = .{ 4, 5, 6 };
    const a4: @Vector(4, f32) = .{ 1, 2, 3, 4 };
    const b4: @Vector(4, f32) = .{ 5, 6, 7, 8 };

    try std.testing.expect(dot(a2, b2) == 11);
    try std.testing.expect(dot(a3, b3) == 32);
    try std.testing.expect(dot(a4, b4) == 70);
}

test "length" {
    const v2: @Vector(2, f32) = .{ 3, 4 };
    const v3: @Vector(3, f32) = .{ 1, 2, 2 };

    try std.testing.expect(@abs(length(v2) - 5) < 0.0001);
    try std.testing.expect(@abs(length(v3) - 3) < 0.0001);
}

test "normalize" {
    const v2: @Vector(2, f32) = .{ 3, 0 };
    const v3: @Vector(3, f32) = .{ 0, 4, 0 };
    const v4: @Vector(4, f32) = .{ 0, 0, 0, 5 };

    try std.testing.expect(eql(normalize(v2), .{ 1, 0 }));
    try std.testing.expect(eql(normalize(v3), .{ 0, 1, 0 }));
    try std.testing.expect(eql(normalize(v4), .{ 0, 0, 0, 1 }));
}

test "cross" {
    const a: @Vector(3, f32) = .{ 1, 0, 0 };
    const b: @Vector(3, f32) = .{ 0, 1, 0 };
    try std.testing.expect(eql(cross(a, b), .{ 0, 0, 1 }));
}

test "eql" {
    const a2: @Vector(2, f32) = .{ 1, 2 };
    const b2: @Vector(2, f32) = .{ 1, 2 };
    const c2: @Vector(2, f32) = .{ 3, 4 };

    const a3: @Vector(3, f32) = .{ 1, 2, 3 };
    const b3: @Vector(3, f32) = .{ 1, 2, 3 };
    const c3: @Vector(3, f32) = .{ 4, 5, 6 };

    const a4: @Vector(4, f32) = .{ 1, 2, 3, 4 };
    const b4: @Vector(4, f32) = .{ 1, 2, 3, 4 };
    const c4: @Vector(4, f32) = .{ 5, 6, 7, 8 };

    try std.testing.expect(eql(a2, b2));
    try std.testing.expect(!eql(a2, c2));

    try std.testing.expect(eql(a3, b3));
    try std.testing.expect(!eql(a3, c3));

    try std.testing.expect(eql(a4, b4));
    try std.testing.expect(!eql(a4, c4));
}

test "distance" {
    const a: @Vector(2, f32) = .{ 0, 0 };
    const b: @Vector(2, f32) = .{ 3, 4 };
    try std.testing.expect(distance(a, b) == 5);
}

test "distanceSquared" {
    const a: @Vector(3, f32) = .{ 1, 2, 3 };
    const b: @Vector(3, f32) = .{ 4, 6, 3 };
    try std.testing.expect(distanceSquared(a, b) == 25);
}

test "reflect" {
    const i: @Vector(2, f32) = .{ 1, -1 };
    const n: @Vector(2, f32) = .{ 0, 1 };
    try std.testing.expect(eql(reflect(i, n), .{ 1, 1 }));
}

test "mix" {
    const a: @Vector(3, f32) = .{ 0, 0, 0 };
    const b: @Vector(3, f32) = .{ 10, 10, 10 };
    try std.testing.expect(eql(mix(a, b, 0.5), .{ 5, 5, 5 }));
}

test "negate" {
    const v: @Vector(4, f32) = .{ 1, -2, 3, -4 };
    const expected: @Vector(4, f32) = .{ -1, 2, -3, 4 };
    const result = negate(v);

    inline for (0..4) |i| try std.testing.expectApproxEqAbs(result[i], expected[i], 0.00001);
}

test "forward" {
    const from: @Vector(3, f32) = .{ 0, 0, 0 };
    const to: @Vector(3, f32) = .{ 0, 0, 1 };

    const dir = forward(from, to);
    try std.testing.expect(eql(dir, .{ 0, 0, 1 }));
}
