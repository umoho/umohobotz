const std = @import("std");

const Bot = @import("telegram/bot.zig").Bot;

const objects = @import("telegram/objects.zig");
const methods = @import("telegram/methods.zig");

const OpenRouter = @import("openrouter/openrouter.zig").OpenRouter;
const DateTime = @import("datetime/datetime.zig").DateTime;

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
        // sendMessage(bot, message.chat.id, "I can't handle this message");
        return;
    };

    // log the message.
    if (message.from) |from| {
        std.log.info("I got a text message from {s}: {s}", .{
            from.username orelse from.first_name,
            text,
        });
    } else {
        std.log.info("I got a text message from {d}: {s}", .{ message.chat.id, text });
    }

    // add user info to the text.
    const name = if (message.from) |from| from.username orelse from.first_name else null;
    const time = DateTime.fromUnixTimestamp(message.date).toText(bot.allocator) catch unreachable;
    const text_included_info = addUserInfo(bot.allocator, name, time, text) catch unreachable;
    defer bot.allocator.free(text_included_info);

    // get reply from openrouter.
    const reply_text = getReply(bot.allocator, text_included_info) catch |err| {
        std.log.warn("failed to get reply: {}", .{err});
        // sendMessage(bot, message.chat.id, "I can't reply to your message");
        return;
    } orelse {
        std.log.warn("failed to get reply: text is null", .{});
        // sendMessage(bot, message.chat.id, "I can't reply to your message");
        return;
    };
    defer bot.allocator.free(reply_text);

    if (reply_text.len == 0) {
        std.log.warn("failed to get reply: text is empty", .{});
        // sendMessage(bot, message.chat.id, "I can't reply to your message");
        return;
    }

    // send a message back to the user.
    sendMessage(bot, message.chat.id, reply_text);
}

fn sendMessage(bot: *Bot, chat_id: i64, text: []const u8) void {
    if (bot.client.invokePost(methods.SendMessage{
        .chat_id = chat_id,
        .text = text,
        .link_preview_options = .{ .is_disabled = true },
    })) |response| {
        defer response.deinit();
        std.log.info("response: {s}", .{response.base.buf});
    } else |err| {
        std.log.warn("failed to send message: {}", .{err});
    }
}

fn getReply(
    allocator: std.mem.Allocator,
    text: []const u8,
) !?[]const u8 {
    // read openrouter api key.
    const openrouter_api_key = std.process.getEnvVarOwned(
        allocator,
        "OPENROUTER_API_KEY",
    ) catch |err| {
        std.debug.print("tip: please set 'OPENROUTER_API_KEY'\n", .{});
        return err;
    };
    defer allocator.free(openrouter_api_key);

    // initialize openrouter.
    var openrouter = OpenRouter.init(allocator, openrouter_api_key);
    defer openrouter.deinit();

    const reply = try openrouter.chatCompletion(.{
        .model = "deepseek/deepseek-r1:free",
        .messages = &.{
            .{
                .role = "system",
                .content = @embedFile("prompt.txt"),
            },
            .{
                .role = "user",
                .content = text,
            },
        },
    });
    defer reply.deinit();

    const reply_choices = reply.value.choices orelse {
        return null;
    };
    const reply_text = reply_choices[0].message.content orelse {
        return null;
    };

    std.log.info("reply text (length: {d}): {s}", .{ reply_text.len, reply_text });

    // let slice to owned.
    const owned_text = try allocator.dupe(u8, reply_text);

    return owned_text;
}

fn addUserInfo(
    allocator: std.mem.Allocator,
    optional_name: ?[]const u8,
    time: []const u8,
    text: []const u8,
) ![]const u8 {
    if (optional_name) |name| {
        return std.fmt.allocPrint(allocator, "[%% Name: {s} | Time: {s} %%] {s}", .{ name, time, text });
    } else {
        return std.fmt.allocPrint(allocator, "[%% Time: {s} %%] {s}", .{ time, text });
    }
}
