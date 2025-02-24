const std = @import("std");

const Allocator = std.mem.Allocator;

const query_string = @import("query_string.zig");

/// Make a URL from API URI prefix, method and arguments.
///
/// Note:
///
/// - Remember to free the returned URL.
/// - If `args` is `.{}`, it will not add query string.
pub fn buildUrl(
    allocator: Allocator,
    api_uri_prefix: []const u8,
    method: []const u8,
    args: anytype,
) ![]u8 {
    var str = std.ArrayList(u8).init(allocator);
    defer str.deinit();

    try str.appendSlice(api_uri_prefix);
    try str.appendSlice(method);

    const pairs = try query_string.pairsFromStruct(allocator, @TypeOf(args), args);
    defer query_string.freePairs(allocator, @TypeOf(args), pairs);

    const qs = try query_string.buildQueryString(allocator, pairs);
    defer allocator.free(qs);

    try str.appendSlice(qs);

    return str.toOwnedSlice();
}

test buildUrl {
    const allocator = std.testing.allocator;

    const url = try buildUrl(allocator, "https://example.com", "/getUpdates", .{
        .limit = 100,
        .offset = 200,
    });
    defer allocator.free(url);

    try std.testing.expectEqualSlices(
        u8,
        "https://example.com/getUpdates?limit=100&offset=200",
        url,
    );

    const url_empty_args = try buildUrl(allocator, "https://example.com", "/getUpdates", .{});
    defer allocator.free(url_empty_args);

    try std.testing.expectEqualSlices(
        u8,
        "https://example.com/getUpdates",
        url_empty_args,
    );
}
