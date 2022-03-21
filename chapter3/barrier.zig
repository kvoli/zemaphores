const std = @import("std");
const Thread = std.Thread;
const Semaphore = @import("semaphore.zig").Semaphore;
const Mutex = Thread.Mutex;

/// Every thread should execute  the code in this fashion:
///
/// (a) rendevous
/// (b) critical section
///
/// Where there are n threads, no thread should execute (b) until n threads
/// have executed rendevous. i.e. the first n-1 threads block until the nth
/// thread enters the cs.
const Barrier = struct {
    sem: Semaphore,
    mu: Mutex,
    threads: i32,
    waiting: i32,

    fn init(threads: i32) Barrier {
        return .{
            .sem = Semaphore{ .tickets = 0 },
            .mu = Mutex{},
            .threads = threads,
            .waiting = 0,
        };
    }

    fn wait(b: *Barrier) anyerror!void {
        b.mu.lock();
        std.debug.print("{}/{}\n", .{ b.waiting, b.threads });
        if (b.waiting >= b.threads - 1) {
            try b.sem.inc();
            b.mu.unlock();
        } else {
            b.waiting += 1;
            b.mu.unlock();
            try b.sem.dec();
        }
    }
};

fn testfn(b: *Barrier, id: i32) void {
    b.wait() catch @panic("error waiting");
    std.debug.print("{} in", .{id});
}

test "should wait" {
    comptime var b = Barrier.init(3);

    var threadA = try Thread.spawn(.{}, testfn, .{ &b, 0 });
    var threadB = try Thread.spawn(.{}, testfn, .{ &b, 1 });
    var threadC = try Thread.spawn(.{}, testfn, .{ &b, 2 });

    threadA.join();
    threadB.join();
    threadC.join();
}
