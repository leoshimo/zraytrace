const std = @import("std");
const color = @import("color.zig");
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec.zig").Vec3;
const Scene = @import("scene.zig").Scene;
const Interval = @import("interval.zig").Interval;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var scene = Scene.init(alloc);
    defer {
        scene.deinit();
    }

    try scene.add(.{ .sphere = .{
        .center = Vec3{ .items = .{ 0, 0, -1 } },
        .radius = 0.5,
    } });
    try scene.add(.{ .sphere = .{
        .center = Vec3{ .items = .{ 0, -100.5, -1 } },
        .radius = 100,
    } });

    const stdout = std.io.getStdOut();
    try writePPM(&scene, stdout.writer());
}

pub fn writePPM(scene: *const Scene, writer: anytype) !void {
    const width = 400;
    const aspect_ratio = 16.0 / 9.0;
    const height = @as(comptime_int, width * (1.0 / aspect_ratio));

    const viewport_height = 2.0;
    const viewport_width: comptime_float = viewport_height * (@as(comptime_float, width) / @as(comptime_float, height));

    const v_u = Vec3{ .items = .{ viewport_width, 0, 0 } };
    const v_v = Vec3{ .items = .{ 0, -viewport_height, 0 } };

    const v_u_step = v_u.div(width);
    const v_v_step = v_v.div(height);

    const camera_origin = Vec3.zero();
    const focal_length = -1.0;
    const viewport_tl = camera_origin.add(&.{ .items = .{ -viewport_width / 2.0, viewport_height / 2.0, focal_length } });
    const viewport_p0 = viewport_tl.add(&v_u_step.mult(0.5))
        .add(&v_v_step.mult(0.5));

    try writer.print(
        \\P3
        \\{d} {d}
        \\255
        \\
    , .{ width, height });

    for (0..height) |y| {
        std.debug.print("\rScanlines remaining: {d} ", .{height - y});
        for (0..width) |x| {
            const x_fl: f64 = @floatFromInt(x);
            const y_fl: f64 = @floatFromInt(y);
            const direction = viewport_p0.add(&v_u_step.mult(x_fl))
                .add(&v_v_step.mult(y_fl));
            const ray = Ray{
                .origin = camera_origin,
                .direction = direction,
            };

            const c = rayColor(scene, &ray);
            try color.write(&c, writer);
        }
    }
    std.debug.print("\rDone.                     \n", .{});
}

fn rayColor(scene: *const Scene, ray: *const Ray) color.Color {
    if (scene.hit(&Interval.pos, ray)) |record| {
        // All normal vectors are unit vectors w/ components in range [-1, 1]
        return record.normal.add(&Vec3{ .items = .{ 1, 1, 1 } }).mult(0.5);
    }

    // Gradient background:
    const scale = 0.5 * (ray.direction.unit().y() + 1.0); // y is in [-1, 1], scale to [0, 1]
    const white = color.Color{ .items = .{ 1, 1, 1 } };
    const blue = color.Color{ .items = .{ 0.5, 0.7, 1 } };
    return white.mult(1 - scale).add(&blue.mult(scale));
}

// test "writePPM" {
//     var list = std.ArrayList(u8).init(std.testing.allocator);
//     defer list.deinit();
//     var writer = list.writer();

//     try writePPM(&writer);
//     std.debug.print("{s}\n", .{list.items});
//     try std.testing.expect(std.mem.eql(u8, list.items, "Hello world\n"));
// }
