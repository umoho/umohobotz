const std = @import("std");

const Bot = @import("root.zig").Bot;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const bot_token = std.process.getEnvVarOwned(allocator, "BOT_TOKEN") catch |err| {
        std.debug.print("tip: please set 'BOT_TOKEN'\n", .{});
        return err;
    };
    defer allocator.free(bot_token);

    var api_uri_prefix_concat = std.ArrayList(u8).init(allocator);
    defer api_uri_prefix_concat.deinit();
    try api_uri_prefix_concat.appendSlice("https://api.telegram.org/bot");
    try api_uri_prefix_concat.appendSlice(bot_token);
    try api_uri_prefix_concat.append('/');

    var bot = Bot{
        .allocator = allocator,
        .client = .{ .allocator = allocator },
        .api_uri_prefix = api_uri_prefix_concat.items,
    };
    defer bot.deinit();

    const body = try bot.invoke(.getUpdates, "", 1024 * 1024);
    defer body.deinit();

    std.debug.print("body:\n{s}\n", .{body.buf.items});

    const parsed_json = try body.toJson();
    defer parsed_json.deinit();

    std.debug.print("body as JSON:\n", .{});
    parsed_json.value.dump();
    std.debug.print("\n", .{});

    const parsed_object = try body.toResponseObject([]Bot.objects.Update);
    defer parsed_object.deinit();

    std.debug.print("body as ResponseObject([]Bot.objects.Update):\n{}\n", .{parsed_object.value});
}
