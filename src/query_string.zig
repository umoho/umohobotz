const std = @import("std");

const Allocator = std.mem.Allocator;

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

    pub fn toString(self: *@This(), allocator: Allocator) ![]u8 {
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

test "toString" {
    const test_allocator = std.testing.allocator;

    var query_string = QueryString.init(test_allocator);
    defer query_string.deinit();

    try query_string.put("hello", "你好");
    try query_string.put("world", "世界");

    const str = try query_string.toString(test_allocator);
    defer test_allocator.free(str);

    try std.testing.expect(std.mem.eql(
        u8,
        str,
        "?hello=%e4%bd%a0%e5%a5%bd&world=%e4%b8%96%e7%95%8c",
    ));
}

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

    const test_cases = [_][]const u8{
        "Hello World",
        "你好世界",
        "Test@#$%^&*()",
    };

    for (test_cases) |case| {
        const encoded = try encode(allocator, case);
        defer allocator.free(encoded);

        try std.testing.expect(encoded.len > 0);
        std.debug.print("'{s}' -> '{s}'\n", .{ case, encoded });
    }
}
