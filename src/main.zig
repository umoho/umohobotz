const std = @import("std");

const Bot = @import("root.zig").Bot;

pub fn main() !void {
    // make allocator.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // handle the args.
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len != 3) {
        std.debug.print("tip: please set '--print <plain|json|object>'\n", .{});
        return;
    }

    // read bot token.
    const bot_token = std.process.getEnvVarOwned(allocator, "BOT_TOKEN") catch |err| {
        std.debug.print("tip: please set 'BOT_TOKEN'\n", .{});
        return err;
    };
    defer allocator.free(bot_token);

    // make API URI.
    var api_uri_prefix_concat = std.ArrayList(u8).init(allocator);
    defer api_uri_prefix_concat.deinit();
    try api_uri_prefix_concat.appendSlice("https://api.telegram.org/bot");
    try api_uri_prefix_concat.appendSlice(bot_token);
    try api_uri_prefix_concat.append('/');

    // init bot.
    var bot = Bot{
        .allocator = allocator,
        .client = .{ .allocator = allocator },
        .api_uri_prefix = api_uri_prefix_concat.items,
    };
    defer bot.deinit();

    // invoke API.
    const body = try bot.invoke(.getUpdates, "", 1024 * 1024);
    defer body.deinit();

    if (std.mem.eql(u8, args[2], "plain")) {
        // print as plain.
        std.debug.print("plain:\n{s}\n", .{body.buf.items});
    }

    if (std.mem.eql(u8, args[2], "json")) {
        // print as json.
        const parsed_json = try body.toJson();
        defer parsed_json.deinit();
        std.debug.print("JSON:\n", .{});
        parsed_json.value.dump();
        std.debug.print("\n", .{});
    }

    if (std.mem.eql(u8, args[2], "object")) {
        // print as object.
        const parsed_object = try body.toResponseObject([]Bot.objects.Update);
        defer parsed_object.deinit();
        std.debug.print("object:\n{}\n", .{parsed_object.value});
    }
}
