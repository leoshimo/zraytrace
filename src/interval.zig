const std = @import("std");

const infinity = std.math.inf(f64);

pub const Interval = struct {
    const Self = @This();
    const Value = f64;

    min: Value,
    max: Value,

    pub fn contains(self: Self, value: Value) bool {
        return self.min <= value and value <= self.max;
    }

    pub fn size(self: Self) Value {
        return @max(self.max - self.min, 0);
    }

    pub const empty: Self = .{
        .min = infinity,
        .max = -infinity,
    };

    pub const inf: Self = .{
        .min = -infinity,
        .max = infinity,
    };

    pub const pos: Self = .{
        .min = 0,
        .max = infinity,
    };
};

test "Interval" {
    const expect = std.testing.expect;

    {
        const i = Interval{
            .min = 0,
            .max = 10,
        };

        try expect(i.size() == 10);

        try expect(i.contains(0));
        try expect(i.contains(5));
        try expect(i.contains(10));
        try expect(!i.contains(-1));
        try expect(!i.contains(11));
        try expect(!i.contains(infinity));
        try expect(!i.contains(-infinity));
    }
    {
        const i = Interval.inf;

        try expect(i.size() == infinity);

        try expect(i.contains(0));
        try expect(i.contains(5));
        try expect(i.contains(10));
        try expect(i.contains(-1));
        try expect(i.contains(11));
        try expect(i.contains(infinity));
        try expect(i.contains(-infinity));
    }
    {
        const i = Interval.empty;

        try expect(i.size() == 0);

        try expect(!i.contains(0));
        try expect(!i.contains(5));
        try expect(!i.contains(10));
        try expect(!i.contains(-1));
        try expect(!i.contains(11));
        try expect(!i.contains(infinity));
        try expect(!i.contains(-infinity));
    }
    {
        const i = Interval.pos;

        try expect(i.size() == infinity);

        try expect(i.contains(0));
        try expect(i.contains(5));
        try expect(i.contains(10));
        try expect(!i.contains(-1));
        try expect(!i.contains(-10));
        try expect(i.contains(infinity));
        try expect(!i.contains(-infinity));
    }
}
