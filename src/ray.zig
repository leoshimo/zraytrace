const Vec3 = @import("vec.zig").Vec3;

pub const Ray = struct {
    origin: Vec3,
    direction: Vec3,

    pub fn at(self: *const Ray, t: f64) Vec3 {
        return self.origin.add(&self.direction.mult(t));
    }
};

test "Ray.at" {
    const std = @import("std");
    const expectEqual = std.testing.expectEqual;
    {
        const r = Ray{
            .origin = Vec3.new(.{ 0, 0, 1 }),
            .direction = Vec3.new(.{ 1, 1, 0 }),
        };
        const res = r.at(5);
        try expectEqual(res.items, .{ 5, 5, 1 });
    }
    {
        const r = Ray{
            .origin = Vec3.new(.{ 0, 0, 1 }),
            .direction = Vec3.new(.{ 1, 1, -1 }),
        };
        const res = r.at(-5);
        try expectEqual(res.items, .{ -5, -5, 6 });
    }
}
