const std = @import("std");

var rng: ?std.Random = null;

pub fn init() !void {
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));
    var prng = std.Random.DefaultPrng.init(seed);
    rng = prng.random();
}

pub fn rand() f64 {
    return rng.?.float(f64);
}

pub fn randRange(min: f64, max: f64) f64 {
    return min + (max - min) * rand();
}
