const std = @import("std");

pub fn Rgb(T: type) type {
    const Color = Rgb;
    return extern struct {
        r: T,
        g: T,
        b: T,

        pub const len: usize = 3;
        pub const max: T = switch (@typeInfo(T)) {
            .int => std.math.maxInt(T),
            .float => 1.0,
            else => unreachable,
        };
        pub const min: T = switch (@typeInfo(T)) {
            .int => std.math.minInt(T),
            .float => 0.0,
            else => unreachable,
        };
        pub const half: T = switch (@typeInfo(T)) {
            .int => @divTrunc(std.math.minInt(T), 2),
            .float => 0.5,
            else => unreachable,
        };

        pub const transparent: @This() = std.mem.zeroes(@This());
        pub const white: @This() = .new(max, max, max);
        pub const grey: @This() = .new(half, half, half);
        pub const black: @This() = .new(min, min, min);
        pub const red: @This() = .new(max, min, min);
        pub const green: @This() = .new(min, max, min);
        pub const blue: @This() = .new(min, min, max);
        pub const yellow: @This() = .new(max, max, min);

        pub inline fn new(r: f32, g: f32, b: f32) @This() {
            return .{ .r = r, .g = g, .b = b };
        }

        pub inline fn eql(self: @This(), other: @This()) bool {
            inline for (0..len) |i| if (self.toVec()[i] != other.toVec()[i]) return false;
            return true;
        }

        /// Adds alpha
        pub inline fn alpha(self: @This()) Rgba(T) {
            return .{ .r = self.r, .g = self.g, .b = self.b, .a = Rgba(T).max };
        }

        pub fn from(comptime J: type, color: Color(J)) @This() {
            return switch (@typeInfo(T)) {
                .int => switch (@typeInfo(J)) {
                    .int => .{
                        .r = @intCast(color.r),
                        .g = @intCast(color.g),
                        .b = @intCast(color.b),
                    },
                    .float => .{
                        .r = @intFromFloat(color.r * @as(J, @floatFromInt(std.math.maxInt(T)))),
                        .g = @intFromFloat(color.g * @as(J, @floatFromInt(std.math.maxInt(T)))),
                        .b = @intFromFloat(color.b * @as(J, @floatFromInt(std.math.maxInt(T)))),
                    },
                    else => unreachable,
                },
                .float => switch (@typeInfo(J)) {
                    .int => .{
                        .r = @as(T, @floatFromInt(color.r)) / @as(T, @floatFromInt(std.math.maxInt(J))),
                        .g = @as(T, @floatFromInt(color.g)) / @as(T, @floatFromInt(std.math.maxInt(J))),
                        .b = @as(T, @floatFromInt(color.b)) / @as(T, @floatFromInt(std.math.maxInt(J))),
                    },
                    .float => .{
                        .r = @floatCast(color.r),
                        .g = @floatCast(color.g),
                        .b = @floatCast(color.b),
                    },
                    else => unreachable,
                },
                else => unreachable,
            };
        }

        pub inline fn to(self: @This(), comptime J: type) Color(J) {
            return .from(f32, self);
        }

        pub inline fn fromVec(vec: @Vector(len, T)) @This() {
            return .{ .r = vec[0], .g = vec[1], .b = vec[2] };
        }

        pub inline fn toVec(self: @This()) @Vector(len, T) {
            return .{ self.r, self.g, self.b };
        }

        pub fn fromHex(str: []const u8) !@This() {
            if (str.len != len * 2) return error.InvalidHexLen;
            const r = try std.fmt.parseInt(u8, str[0..2], 16);
            const g = try std.fmt.parseInt(u8, str[2..4], 16);
            const b = try std.fmt.parseInt(u8, str[4..6], 16);

            return .from(u8, .{ .r = r, .g = g, .b = b });
        }

        pub fn toU32(self: @This(), endian: std.builtin.Endian) u32 {
            const color = self.to(u8).alpha();

            return switch (endian) {
                .big => (@as(u32, color.r) << 24) |
                    (@as(u32, color.g) << 16) |
                    (@as(u32, color.b) << 8) |
                    @as(u32, color.a),
                .little => (@as(u32, color.a) << 24) |
                    (@as(u32, color.b) << 16) |
                    (@as(u32, color.g) << 8) |
                    @as(u32, color.r),
            };
        }
    };
}

