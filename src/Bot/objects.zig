const std = @import("std");

const Allocator = std.mem.Allocator;
const Value = std.json.Value;
const ParseOptions = std.json.ParseOptions;

const integer_or_string = union(enum) {
    integer: i64,
    string: []const u8,

    pub fn jsonParse(allocator: Allocator, source: anytype, options: ParseOptions) !@This() {
        const value = try Value.jsonParse(allocator, source, options);
        return switch (value) {
            .string => .{ .string = value.string },
            .integer => .{ .integer = value.integer },
            else => error.UnexpectedToken,
        };
    }
};

test "union parsing" {
    const test_allocator = std.testing.allocator;

    const parsed_integer = try std.json.parseFromSlice(
        integer_or_string,
        test_allocator,
        "-2333",
        .{},
    );
    defer parsed_integer.deinit();
    try std.testing.expect(parsed_integer.value.integer == -2333);

    const parsed_string = try std.json.parseFromSlice(
        integer_or_string,
        test_allocator,
        \\"hello \"world\""
    ,
        .{},
    );
    defer parsed_string.deinit();
    try std.testing.expect(std.mem.eql(u8, parsed_string.value.string, "hello \"world\""));
}
