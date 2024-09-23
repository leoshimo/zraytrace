const std = @import("std");
const color = @import("color.zig");
const Ray = @import("ray.zig").Ray;
const Vec3 = @import("vec.zig").Vec3;
const Scene = @import("scene.zig").Scene;
const Interval = @import("interval.zig").Interval;
const Camera = @import("camera.zig").Camera;
const rand = @import("rand.zig");

pub fn main() !void {
    try rand.init();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const scene = blk: {
        var scene = Scene.init(alloc);
        try scene.add(.{ .sphere = .{
            .center = Vec3{ .items = .{ 0, 0, -1 } },
            .radius = 0.5,
        } });
        try scene.add(.{ .sphere = .{
            .center = Vec3{ .items = .{ 0, -100.5, -1 } },
            .radius = 100,
        } });
        break :blk scene;
    };
    defer {
        scene.deinit();
    }

    const camera = Camera.init(.{
        .width = 400,
        .aspect_ratio = 16.0 / 9.0,
        .viewport_height = 2.0,
        .focal_length = -1,
        .sampling = .{ .simple = .{
            .number_of_samples = 100,
        } },
    });

    const stdout = std.io.getStdOut();
    var writer = std.io.bufferedWriter(stdout.writer());
    try camera.render(&scene, writer.writer());
    try writer.flush();
}
