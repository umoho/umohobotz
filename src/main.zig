const std = @import("std");

const Bot = @import("telegram/bot.zig").Bot;

const objects = @import("telegram/objects.zig");
const methods = @import("telegram/methods.zig");
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

    try bot.getUpdatesLoop(handleUpdate);
}

fn handleUpdate(bot: *Bot, update: objects.Update) !void {
    if (update.message) |message| {
        if (message.text) |text| {
            std.debug.print("I got a text message: {s}\n", .{text});

            // send a message to the user.
            _ = try bot.invokeGet(methods.SendMessage{
                // .chat_id = .{ .integer = message.chat.id },
                .chat_id = message.chat.id,
                .text = "I got your message",
            });
        }
    }
}
