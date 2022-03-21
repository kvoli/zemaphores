const std = @import("std");
const Thread = std.Thread;
const Mutex = Thread.Mutex;
const Atomic = std.atomic.Atomic;

// Condition mimics pthread_cond_signal within the runtime.
pub const Condition = struct {
    pending: bool = false,
    queue_list: QueueList = .{},
    queue_mu: Mutex = .{},

    const QueueList = std.SinglyLinkedList(QueueItem);

    pub const QueueItem = struct {
        futex: i32 = 0,

        fn wait(cond: *@This()) void {
            while (@atomicLoad(i32, &cond.futex, .Acquire) == 0) {
                std.atomic.spinLoopHint();
            }
        }

        fn notify(cond: *@This()) void {
            @atomicStore(i32, &cond.futex, 1, .Release);
        }
    };

    pub fn wait(cond: *Condition, mu: *Mutex) void {
        var waiter = QueueList.Node{ .data = .{} };

        cond.queue_mu.lock();
        defer cond.queue_mu.unlock();

        cond.queue_list.prepend(&waiter);
        @atomicStore(bool, &cond.pending, true, .SeqCst);

        mu.unlock();
        waiter.data.wait();
        mu.lock();
    }

    pub fn signal(cond: *Condition) void {
        if (@atomicLoad(bool, &cond.pending, .SeqCst) == false) {
            return;
        }

        const maybe_waiter = blk: {
            cond.queue_mu.lock();
            defer cond.queue_mu.unlock();

            const maybe_waiter = cond.queue_list.popFirst();
            @atomicStore(bool, &cond.pending, cond.queue_list.first != null, .SeqCst);
            break :blk maybe_waiter;
        };

        if (maybe_waiter) |waiter|
            waiter.data.notify();
    }
};

pub const Semaphore = struct {
    tickets: i32 = 0,
    mu: Mutex = .{},
    cond: Condition = .{},

    // Acquire a ticket
    pub fn dec(self: *Semaphore) anyerror!void {
        self.mu.lock();
        defer self.mu.unlock();

        while (self.tickets == 0) {
            self.cond.wait(&self.mu);
        }

        self.tickets -= 1;
        if (self.tickets > 0) {
            self.cond.signal();
        }
    }

    // Drop a ticket
    pub fn inc(self: *Semaphore) anyerror!void {
        self.mu.lock();
        defer self.mu.unlock();

        self.tickets += 1;
        self.cond.signal();
    }
};
