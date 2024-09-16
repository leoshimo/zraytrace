const std = @import("std");

// TODO: Try Zig's @Vector
// TODO: Perf: Parameter Reference Optimization - Experiment passing by value
// TODO: Perf: Compare inline fn
pub fn Vec(comptime n: comptime_int, comptime T: type) type {
    return struct {
        items: [n]T,
        const Self = @This();

        pub fn zero() Self {
            return .{
                .items = [_]T{0} ** n,
            };
        }

        pub fn new(items: [n]T) Self {
            return .{ .items = items };
        }

        pub fn parse(str: []const u8) !Self {
            var tokens = std.mem.tokenizeAny(u8, str, " ");
            var v = Vec3{ .items = undefined };
            inline for (0..n) |i| {
                if (tokens.next()) |t| {
                    v.items[i] = try std.fmt.parseFloat(T, t);
                } else {
                    return error.ParseError;
                }
            }
            if (tokens.next() != null) {
                return error.ParseError;
            }
            return v;
        }

        pub fn x(self: *const Self) T {
            return self.items[0];
        }

        pub fn y(self: *const Self) T {
            return self.items[1];
        }

        pub fn z(self: *const Self) T {
            return self.items[2];
        }

        pub fn add(lhs: *const Self, rhs: *const Self) Self {
            var res = lhs.*;
            inline for (0..n) |i| {
                res.items[i] += rhs.items[i];
            }
            return res;
        }

        pub fn sub(lhs: *const Self, rhs: *const Self) Self {
            var res = lhs.*;
            inline for (0..n) |i| {
                res.items[i] -= rhs.items[i];
            }
            return res;
        }

        pub fn mult(lhs: *const Self, s: T) Self {
            var res = lhs.*;
            inline for (0..n) |i| {
                res.items[i] *= s;
            }
            return res;
        }

        pub fn div(lhs: *const Self, s: T) Self {
            var res = lhs.*;
            inline for (0..n) |i| {
                res.items[i] /= s;
            }
            return res;
        }

        pub fn dot(lhs: *const Self, rhs: *const Self) T {
            var result: T = 0;
            inline for (0..n) |i| {
                result += lhs.items[i] * rhs.items[i];
            }
            return result;
        }

        pub fn cross(lhs: *const Self, rhs: *const Self) Self {
            return .{ .items = .{
                lhs.items[1] * rhs.items[2] - lhs.items[2] * rhs.items[1],
                lhs.items[2] * rhs.items[0] - lhs.items[0] * rhs.items[2],
                lhs.items[0] * rhs.items[1] - lhs.items[1] * rhs.items[0],
            } };
        }

        pub fn adding(self: *Self, v: *const Self) void {
            inline for (0..n) |i| {
                self.items[i] += v.items[i];
            }
        }

        pub fn subtracting(self: *Self, v: *const Self) void {
            inline for (0..n) |i| {
                self.items[i] -= v.items[i];
            }
        }

        pub fn multiplying(self: *Self, s: T) void {
            inline for (&self.items) |*elem| {
                elem.* *= s;
            }
        }

        pub fn dividing(self: *Self, s: T) void {
            inline for (&self.items) |*elem| {
                elem.* /= s;
            }
        }

        pub fn length(self: *const Self) T {
            return @sqrt(self.length_squared());
        }

        pub fn length_squared(self: *const Self) T {
            var result: T = 0;
            inline for (self.items) |value| {
                result += std.math.pow(f64, value, 2);
            }
            return result;
        }

        pub fn unit(self: *const Self) Self {
            const scale = self.length();
            return self.div(scale);
        }
    };
}

pub const Vec3 = Vec(3, f64);

