const Vec3 = @import("vec.zig").Vec3;

/// RGB color where each component is [0, 1]
pub const Color = Vec3;

/// Write `Color` as next PPM pixel
pub fn write(color: *const Color, writer: anytype) !void {
    const r: i32 = @intFromFloat(color.x() * 255.99);
    const g: i32 = @intFromFloat(color.y() * 255.99);
    const b: i32 = @intFromFloat(color.z() * 255.99);
    try writer.print("{d}\t{d}\t{d}\n", .{ r, g, b });
}
