const std = @import("std");
const Thread = std.Thread;

// Try and introduce a race condition on x.
// We will represent the results as [ordering] : (print, final).
// The possible results are:
// a1 > a2 > b1 : (5, 7)
// b1 > a1 > a2 : (5, 5)
// a1 > b2 > a2 : (7, 7)
//
// i.e. this is the shuffle product of A x B. the only outcome not in this set,
// is a2 > ((a1 > b1)  || (b1 > a1)). as that is impossible to occur, given a
// is executed sequentially. i.e. we cannot reorder internal functions, where
// there exists a HB relationship a1 -> a2
// The impossible results are:
// a2 > a1 > b1 : (-1, 7)
// a2 > b1 > a1 : (-1, 5)

var x: i32 = -1;

fn delay() void {
    var i: i32 = 0;
    while (i < 500000) : (i += 1) {}
}

fn a() void {
    delay();
    x = 5; // a1
    std.debug.print("a2 {}\n", .{x}); // a2
}

fn b() void {
    delay();
    x = 7; // b1
}

test "Ending Values" {
    var runs: i32 = 0;
    while (runs < 1000) : (runs += 1) {
        var threadA: Thread = try Thread.spawn(.{}, a, .{});
        var threadB: Thread = try Thread.spawn(.{}, b, .{});
        std.debug.print("final value: {}\n==========[{}]============\n\n", .{ x, runs });
        threadB.join();
        threadA.join();
    }
    try std.testing.expect(true);
}