pub fn Rgba(T: type) type {
    const Color = Rgba;
    return extern struct {
        r: T,
        g: T,
        b: T,
        a: T,

        pub const len: usize = 4;
        pub const max: T = switch (@typeInfo(T)) {
            .int => std.math.maxInt(T),
            .float => 1.0,
            else => unreachable,
        };
        pub const min: T = switch (@typeInfo(T)) {
            .int => std.math.minInt(T),
            .float => 0.0,
            else => unreachable,
        };
        pub const half: T = switch (@typeInfo(T)) {
            .int => @divTrunc(std.math.minInt(T), 2),
            .float => 0.5,
            else => unreachable,
        };

        pub const transparent: @This() = std.mem.zeroes(@This());
        pub const white: @This() = .new(max, max, max, max);
        pub const grey: @This() = .new(half, half, half, max);
        pub const black: @This() = .new(min, min, min, max);
        pub const red: @This() = .new(max, min, min, max);
        pub const green: @This() = .new(min, max, min, max);
        pub const blue: @This() = .new(min, min, max, max);
        pub const yellow: @This() = .new(max, max, min, max);

        pub inline fn new(r: f32, g: f32, b: f32, a: f32) @This() {
            return .{ .r = r, .g = g, .b = b, .a = a };
        }

        pub inline fn eql(self: @This(), other: @This()) bool {
            inline for (0..len) |i| if (self.toVec()[i] != other.toVec()[i]) return false;
            return true;
        }

        /// Removes alpha
        pub inline fn alpha(self: @This()) Rgb(T) {
            return .{ .r = self.r, .g = self.g, .b = self.b };
        }

        pub fn from(comptime J: type, color: Color(J)) @This() {
            return switch (@typeInfo(T)) {
                .int => switch (@typeInfo(J)) {
                    .int => .{
                        .r = @intCast(color.r),
                        .g = @intCast(color.g),
                        .b = @intCast(color.b),
                        .a = @intCast(color.a),
                    },
                    .float => .{
                        .r = @intFromFloat(color.r * @as(J, @floatFromInt(std.math.maxInt(T)))),
                        .g = @intFromFloat(color.g * @as(J, @floatFromInt(std.math.maxInt(T)))),
                        .b = @intFromFloat(color.b * @as(J, @floatFromInt(std.math.maxInt(T)))),
                        .a = @intFromFloat(color.a * @as(J, @floatFromInt(std.math.maxInt(T)))),
                    },
                    else => unreachable,
                },
                .float => switch (@typeInfo(J)) {
                    .int => .{
                        .r = @as(T, @floatFromInt(color.r)) / @as(T, @floatFromInt(std.math.maxInt(J))),
                        .g = @as(T, @floatFromInt(color.g)) / @as(T, @floatFromInt(std.math.maxInt(J))),
                        .b = @as(T, @floatFromInt(color.b)) / @as(T, @floatFromInt(std.math.maxInt(J))),
                        .a = @as(T, @floatFromInt(color.a)) / @as(T, @floatFromInt(std.math.maxInt(J))),
                    },
                    .float => .{
                        .r = @floatCast(color.r),
                        .g = @floatCast(color.g),
                        .b = @floatCast(color.b),
                        .a = @floatCast(color.a),
                    },
                    else => unreachable,
                },
                else => unreachable,
            };
        }

        pub inline fn to(self: @This(), comptime J: type) Color(J) {
            return .from(T, self);
        }

        pub inline fn fromVec(vec: @Vector(len, T)) @This() {
            return .{ .r = vec[0], .g = vec[1], .b = vec[2], .a = vec[3] };
        }

        pub inline fn toVec(self: @This()) @Vector(len, T) {
            return .{ self.r, self.g, self.b, self.a };
        }

        pub fn fromHex(str: []const u8) !@This() {
            if (str.len != len * 2) return error.InvalidHexLen;
            const r = try std.fmt.parseInt(u8, str[0..2], 16);
            const g = try std.fmt.parseInt(u8, str[2..4], 16);
            const b = try std.fmt.parseInt(u8, str[4..6], 16);
            const a = try std.fmt.parseInt(u8, str[6..8], 16);

            return .from(u8, .{ .r = r, .g = g, .b = b, .a = a });
        }

        pub fn toU32(self: @This(), endian: std.builtin.Endian) u32 {
            const color: Color(u8) = self.to(u8);

            return switch (endian) {
                .big => (@as(u32, color.r) << 24) |
                    (@as(u32, color.g) << 16) |
                    (@as(u32, color.b) << 8) |
                    @as(u32, color.a),
                .little => (@as(u32, color.a) << 24) |
                    (@as(u32, color.b) << 16) |
                    (@as(u32, color.g) << 8) |
                    @as(u32, color.r),
            };
        }
    };
}

