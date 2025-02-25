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

fn handleUpdate(bot: *Bot, update: objects.Update) void {
    const message = update.message orelse {
        std.log.warn("update message is null: {any}", .{update});
        return;
    };
    const text = message.text orelse {
        std.log.warn("message text is null: {any}", .{message});
        // tell the user we can't handle this message.
        sendMessage(bot, message.chat.id, "I can't handle this message");
        return;
    };

    // log the message.
    if (message.chat.username) |username| {
        std.log.info("I got a text message from {s}: {s}\n", .{ username, text });
    } else {
        std.log.info("I got a text message from {d}: {s}\n", .{ message.chat.id, text });
    }

    // build a response message.
    const response_message = std.fmt.allocPrint(
        bot.allocator,
        "I got your message: '{s}'",
        .{text},
    ) catch "I got your message";
    defer bot.allocator.free(response_message);

    // send a message back to the user.
    sendMessage(bot, message.chat.id, response_message);
}

fn sendMessage(bot: *Bot, chat_id: i64, text: []const u8) void {
    if (bot.invokeGet(methods.SendMessage{
        .chat_id = chat_id,
        .text = text,
    })) |response| {
        defer response.deinit();
        std.log.info("response: {s}\n", .{response.buf});
    } else |err| {
        std.log.warn("failed to send message: {}\n", .{err});
    }
}
