const std = @import("std");

const Bot = @import("root.zig").Bot;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var bot = Bot{
        .allocator = allocator,
        .client = .{ .allocator = allocator },
        .api_uri_prefix = "http://postman-echo.com/",
    };
    defer bot.deinit();

    const body = try bot.invoke("post", "", 8192);

    std.debug.print("body:\n{s}\n", .{body.buf});

    const parsed = try body.toJson();
    defer parsed.deinit();

    std.debug.print("body as JSON:\n", .{});
    parsed.value.dump();
    std.debug.print("\n", .{});
}