test "eql" {
    const c1: Rgba(f32) = .red;
    const c2: Rgba(f32) = .blue;

    try std.testing.expect(c1.eql(c1));
    try std.testing.expect(!c1.eql(c2));
}

test "alpha" {
    const rgba: Rgba(f32) = .new(1.0, 0.0, 1.0, 1.0);
    const rgb: Rgb(f32) = .new(1.0, 0.0, 1.0);

    try std.testing.expect(rgba.alpha().eql(rgb));
    try std.testing.expect(rgba.eql(rgb.alpha()));
}

test "from" {
    const rgba_u8: Rgba(u8) = .green;
    const rgb_u8: Rgba(u8) = .green;

    const rgba_f32: Rgba(f32) = .green;
    const rgb_f32: Rgba(f32) = .green;

    try std.testing.expect(rgb_u8.eql(.from(u8, rgb_u8)));
    try std.testing.expect(rgba_f32.eql(.from(u8, rgba_u8)));
    try std.testing.expect(rgb_f32.eql(.from(u8, rgb_u8)));
}

test "to" {
    const rgba_f32: Rgba(f32) = .grey;
    const rgb_f32: Rgba(f32) = .grey;

    const rgba_u8: Rgba(u8) = .grey;
    const rgb_u8: Rgba(u8) = .grey;

    try std.testing.expect(@TypeOf(rgba_f32.to(u8)) == @TypeOf(rgba_u8));
    try std.testing.expect(@TypeOf(rgb_f32.to(u8)) == @TypeOf(rgb_u8));

    try std.testing.expect(@TypeOf(rgba_u8.to(f32)) == @TypeOf(rgba_f32));
    try std.testing.expect(@TypeOf(rgb_u8.to(f32)) == @TypeOf(rgb_f32));
}

test "fromHex" {
    const rgba: Rgba(f32) = try .fromHex("FF0000FF");
    const rgb: Rgb(f32) = try .fromHex("FF0000");

    try std.testing.expect(rgba.eql(.red));
    try std.testing.expect(rgb.eql(.red));
}

test "toU32" {
    {
        const rgba_f32: Rgba(f32) = .white;
        const rgb_f32: Rgb(f32) = .white;

        try std.testing.expect(rgba_f32.toU32(.native) == rgb_f32.toU32(.native));
    }
    {
        const rgba_f32: Rgba(f32) = .red;
        const rgb_f32: Rgb(f32) = .red;

        try std.testing.expect(rgba_f32.toU32(.native) == rgb_f32.toU32(.native));
    }
}
