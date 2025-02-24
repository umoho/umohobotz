const std = @import("std");

const Allocator = std.mem.Allocator;

/// Pair of key and value.
pub fn Pair(comptime K: type, comptime V: type) type {
    return struct {
        key: K,
        value: V,
    };
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

pub const QueryString = struct {
    map: std.StringHashMap([]const u8),

    pub fn init(allocator: Allocator) @This() {
        return .{
            .map = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.map.deinit();
    }

    pub fn put(self: *@This(), key: []const u8, value: []const u8) !void {
        try self.map.put(key, value);
    }

    pub fn toOnwedSlice(self: *@This(), allocator: Allocator) ![]u8 {
        var str = std.ArrayList(u8).init(allocator);
        defer str.deinit();

        var is_first = true;
        var iterator = self.map.iterator();
        while (iterator.next()) |entry| {
            if (is_first) {
                try str.append('?');
                is_first = false;
            } else {
                try str.append('&');
            }
            const encoded_key = try encode(allocator, entry.key_ptr.*);
            try str.appendSlice(encoded_key);
            allocator.free(encoded_key);

            try str.append('=');

            const encoded_value = try encode(allocator, entry.value_ptr.*);
            try str.appendSlice(encoded_value);
            allocator.free(encoded_value);
        }
        errdefer str.clearAndFree();

        return str.toOwnedSlice();
    }
};

test "toOwnedSlice" {
    const test_allocator = std.testing.allocator;

    var query_string = QueryString.init(test_allocator);
    defer query_string.deinit();

    try query_string.put("hello", "你好");
    try query_string.put("world", "世界");

    const str = try query_string.toOnwedSlice(test_allocator);
    defer test_allocator.free(str);

    try std.testing.expect(std.mem.eql(
        u8,
        str,
        "?hello=%e4%bd%a0%e5%a5%bd&world=%e4%b8%96%e7%95%8c",
    ));
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
