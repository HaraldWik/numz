const std = @import("std");
const math = @import("std").math;

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
            return .new(v[0], v[1]);
        }

        pub inline fn scale(v: Self, s: T) Self {
            return .new(v[0] * s, v[1] * s);
        }

        // zig fmt: off
        pub inline fn xyz(v: Self) Vec3(T) { return .new(v.d[0], v.d[1], 0); }
        pub inline fn xyzw(v: Self) Vec4(T) { return .new(v.d[1], v.d[2], 0, 0); }
        // zig fmt: on

        pub inline fn dot(self: Self, other: Self) T {
            return (self.d * other.d)[0] + (self.d * other.d)[1];
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
            return .new(v[0], v[1], v[2]);
        }

        pub inline fn scale(v: Self, s: T) Self {
            return .new(v[0] * s, v[1] * s, v[2] * s);
        }

        // zig fmt: off
        pub inline fn xy(v: Self) Vec2(T) { return .new(v.d[0], v.d[1]); }
        pub inline fn yz(v: Self) Vec2(T) { return .new(v.d[1], v.d[2]); }
        pub inline fn xz(v: Self) Vec2(T) { return .new(v.d[0], v.d[2]); }

        pub inline fn xyzw(v: Self) Vec4(T) { return .new(v.d[0], v.d[2], 0, 0); }
        // zig fmt: on

        pub inline fn dot(self: Self, other: Self) T {
            return (self.d * other.d)[0] + (self.d * other.d)[1];
        }

        pub inline fn cross(self: Self, other: Self) Self {
            return .new(
                self.d[1] * other.d[2] - self.d[2] * other.d[1],
                self.d[2] * other.d[0] - self.d[0] * other.d[2],
                self.d[0] * other.d[1] - self.d[1] * other.d[0],
            );
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
            return .new(v[0], v[1], v[2], v[
                3
            ]);
        }

        pub inline fn scale(v: Self, s: T) Self {
            return .new(v[0] * s, v[1] * s, v[2] * s, v[
                3
            ] * s);
        }

        // zig fmt: off
        pub inline fn xy(v: Self) Vec2(T) { return .new(v.d[0], v.d[1]); }
        pub inline fn yz(v: Self) Vec2(T) { return .new(v.d[1], v.d[2]); }
        pub inline fn xz(v: Self) Vec2(T) { return .new(v.d[0], v.d[2]); }
        pub inline fn xw(v: Self) Vec2(T) { return .new(v.d[0], v.d[3
        ]); }
        pub inline fn yw(v: Self) Vec2(T) { return .new(v.d[1], v.d[3
        ]); }
        pub inline fn zw(v: Self) Vec2(T) { return .new(v.d[2], v.d[3
        ]); }

        pub inline fn xyz(v: Self) Vec3(T) { return .new(v.d[0], v.d[1], v.d[2]); }
        pub inline fn xzw(v: Self) Vec3(T) { return .new(v.d[0], v.d[2], v.d[3
        ]); }
        pub inline fn yzw(v: Self) Vec3(T) { return .new(v.d[1], v.d[2], v.d[3
        ]); }
        pub inline fn xyw(v: Self) Vec3(T) { return .new(v.d[0], v.d[1], v.d[3
        ]); }
        // zig fmt: on

        pub inline fn dot(self: Self, other: Self) T {
            return (self.d * other.d)[0] + (self.d * other.d)[1] + (self.d * other.d)[2] + (self.d * other.d)[
                3
            ];
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
