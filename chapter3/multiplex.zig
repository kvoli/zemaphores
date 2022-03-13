const std = @import("std");
const Thread = std.Thread;
const Semaphore = @import("semaphore.zig").Semaphore;

// Allow multiple threads to run in the critical section at the same time,
// however enforece a limit such that at most k threads may be in the cs.
const Multiplex = struct {
    sem: Semaphore = .{},

    pub fn init(k: i32) *Multiplex {
        var multiplex = Multiplex{};
        multiplex.sem.tickets = k;
        return &multiplex;
    }

    pub fn lock(m: *Multiplex) anyerror!void {
        try m.sem.dec();
    }

    pub fn unlock(m: *Multiplex) anyerror!void {
        try m.sem.inc();
    }
};

var c: i32 = 0;
var kk: i32 = 0;
var mu = Multiplex.init(2);

fn write() anyerror!void {
    try mu.lock();

    // race
    c += 1;

    std.time.sleep(1000000);
    // shouldn't exceed
    if (c > kk) {
        @panic("too many in the cs");
    }
    std.debug.print("{}", .{c});

    // race
    c -= 1;
    try mu.unlock();
}

test "n-writers" {
    var threadA: Thread = try Thread.spawn(.{}, write, .{});
    var threadB: Thread = try Thread.spawn(.{}, write, .{});
    var threadC: Thread = try Thread.spawn(.{}, write, .{});
    threadA.join();
    threadB.join();
    threadC.join();
}
