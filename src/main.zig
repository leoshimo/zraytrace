const std = @import("std");
const color = @import("color.zig");

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
            const c = color.Color.new(.{ @as(f32, @floatFromInt(x)) / (width - 1), @as(f32, @floatFromInt(y)) / (height - 1), 0 });
            try color.write(&c, writer);
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
