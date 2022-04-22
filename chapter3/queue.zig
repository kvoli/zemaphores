const std = @import("std");
const Thread = std.Thread;
const Semaphore = Thread.Semaphore;
const ArrayList = std.ArrayList;
const Mutex = Thread.Mutex;

/// the same follower and leader dance together.
const Queue = struct {
    follower_sem: Semaphore = Semaphore{},
    leader_sem: Semaphore = Semaphore{},
    rendevous: Semaphore = Semaphore{},
    mu: Semaphore = Semaphore{},
    leaders: i32 = 0,
    followers: i32 = 0,

    fn init() Queue {
        var q = Queue{};
        q.mu.permits = 1;
        return q;
    }

    fn leader(q: *Queue) void {
        q.mu.wait();
        if (q.followers > 0) {
            q.followers -= 1;
            q.follower_sem.post();
        } else {
            q.leaders += 1;
            q.mu.post();
            q.leader_sem.wait();
        }
        q.rendevous.wait();
        q.mu.post();
    }

    fn follower(q: *Queue) void {
        q.mu.wait();
        if (q.leaders > 0) {
            q.leaders -= 1;
            q.leader_sem.post();
        } else {
            q.followers += 1;
            q.mu.post();
            q.follower_sem.wait();
        }

        q.rendevous.post();
    }
};

var in: i32 = 0;
var mu: Mutex = Mutex{};

fn inc() void {
    mu.lock();
    in += 1;
    mu.unlock();
}

fn testfn(q: *Queue, id: i32) void {
    std.debug.print("{} wait\n", .{id});
    if (@mod(id, 2) == 0) {
        q.follower();
        std.debug.print("follower {} in\n", .{id});
    } else {
        q.leader();
        std.debug.print("leader {} in\n", .{id});
    }
    inc();
}

test "should wait" {
    var b = Queue.init();

    var threadA = try Thread.spawn(.{}, testfn, .{ &b, 1 });
    var threadB = try Thread.spawn(.{}, testfn, .{ &b, 2 });
    var threadC = try Thread.spawn(.{}, testfn, .{ &b, 3 });
    var threadD = try Thread.spawn(.{}, testfn, .{ &b, 4 });

    threadA.join();
    threadB.join();
    threadC.join();
    threadD.join();

    mu.lock();
    var expected: i32 = 4;
    try std.testing.expectEqual(expected, in);
    mu.unlock();
}
