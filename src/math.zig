const std = @import("std");

pub fn radiansFromDegrees(deg: f64) f64 {
    return deg * (std.math.pi / 180.0);
}

test "radiansFromDegrees" {
    const expectEqual = std.testing.expectEqual;
    try expectEqual(0, radiansFromDegrees(0));
    try expectEqual(std.math.pi, radiansFromDegrees(180));
    try expectEqual(2 * std.math.pi, radiansFromDegrees(360));
}
