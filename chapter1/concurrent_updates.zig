const std = @import("std");
const Thread = std.Thread;

// This is similar to concurrent_writes, a race occurs and we force this every
// time with delay. 1 is the final result, when you would expect 2 to be.

var count: i32 = 0;

// spin on a core to try and create a race condition.
fn delay() void {
    var i: i32 = 0;
    while (i < 500000) : (i += 1) {}
}

fn a() void {
    var temp: i32 = count;
    delay();
    count = temp + 1;
}

fn b() void {
    var temp: i32 = count;
    delay();
    count = temp + 1;
}

test "Ending Values" {
    var runs: i32 = 0;
    while (runs < 1000) : (runs += 1) {
        count = 0;
        var threadA: Thread = try Thread.spawn(.{}, a, .{});
        var threadB: Thread = try Thread.spawn(.{}, b, .{});
        threadB.join();
        threadA.join();
        std.debug.print("final value: {}\n==========[{}]============\n\n", .{ count, runs });
    }
    try std.testing.expect(true);
}
