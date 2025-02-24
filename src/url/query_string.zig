const std = @import("std");

const Allocator = std.mem.Allocator;

/// Pair of key and value.
pub fn Pair(comptime K: type, comptime V: type) type {
    return struct {
        key: K,
        value: V,
    };
}

/// Build pairs from a struct.
///
/// Note:
///
/// - Remember to free the returned pairs.
pub fn pairsFromStruct(
    allocator: Allocator,
    comptime T: type,
    value: T,
) ![]Pair([]const u8, []const u8) {
    const fields = std.meta.fields(T);
    const len = fields.len;
    var pairs = try allocator.alloc(Pair([]const u8, []const u8), len);

    inline for (fields, 0..) |field, i| {
        const field_value = @field(value, field.name);
        const field_type = @TypeOf(field_value);

        pairs[i] = switch (field_type) {
            []const u8 => .{
                .key = field.name,
                .value = field_value,
            },
            []u8 => .{
                .key = field.name,
                .value = field_value,
            },
            comptime_int => .{
                .key = field.name,
                .value = try std.fmt.allocPrint(allocator, "{d}", .{field_value}),
            },
            else => .{
                .key = field.name,
                .value = try std.fmt.allocPrint(allocator, "{any}", .{field_value}),
            },
        };
    }

    return pairs;
}

test pairsFromStruct {
    const test_allocator = std.testing.allocator;

    const TestStruct = struct {
        foo: []const u8,
        hello: []const u8,
    };
    const test_struct = TestStruct{
        .foo = "bar",
        .hello = "world",
    };

    const pairs = try pairsFromStruct(test_allocator, TestStruct, test_struct);
    defer test_allocator.free(pairs);

    try std.testing.expectEqual(pairs.len, 2);
    try std.testing.expectEqualStrings("foo", pairs[0].key);
    try std.testing.expectEqualStrings("bar", pairs[0].value);
    try std.testing.expectEqualStrings("hello", pairs[1].key);
    try std.testing.expectEqualStrings("world", pairs[1].value);
}

/// Build query string from pairs.
///
/// Note:
///
/// - Remember to free the returned string.
/// - Pairs' key and value will be encoded.
/// - Keys are not deduplicated.
/// - It adds '?' at the beginning of the query string.
pub fn buildQueryString(
    allocator: Allocator,
    pairs: []const Pair([]const u8, []const u8),
) ![]u8 {
    var str = std.ArrayList(u8).init(allocator);
    defer str.deinit();

    var is_first = true;
    for (pairs) |pair| {
        // put '?' if it's the first pair,
        // put '&' if it's not the first pair.
        if (is_first) {
            try str.append('?');
            is_first = false;
        } else {
            try str.append('&');
        }

        // put encoded key.
        const encoded_key = try encode(allocator, pair.key);
        defer allocator.free(encoded_key);
        try str.appendSlice(encoded_key);

        // put '='.
        try str.append('=');

        // put encoded value.
        const encoded_value = try encode(allocator, pair.value);
        defer allocator.free(encoded_value);
        try str.appendSlice(encoded_value);
    }
    // clear and free if error.
    // I'm not sure if it's necessary to do this.
    errdefer str.clearAndFree();

    return str.toOwnedSlice();
}

test buildQueryString {
    const test_allocator = std.testing.allocator;

    const pairs = [_]Pair([]const u8, []const u8){
        .{ .key = "hello", .value = "你好" },
        .{ .key = "world", .value = "世界" },
    };

    const query_string = try buildQueryString(test_allocator, &pairs);
    defer test_allocator.free(query_string);

    try std.testing.expectEqualStrings(
        "?hello=%e4%bd%a0%e5%a5%bd&world=%e4%b8%96%e7%95%8c",
        query_string,
    );
}

/// Encode a string to be used in query string.
///
/// Note:
///
/// - Remember to free the returned string.
fn encode(allocator: Allocator, origin: []const u8) ![]u8 {
    var str = std.ArrayList(u8).init(allocator);
    defer str.deinit();

    for (origin) |char| {
        switch (char) {
            'a'...'z', 'A'...'Z', '0'...'9', '-', '_', '.', '~' => {
                try str.append(char);
            },
            else => {
                const hex = try std.fmt.allocPrint(allocator, "%{x:0>2}", .{char});
                defer allocator.free(hex);
                try str.appendSlice(hex);
            },
        }
    }

    return str.toOwnedSlice();
}

test "encode" {
    const allocator = std.testing.allocator;

    const encoded1 = try encode(allocator, "Hello World");
    defer allocator.free(encoded1);
    try std.testing.expectEqualStrings(
        "Hello%20World",
        encoded1,
    );

    const encoded2 = try encode(allocator, "你好世界");
    defer allocator.free(encoded2);
    try std.testing.expectEqualStrings(
        "%e4%bd%a0%e5%a5%bd%e4%b8%96%e7%95%8c",
        encoded2,
    );

    const encoded3 = try encode(allocator, "Test@#$%^&*()");
    defer allocator.free(encoded3);
    try std.testing.expectEqualStrings(
        "Test%40%23%24%25%5e%26%2a%28%29",
        encoded3,
    );
}