test "Vec3 basic" {
    const expect = std.testing.expect;
    const expectEqual = std.testing.expectEqual;
    const eql = std.mem.eql;

    {
        const zero = Vec3.zero();
        try expect(eql(f64, &.{ 0, 0, 0 }, &zero.items));
    }
    {
        const ones = Vec3.new(.{ 1, 1, 1 });
        try expect(eql(f64, &.{ 1, 1, 1 }, &ones.items));
    }
    {
        const vec = Vec3.new(.{ 1, 2, 3 });
        try expectEqual(1, vec.x());
        try expectEqual(2, vec.y());
        try expectEqual(3, vec.z());
    }
    {
        const rhs = Vec3.new(.{ 1, 2, 3 });
        const lhs = Vec3.new(.{ 1, 2, 3 });
        const res = rhs.add(&lhs);
        try expect(eql(f64, &res.items, &.{ 2, 4, 6 }));
    }
    {
        const rhs = Vec3.new(.{ 1, 2, 3 });
        const lhs = Vec3.new(.{ 1, 1, 1 });
        const res = rhs.sub(&lhs);
        try expect(eql(f64, &res.items, &.{ 0, 1, 2 }));
    }
    {
        const v = Vec3.new(.{ 1, 2, 3 });
        const res = v.mult(11);
        try expect(eql(f64, &res.items, &.{ 11, 22, 33 }));
    }
    {
        const v = Vec3.new(.{ 1, 2, 3 });
        const res = v.div(2);
        try expect(eql(f64, &res.items, &.{ 0.5, 1, 1.5 }));
    }
    {
        var v = Vec3.new(.{ 1, 2, 3 });
        v.adding(&Vec3.new(.{ 1, 1, 1 }));
        try expect(eql(f64, &v.items, &.{ 2, 3, 4 }));
    }
    {
        var v = Vec3.new(.{ 1, 2, 3 });
        v.subtracting(&Vec3.new(.{ 1, 1, 1 }));
        try expect(eql(f64, &v.items, &.{ 0, 1, 2 }));
    }
    {
        var v = Vec3.new(.{ 1, 2, 3 });
        v.multiplying(11);
        try expect(eql(f64, &v.items, &.{ 11, 22, 33 }));
    }
    {
        var v = Vec3.new(.{ 1, 2, 3 });
        v.dividing(2);
        try expect(eql(f64, &v.items, &.{ 0.5, 1, 1.5 }));
    }
    {
        var v = Vec3.new(.{ 1, 0, 0 });
        try expectEqual(1, v.length());
    }
    {
        var v = Vec3.new(.{ 1, 2, 3 });
        try expectEqual(3.7416573867739413, v.length());
    }
}

test "Vec3.parse" {
    const expect = std.testing.expect;
    const expectError = std.testing.expectError;
    const eql = std.mem.eql;

    {
        const v = try Vec3.parse("1 2 3");
        try expect(eql(f64, &v.items, &.{ 1, 2, 3 }));
    }
    {
        const v = Vec3.parse("1 2");
        try expectError(error.ParseError, v);
    }
    {
        const v = Vec3.parse("1 2 3 4");
        try expectError(error.ParseError, v);
    }
}

test "Vec3.dot" {
    const expectEqual = std.testing.expectEqual;
    {
        const lhs = Vec3.new(.{ 1, 3, -5 });
        const rhs = Vec3.new(.{ 4, -2, -1 });
        try expectEqual(3, lhs.dot(&rhs));
    }
    {
        const v = Vec3.new(.{ 1, 3, -5 });
        try expectEqual(35, v.dot(&v));
    }
    {
        const lhs = Vec3.new(.{ 1, 0, 0 });
        const rhs = Vec3.new(.{ 0, 1, 0 });
        try expectEqual(0, lhs.dot(&rhs));
    }
}

test "Vec3.unit" {
    const expect = std.testing.expect;
    const expectEqual = std.testing.expectEqual;
    const eql = std.mem.eql;
    {
        const v = Vec3.new(.{ 0, 1, 0 }).unit();
        try expect(eql(f64, &.{ 0, 1, 0 }, &v.items));
        try expectEqual(1, v.length());
    }
    {
        const v = Vec3.new(.{ 3, 4, 0 }).unit();
        try expect(eql(f64, &.{ 3.0 / 5.0, 4.0 / 5.0, 0 }, &v.items));
        try expectEqual(1, v.length());
    }
}

test "Vec3.cross" {
    const expect = std.testing.expect;
    const eql = std.mem.eql;
    {
        const v = Vec3.new(.{ 1, 0, 0 });
        const w = Vec3.new(.{ 0, 1, 0 });
        const result = v.cross(&w);
        try expect(eql(f64, &.{ 0, 0, 1 }, &result.items));
    }
    {
        const v = Vec3.new(.{ 3, -3, 1 });
        const w = Vec3.new(.{ 4, 9, 2 });
        const result = v.cross(&w);
        try expect(eql(f64, &.{ -15, -2, 39 }, &result.items));
    }
}
