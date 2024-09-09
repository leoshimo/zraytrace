const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut();
    try writePPM(stdout.writer());
}

pub fn writePPM(writer: anytype) !void {
    const width = 256;
    const height = 256;
    try writer.print(
        \\P3
        \\{d} {d}
        \\255
        \\
    , .{ width, height });

    for (0..height) |y| {
        std.debug.print("\rScanlines remaining: {d} ", .{height - y});
        for (0..width) |x| {
            const r = @as(f32, @floatFromInt(x)) / (width - 1);
            const g = @as(f32, @floatFromInt(y)) / (height - 1);
            const b: f32 = 0;

            const ri: i32 = @intFromFloat(r * 255.999);
            const gi: i32 = @intFromFloat(g * 255.999);
            const bi: i32 = @intFromFloat(b * 255.999);

            try writer.print("{d}\t{d}\t{d}\n", .{ ri, gi, bi });
        }
    }
    std.debug.print("\rDone.                     \n", .{});
}

// test "writePPM" {
//     var list = std.ArrayList(u8).init(std.testing.allocator);
//     defer list.deinit();
//     var writer = list.writer();

//     try writePPM(&writer);
//     std.debug.print("{s}\n", .{list.items});
//     try std.testing.expect(std.mem.eql(u8, list.items, "Hello world\n"));
// }
