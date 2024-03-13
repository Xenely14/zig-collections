const std = @import("std");

pub fn build(b: *std.Build) !void {
    _ = b.addModule("collections", .{
        .root_source_file = .{
            .path = "src/collections.zig",
        },
    });
}
