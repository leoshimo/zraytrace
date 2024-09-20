//
// geometry.zig - Scene Geometry
//

const Vec3 = @import("vec.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const Interval = @import("interval.zig").Interval;

pub const HitRecord = struct {
    hit_point: Vec3,
    t: f64,
    normal: Vec3,
    front_face: bool,
};

pub const Geometry = union(enum) {
    sphere: Sphere,

    pub fn hit(self: *const Geometry, ray_t: *const Interval, ray: *const Ray) ?HitRecord {
        switch (self.*) {
            .sphere => |s| return s.hit(ray_t, ray),
        }
    }
};

pub const Sphere = struct {
    center: Vec3,
    radius: f64,

    pub fn hit(self: *const Sphere, ray_t: *const Interval, ray: *const Ray) ?HitRecord {
        const radius = self.radius;

        const oc = self.center.sub(&ray.origin);
        const a = ray.direction.length_squared();
        const h = ray.direction.dot(&oc);
        const c = oc.length_squared() - radius * radius;
        const discriminant = h * h - a * c;
        if (discriminant < 0) {
            return null;
        }

        const t1 = (h - @sqrt(discriminant)) / a;
        const t2 = (h + @sqrt(discriminant)) / a;
        const t_opt: ?f64 = if (ray_t.contains(t1))
            t1
        else if (ray_t.contains(t2))
            t2
        else
            null;

        if (t_opt) |t| {
            const hit_point = ray.at(t);
            var normal = hit_point.sub(&self.center).div(radius);
            var front_face = true;
            if (normal.dot(&ray.direction) > 0) {
                normal.multiplying(-1);
                front_face = false;
            }
            return .{
                .hit_point = hit_point,
                .t = t,
                .normal = normal,
                .front_face = front_face,
            };
        } else {
            return null;
        }
    }
};

test "Sphere.hit" {
    const std = @import("std");
    const expectEqual = std.testing.expectEqual;

    // Sphere @ z = -50 with radius 10
    const sphere = Sphere{ .center = Vec3{ .items = .{ 0, 0, -50 } }, .radius = 10 };

    {
        // Intersecting ray
        const ray = Ray{
            .origin = Vec3.zero(),
            .direction = Vec3{ .items = .{ 0, 0, -1 } },
        };
        const record = sphere.hit(&Interval.pos, &ray);
        const expected = HitRecord{
            .hit_point = Vec3{ .items = .{ 0, 0, -40 } },
            .t = 40,
            .normal = Vec3{ .items = .{ 0, 0, 1 } },
            .front_face = true,
        };
        try expectEqual(expected, record);
    }

    {
        // Non-intersecting ray
        const ray = Ray{
            .origin = Vec3.zero(),
            .direction = Vec3{ .items = .{ 0, -50, -1 } },
        };
        const record = sphere.hit(&Interval.pos, &ray);
        try expectEqual(null, record);
    }

    {
        // Ray starting from inside sphere
        const ray = Ray{
            .origin = sphere.center,
            .direction = Vec3{ .items = .{ 0, 0, -1 } },
        };
        const record = sphere.hit(&Interval.pos, &ray);
        const expected = HitRecord{
            .hit_point = Vec3{ .items = .{ 0, 0, -60 } },
            .t = 10,
            .normal = Vec3{ .items = .{ 0, 0, 1 } },
            .front_face = false,
        };
        try expectEqual(expected, record);
    }

    {
        // Ray intersecting top of sphere
        const ray = Ray{
            .origin = Vec3{ .items = .{ 0, 10, 0 } },
            .direction = Vec3{ .items = .{ 0, 0, -1 } },
        };
        const record = sphere.hit(&Interval.pos, &ray);
        const expected = HitRecord{
            .hit_point = Vec3{ .items = .{ 0, 10, -50 } },
            .t = 50,
            .normal = Vec3{ .items = .{ 0, 1, 0 } },
            .front_face = true,
        };
        try expectEqual(expected, record);
    }

    {
        // Ray passing top of sphere
        const ray = Ray{
            .origin = Vec3{ .items = .{ 0, 11, 0 } },
            .direction = Vec3{ .items = .{ 0, 0, -1 } },
        };
        const record = sphere.hit(&Interval.pos, &ray);
        try expectEqual(null, record);
    }
}
