const std = @import("std");
const Vec3 = @import("vec.zig").Vec3;
const Ray = @import("ray.zig").Ray;
const Scene = @import("scene.zig").Scene;
const color = @import("color.zig");
const Color = color.Color;
const Interval = @import("interval.zig").Interval;
const rand = @import("rand.zig");

pub const Config = struct {
    width: usize = 100,
    aspect_ratio: f64 = 1.0,
    focal_length: f64 = -1.0,
    viewport_height: f64 = 2.0,
    sampling: Sampling = .none,
};

pub const Sampling = union(enum) {
    none: void,
    simple: struct { number_of_samples: usize },
};

pub const Camera = struct {
    const Self = @This();

    width: usize,
    height: usize,
    position: Vec3,
    vp_00: Vec3,
    vp_x_step: Vec3,
    vp_y_step: Vec3,
    sampling: Sampling,

    pub fn init(comptime config: Config) Self {
        const width = config.width;
        const height = width * (1 / config.aspect_ratio);

        const vp_height = config.viewport_height;
        const vp_width = vp_height * width / height;

        const focal_length = config.focal_length;
        const position = Vec3.zero();
        const vp_x_step = Vec3{ .items = .{
            vp_width / width, 0, 0,
        } };
        const vp_y_step = Vec3{ .items = .{
            0, -vp_height / height, 0,
        } };
        const vp_top_left = position.add(&Vec3{ .items = .{
            -vp_width / 2, vp_height / 2, focal_length,
        } });
        const vp_00 = vp_top_left.add(&vp_x_step.mult(0.5))
            .add(&vp_y_step.mult(0.5));

        return Self{
            .width = width,
            .height = height,
            .position = position,
            .vp_00 = vp_00,
            .vp_x_step = vp_x_step,
            .vp_y_step = vp_y_step,
            .sampling = config.sampling,
        };
    }

    pub fn render(camera: *const Self, scene: *const Scene, writer: anytype) !void {
        try writer.print(
            \\P3
            \\{d} {d}
            \\255
            \\
        , .{ camera.width, camera.height });

        for (0..camera.height) |y| {
            std.debug.print("\rScanlines remaining: {d} ", .{camera.height - y});
            for (0..camera.width) |x| {
                const c: color.Color = camera.colorForPixel(scene, x, y);
                try color.write(&c, writer);
            }
        }
        std.debug.print("\rDone.                     \n", .{});
    }

    fn colorForPixel(camera: *const Self, scene: *const Scene, x: usize, y: usize) color.Color {
        switch (camera.sampling) {
            .none => {
                const r = camera.ray(x, y);
                return rayColor(scene, &r);
            },
            .simple => |s| {
                var c = color.Color.zero();
                for (0..s.number_of_samples) |_| {
                    const r = camera.ray(x, y);
                    c.adding(&rayColor(scene, &r));
                }
                return c.div(@floatFromInt(s.number_of_samples));
            },
        }
    }

    fn rayColor(scene: *const Scene, r: *const Ray) Color {
        if (scene.hit(&Interval.pos, r)) |record| {
            // All normal vectors are unit vectors w/ components in range [-1, 1]
            return record.normal.add(&Vec3{ .items = .{ 1, 1, 1 } }).mult(0.5);
        }

        // Gradient background:
        const scale = 0.5 * (r.direction.unit().y() + 1.0); // y is in [-1, 1], scale to [0, 1]
        const white = color.Color{ .items = .{ 1, 1, 1 } };
        const blue = color.Color{ .items = .{ 0.5, 0.7, 1 } };
        return white.mult(1 - scale).add(&blue.mult(scale));
    }

    fn ray(camera: *const Camera, x: usize, y: usize) Ray {
        const x_f: f64 = @floatFromInt(x);
        const y_f: f64 = @floatFromInt(y);

        switch (camera.sampling) {
            .none => {
                const direction = camera.vp_00.add(&camera.vp_x_step.mult(x_f)).add(&camera.vp_y_step.mult(y_f));
                return Ray{ .origin = camera.position, .direction = direction };
            },
            .simple => {
                const offset_x = rand.rand() - 0.5;
                const offset_y = rand.rand() - 0.5;
                const direction = camera.vp_00
                    .add(&camera.vp_x_step.mult(x_f + offset_x))
                    .add(&camera.vp_y_step.mult(y_f + offset_y));
                return Ray{ .origin = camera.position, .direction = direction };
            },
        }
    }
};

test "Camera" {
    const camera = Camera.init(.{});
    _ = camera;
}
