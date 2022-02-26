const std = @import("std");
const atomic = std.atomic;

var eatenLunch: atomic.Atomic(i32) = atomic.Atomic(i32).init();

const Eater = struct {
    ticket: i32,
    name: []u8,

    fn init(name: []u8) Eater {
        return .{
            .ticket = 0,
            .name = name,
        };
    }

    fn eatLunch(self: @This()) void {
        var acq: i32 = -1;
        var swapped: i32 = -1;
        while (swapped != acq) : (swapped = eatenLunch.compareAndSwap(acq, acq + 1, atomic.Ordering.SeqCst, atomic.Ordering.SeqCst)) {
            acq = eatenLunch.value;
        }
        self.ticket = acq + 1;
        return self.ticket;
    }
};

const testing = std.testing;

test "lunchWithBob" {}
