const std = @import("std");

const Allocator = std.mem.Allocator;

/// Pair of key and value.
pub const Pair = struct {
    /// Field name.
    key: []const u8,

    /// Field value.
    ///
    /// Note:
    ///
    /// - If the type of the value is not `[]const u8`,
    ///   it will be converted to `[]const u8` by `std.fmt.allocPrint`.
    /// - If the value is from `allocPrint`, it will be freed by `freePairs`.
    value: []const u8,

    /// Means the value is from `allocPrint`.
    allocated: bool,
};

/// Build pairs from a struct.
///
/// Note:
///
/// - Remember to free the returned pairs by `freePairs`.
/// - If a field is optional and its value is `null`, it will be ignored.
pub fn pairsFromStruct(
    allocator: Allocator,
    comptime T: type,
    value: T,
) ![]Pair {
    const fields = std.meta.fields(T);

    // count non-optional fields for the allocation.
    comptime var valid_fields = 0;
    inline for (fields) |field| {
        if (@typeInfo(@TypeOf(@field(value, field.name))) != .Optional) {
            valid_fields += 1;
        }
    }

    const pairs = try allocator.alloc(Pair, valid_fields);
    errdefer allocator.free(pairs);

    var pair_index: usize = 0;
    inline for (fields) |field| {
        const field_value = @field(value, field.name);
        const field_type = @TypeOf(field_value);

        if (@typeInfo(field_type) == .Optional) {
            // add pair, or do nothing if `field_value` is null.
            if (field_value) |actual_value| try addPair(
                allocator,
                pairs,
                &pair_index,
                field.name,
                actual_value,
            );
        } else {
            // add pair, if not optional.
            try addPair(
                allocator,
                pairs,
                &pair_index,
                field.name,
                field_value,
            );
        }
    }

    return pairs;
}

/// Add a pair to the pairs, and increment the pair index.
fn addPair(
    allocator: Allocator,
    pairs: []Pair,
    pair_index: *usize,
    key: []const u8,
    value: anytype,
) !void {
    if (pair_index.* >= pairs.len) {
        return error.IndexOutOfBounds;
    }

    const T = @TypeOf(value);
    pairs[pair_index.*] = .{
        .key = key,
        .value = switch (T) {
            []const u8, []u8 => value,
            else => try std.fmt.allocPrint(allocator, "{any}", .{value}),
        },
        .allocated = switch (T) {
            []const u8, []u8 => false,
            else => true,
        },
    };
    pair_index.* += 1;
}

/// Free the pairs.
///
/// Note:
///
/// - You don't need to `allocator.free` again after calling this function.
pub fn freePairs(allocator: Allocator, pairs: []Pair) void {
    for (pairs) |pair| {
        if (pair.allocated) {
            allocator.free(pair.value);
        }
    }
    allocator.free(pairs);
}

test pairsFromStruct {
    const test_allocator = std.testing.allocator;

    const TestStruct = struct {
        hello: []const u8,
        none: ?bool,
        answer: i64,
    };
    const test_struct = TestStruct{
        .hello = "world",
        .none = null,
        .answer = 42,
    };

    const pairs = try pairsFromStruct(test_allocator, TestStruct, test_struct);
    defer freePairs(test_allocator, pairs);

    try std.testing.expectEqual(pairs.len, 2);
    try std.testing.expectEqualStrings("hello", pairs[0].key);
    try std.testing.expectEqualStrings("world", pairs[0].value);
    try std.testing.expectEqualStrings("answer", pairs[1].key);
    try std.testing.expectEqualStrings("42", pairs[1].value);
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
    pairs: []const Pair,
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

    const pairs = [_]Pair{
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
