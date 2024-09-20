const std = @import("std");

pub fn dbg(value: anytype) @TypeOf(value) {
    std.debug.print("[dbg]: {}\n", .{value});
    return value;
}
