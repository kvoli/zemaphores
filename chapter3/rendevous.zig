const std = @import("std");

// We want to guarantee that a1 > b2 /\ b1 > a2
// A: a1   B: b1
//    a2      b2
// i.e. a Rendevous just following a1, b1.
// A: a1   B: b1
// ---[Rendevous]---
//    a2      b2
//
const Thread = std.Thread;
const Semaphore = Thread.Semaphore;

var log = std.ArrayList(i32).init(std.testing.allocator);

const Signaller = struct {
    sem: *Semaphore = .{},
    name: []const u8,

    fn f(self: *Signaller, other: *Semaphore) anyerror!void {
        std.debug.print("\nstatement {s}1\n", .{self.name});
        try log.append(1);
        self.sem.post();
        other.wait();
        std.debug.print("\nstatement {s}2\n", .{self.name});
        try log.append(2);
    }
};

var semA = Semaphore{};
var semB = Semaphore{};

fn a() anyerror!void {
    var sigA: Signaller = Signaller{ .sem = &semA, .name = "a" };
    try sigA.f(&semB);
}

fn b() anyerror!void {
    var sigB: Signaller = Signaller{ .sem = &semB, .name = "b" };
    try sigB.f(&semA);
}

test "Rendevous" {
    var threadA: Thread = try Thread.spawn(.{}, a, .{});
    var threadB: Thread = try Thread.spawn(.{}, b, .{});
    threadA.join();
    threadB.join();
    //try std.testing.expectEqualSlices(i32, [_]i32{ 1, 1, 2, 2 }, log.items);
    log.deinit();
}
