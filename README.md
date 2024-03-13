# zig-collections
Fast and convenient implementation of dynamic data structures for zig.

# Requirements
[Zig master](https://ziglang.org/download/) is the only required dependency.

# Instalation
There is only one ways to include `zig-collections` in your project:

### Official package manager

1. Go to the folder of your project and open the terminal.
2. Write `zig fetch https://github.com/Xenely14/zig-collections/archive/<commit>.tar.gz` where `<commit>` is commit id.</br>
  Check your `build.zig.zon`, ther must be a `zig-collections` dependency like this:
    ```zig
    .dependencies = .{
        .collections = .{
            .url = "https://github.com/Xenely14/zig-collections/archive/<commit>.tar.gz",
            .hash = "hash",
        },
    },
    ```
3. Add following code to your `build.zig` file to access your module:
    ```zig
    const collections = b.dependency("collections", .{});
    
    // Add module import into your root file
    exe.root_module.addImport("collections", collections.module("collections"));
    ```

# TODO
- [x] Implement [linked list](https://en.wikipedia.org/wiki/Linked_list) data structure.
- [ ] Implement [vector(dynamic array)](https://en.wikipedia.org/wiki/Dynamic_array) data structure.
- [ ] Implement [stack](https://en.wikipedia.org/wiki/Stack_(abstract_data_type)) data structure.
- [ ] Implement [queue](https://en.wikipedia.org/wiki/Queue_(abstract_data_type)) data structure.
- [ ] Implement [dequeue](https://en.wikipedia.org/wiki/Double-ended_queue) data structure.
