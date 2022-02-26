# Eat Lunch Before Bob

> Assuming that Bob is willing to follow simple instructions, is there any way you can guarantee that tomorrow you will eat lunch before Bob?

If we ensure that there exists a *happens-before* relation between Bob and me, then it must the case that we finished 
our lunch, strictly before Bob started eating his. I'll be A, Bob can be B.

```zig
A eats lunch
A calls bob to tell him to eat lunch
B eats lunch
```

There exists an HB relationship ($\rightarrow$), `A lunch -> B lunch`. 
