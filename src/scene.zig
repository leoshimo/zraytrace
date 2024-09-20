//
// scene.zig - Manages scene geometry
//

const std = @import("std");
const Allocator = std.mem.Allocator;

const Vec3 = @import("vec.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const geometry = @import("geometry.zig");
const Geometry = geometry.Geometry;
const HitRecord = geometry.HitRecord;
const Interval = @import("interval.zig").Interval;

pub const Scene = struct {
    const Self = @This();
    const ArrayList = std.ArrayList(Geometry);

    items: ArrayList,

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .items = ArrayList.init(allocator),
        };
    }

    pub fn deinit(self: Self) void {
        self.items.deinit();
    }

    pub fn clear(self: *Self) void {
        self.items.clearAndFree();
    }

    pub fn add(self: *Self, geo: Geometry) !void {
        try self.items.append(geo);
    }

    pub fn hit(self: *const Self, ray_t: *const Interval, ray: *const Ray) ?HitRecord {
        var interval = ray_t.*;
        var record: ?HitRecord = null;
        // TODO: Capture by ptr or val? (*it or it)
        for (self.items.items) |it| {
            const r_opt = it.hit(&interval, ray);
            if (r_opt) |r| {
                record = r;
                interval.max = r.t;
            }
        }
        return record;
    }
};

test "Scene.init" {
    const expectEqual = std.testing.expectEqual;
    const scene = Scene.init(std.testing.allocator);
    defer {
        scene.deinit();
    }
    const ray = Ray{
        .origin = Vec3.zero(),
        .direction = Vec3{ .items = .{ 0, 0, -1 } },
    };
    try expectEqual(null, scene.hit(&Interval.inf, &ray));
}

test "Scene.add / Scene.hit" {
    const expectEqual = std.testing.expectEqual;

    var scene = Scene.init(std.testing.allocator);
    defer {
        scene.deinit();
    }

    // Sphere at -5
    try scene.add(Geometry{ .sphere = .{
        .center = Vec3{ .items = .{ 0, 0, -5 } },
        .radius = 1,
    } });

    // Sphere at -10
    try scene.add(Geometry{ .sphere = .{
        .center = Vec3{ .items = .{ 0, 0, -10 } },
        .radius = 1,
    } });

    // Big sphere at -100
    try scene.add(Geometry{ .sphere = .{
        .center = Vec3{ .items = .{ 0, 0, -100 } },
        .radius = 50,
    } });

    {
        // Should hit sphere at -5
        const r = Ray{
            .origin = Vec3.zero(),
            .direction = Vec3{ .items = .{ 0, 0, -1 } },
        };
        const record = scene.hit(&Interval.pos, &r);
        const expected = HitRecord{
            .hit_point = Vec3{ .items = .{ 0, 0, -4 } },
            .t = 4,
            .normal = Vec3{ .items = .{ 0, 0, 1 } },
            .front_face = true,
        };
        try expectEqual(expected, record);
    }

    {
        // Should hit sphere at -10
        const inf = std.math.inf(f64);
        const r = Ray{
            .origin = Vec3.zero(),
            .direction = Vec3{ .items = .{ 0, 0, -1 } },
        };
        const record = scene.hit(&Interval{ .min = 7, .max = inf }, &r);
        const expected = HitRecord{
            .hit_point = Vec3{ .items = .{ 0, 0, -9 } },
            .t = 9,
            .normal = Vec3{ .items = .{ 0, 0, 1 } },
            .front_face = true,
        };
        try expectEqual(expected, record);
    }

    {
        // Should hit sphere at -10 (offset camera)
        const r = Ray{
            .origin = Vec3{ .items = .{ 0, 0, -7 } },
            .direction = Vec3{ .items = .{ 0, 0, -1 } },
        };
        const record = scene.hit(&Interval.pos, &r);
        const expected = HitRecord{
            .hit_point = Vec3{ .items = .{ 0, 0, -9 } },
            .t = 2,
            .normal = Vec3{ .items = .{ 0, 0, 1 } },
            .front_face = true,
        };
        try expectEqual(expected, record);
    }

    {
        // Should top of sphere at -1
        const r = Ray{
            .origin = Vec3{ .items = .{ 0, 1, 0 } },
            .direction = Vec3{ .items = .{ 0, 0, -1 } },
        };
        const record = scene.hit(&Interval.pos, &r);
        const expected = HitRecord{
            .hit_point = Vec3{ .items = .{ 0, 1, -5 } },
            .t = 5,
            .normal = Vec3{ .items = .{ 0, 1, 0 } },
            .front_face = true,
        };
        try expectEqual(expected, record);
    }

    {
        // Hit sphere at -100 via offset ray origin
        const r = Ray{
            .origin = Vec3{ .items = .{ 0, 10, 0 } },
            .direction = Vec3{ .items = .{ 0, 0, -1 } },
        };
        const record = scene.hit(&Interval.pos, &r);

        // Hit sphere at t ~= 50
        try expectEqual(-5.101020514433644e1, record.?.hit_point.z());
    }
}

test "Scene.add / Scene.clear" {
    const expectEqual = std.testing.expectEqual;

    var scene = Scene.init(std.testing.allocator);
    defer {
        scene.deinit();
    }

    // Sphere at -5
    try scene.add(Geometry{ .sphere = .{
        .center = Vec3{ .items = .{ 0, 0, -5 } },
        .radius = 1,
    } });

    // Sphere at -10
    try scene.add(Geometry{ .sphere = .{
        .center = Vec3{ .items = .{ 0, 0, -10 } },
        .radius = 1,
    } });

    // Big sphere at -100
    try scene.add(Geometry{ .sphere = .{
        .center = Vec3{ .items = .{ 0, 0, -100 } },
        .radius = 50,
    } });

    // No rays should intersect anything after clear
    scene.clear();
    const r = Ray{
        .origin = Vec3.zero(),
        .direction = Vec3{ .items = .{ 0, 0, -1 } },
    };
    const record = scene.hit(&Interval.pos, &r);
    try expectEqual(null, record);
}
