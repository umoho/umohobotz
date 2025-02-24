const std = @import("std");

const Bot = @import("telegram/bot.zig").Bot;

pub fn main() !void {
    // make allocator.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // read bot token.
    const bot_token = std.process.getEnvVarOwned(allocator, "BOT_TOKEN") catch |err| {
        std.debug.print("tip: please set 'BOT_TOKEN'\n", .{});
        return err;
    };
    defer allocator.free(bot_token);

    // initialize bot.
    var bot = try Bot.init(allocator, bot_token);
    defer bot.deinit();

    try bot.getUpdatesLoop();
}
