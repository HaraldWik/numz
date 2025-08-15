const std = @import("std");

pub fn @"2"(T: type) type {
    return @Vector(2, T);
}
pub fn @"3"(T: type) type {
    return @Vector(3, T);
}
pub fn @"4"(T: type) type {
    return @Vector(4, T);
}

fn info(v: type) struct { usize, type } {
    return switch (@typeInfo(v)) {
        .vector => |i| .{ i.len, i.child },
        .array => |i| .{ i.len, i.child },
        else => @compileError("type must be of typeof vector or array"),
    };
}

pub fn xy(v: anytype) @"2"(@TypeOf(v[0])) {
    return .{ v[0], v[1] };
}

pub fn yz(v: anytype) @"2"(@TypeOf(v[0])) {
    const len, _ = info(@TypeOf(v));
    if (len < 2) @compileError("Vector must have z");
    return .{ v[1], v[2] };
}

pub fn xz(v: anytype) @"2"(@TypeOf(v[0])) {
    const len, _ = info(@TypeOf(v));
    if (len < 2) @compileError("Vector must have z");
    return .{ v[0], v[2] };
}

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
    inline for (0..len) |i| {
        if (a[i] != b[i]) return false;
    }
    return true;
}

pub fn scale(v: anytype, s: @TypeOf(v[0])) @TypeOf(v) {
    var result: @TypeOf(v) = undefined;
    const len, _ = info(@TypeOf(v));
    inline for (0..len) |i| {
        result[i] = v[i] * s;
    }
    return result;
}

pub fn dot(a: anytype, b: @TypeOf(a)) @TypeOf(a[0]) {
    const len, const T = info(@TypeOf(a));
    var acc: T = std.mem.zeroes(T);
    for (0..len) |i| acc += a[i] * b[i];
    return acc;
}

pub fn length(v: anytype) @TypeOf(v[0]) {
    return std.math.sqrt(dot(v, v));
}

pub fn normalize(v: anytype) @TypeOf(v) {
    const len = length(v);
    if (len == 0) return v;
    return scale(v, 1 / len);
}

pub fn cross(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    const len, const T = info(@TypeOf(a));
    if (len != 3) @compileError("cross() only supports vec3");
    return [_]T{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    };
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

test "swizzle functions" {
    const v4 = @"4"(f32){ 1.0, 2.0, 3.0, 4.0 };

    try std.testing.expectEqual(@"2"(f32){ 1.0, 2.0 }, xy(v4));
    try std.testing.expectEqual(@"2"(f32){ 2.0, 3.0 }, yz(v4));
    try std.testing.expectEqual(@"2"(f32){ 1.0, 3.0 }, xz(v4));
    try std.testing.expectEqual(@"4"(f32){ 1.0, 2.0, 3.0, 4.0 }, xyzw(v4));
}

test "scale" {
    const s: f32 = 3.0;

    const v2: @"2"(f32) = .{ 1, 2 };
    const v3: @"3"(f32) = .{ 1, 2, 3 };
    const v4: @"4"(f32) = .{ 1, 2, 3, 4 };

    try std.testing.expect(eql(scale(v2, s), @"2"(f32){ 3, 6 }));
    try std.testing.expect(eql(scale(v3, s), @"3"(f32){ 3, 6, 9 }));
    try std.testing.expect(eql(scale(v4, s), @"4"(f32){ 3, 6, 9, 12 }));
}
test "dot" {
    const a2: @"2"(f32) = .{ 1, 2 };
    const b2: @"2"(f32) = .{ 3, 4 };
    const a3: @"3"(f32) = .{ 1, 2, 3 };
    const b3: @"3"(f32) = .{ 4, 5, 6 };
    const a4: @"4"(f32) = .{ 1, 2, 3, 4 };
    const b4: @"4"(f32) = .{ 5, 6, 7, 8 };

    try std.testing.expect(dot(a2, b2) == 11);
    try std.testing.expect(dot(a3, b3) == 32);
    try std.testing.expect(dot(a4, b4) == 70);
}

test "length" {
    const v2: @"2"(f32) = .{ 3, 4 };
    const v3: @"3"(f32) = .{ 1, 2, 2 };

    try std.testing.expect(@abs(length(v2) - 5) < 0.0001);
    try std.testing.expect(@abs(length(v3) - 3) < 0.0001);
}

test "normalize" {
    const v2: @"2"(f32) = .{ 3, 0 };
    const v3: @"3"(f32) = .{ 0, 4, 0 };
    const v4: @"4"(f32) = .{ 0, 0, 0, 5 };

    try std.testing.expect(eql(normalize(v2), @"2"(f32){ 1, 0 }));
    try std.testing.expect(eql(normalize(v3), @"3"(f32){ 0, 1, 0 }));
    try std.testing.expect(eql(normalize(v4), @"4"(f32){ 0, 0, 0, 1 }));
}

test "cross" {
    const a: @"3"(f32) = .{ 1, 0, 0 };
    const b: @"3"(f32) = .{ 0, 1, 0 };
    try std.testing.expect(eql(cross(a, b), @"3"(f32){ 0, 0, 1 }));
}

test "eql" {
    const a2: @"2"(f32) = .{ 1, 2 };
    const b2: @"2"(f32) = .{ 1, 2 };
    const c2: @"2"(f32) = .{ 3, 4 };

    const a3: @"3"(f32) = .{ 1, 2, 3 };
    const b3: @"3"(f32) = .{ 1, 2, 3 };
    const c3: @"3"(f32) = .{ 4, 5, 6 };

    const a4: @"4"(f32) = .{ 1, 2, 3, 4 };
    const b4: @"4"(f32) = .{ 1, 2, 3, 4 };
    const c4: @"4"(f32) = .{ 5, 6, 7, 8 };

    try std.testing.expect(eql(a2, b2));
    try std.testing.expect(!eql(a2, c2));

    try std.testing.expect(eql(a3, b3));
    try std.testing.expect(!eql(a3, c3));

    try std.testing.expect(eql(a4, b4));
    try std.testing.expect(!eql(a4, c4));
}

test "distance" {
    const a: @"2"(f32) = .{ 0, 0 };
    const b: @"2"(f32) = .{ 3, 4 };
    try std.testing.expect(distance(a, b) == 5);
}

test "distanceSquared" {
    const a: @"3"(f32) = .{ 1, 2, 3 };
    const b: @"3"(f32) = .{ 4, 6, 3 };
    try std.testing.expect(distanceSquared(a, b) == 25);
}

test "reflect" {
    const i: @"2"(f32) = .{ 1, -1 };
    const n: @"2"(f32) = .{ 0, 1 };
    try std.testing.expect(eql(reflect(i, n), @"2"(f32){ 1, 1 }));
}

test "mix" {
    const a: @"3"(f32) = .{ 0, 0, 0 };
    const b: @"3"(f32) = .{ 10, 10, 10 };
    try std.testing.expect(eql(mix(a, b, 0.5), @"3"(f32){ 5, 5, 5 }));
}

test "forward" {
    const from: @"3"(f32) = .{ 0, 0, 0 };
    const to: @"3"(f32) = .{ 0, 0, 1 };

    const dir = forward(from, to);
    try std.testing.expect(eql(dir, @"3"(f32){ 0, 0, 1 }));
}

test "negate" {
    const v: @"4"(f32) = .{ 1, -2, 3, -4 };
    const expected: @"4"(f32) = .{ -1, 2, -3, 4 };
    const result = negate(v);

    inline for (0..4) |i| {
        try std.testing.expectApproxEqAbs(result[i], expected[i], 0.00001);
    }
}
