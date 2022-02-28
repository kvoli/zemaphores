const std = @import("std");

const Thread = std.Thread;
const Semaphore = @import("semaphore.zig").Semaphore;

var count: i32 = 0;
var mutex: Semaphore = .{};

fn raceIncCounter() anyerror!void {
    var i: i32 = 0;
    while (i < 500) : (i += 1) {
        try countInc();
    }
}

fn countInc() anyerror!void {
    try mutex.dec();
    defer mutex.inc() catch unreachable;

    count += 1;
}

// spin on a core to try and create a race condition.
fn delay() void {
    var i: i32 = 0;
    while (i < 500000) : (i += 1) {}
}

test "Ending Values" {
    var runs: i32 = 0;
    while (runs < 1000) : (runs += 1) {
        count = 0;
        var threadA: Thread = try Thread.spawn(.{}, raceIncCounter, .{});
        var threadB: Thread = try Thread.spawn(.{}, raceIncCounter, .{});
        threadB.join();
        threadA.join();
        std.debug.print("final value: {}\n==========[{}]============\n\n", .{ count, runs });
        try std.testing.expectEqual(count, 1000);
    }
}
