const std = @import("std");

const Allocator = std.mem.Allocator;

const methods = @import("methods.zig");
const objects = @import("objects.zig");

const Client = @import("client.zig").Client;
const Response = @import("client.zig").Response;

/// Telegram Bot.
pub const Bot = struct {
    /// The allocator used by myself, and client also use this allocator.
    allocator: Allocator,

    /// The client for sending requests to the Telegram Bot API.
    client: Client,

    /// Initialize the bot.
    ///
    /// Note:
    ///
    /// - Remember to call `deinit` after using the bot.
    pub fn init(allocator: Allocator, token: []const u8) !Bot {
        return Bot{
            .allocator = allocator,
            .client = try Client.init(allocator, token),
        };
    }

    /// Deinitialize the bot.
    pub fn deinit(self: *Bot) void {
        self.client.deinit();
    }

    /// Invoke a method of the Telegram Bot API.
    ///
    /// Note:
    ///
    /// - Remember to call `Response.deinit` after using.
    pub fn invokeGet(self: *Bot, method_struct: anytype) !Response {
        return self.client.invokeGet(method_struct);
    }

    /// Get updates from the Telegram Bot API.
    ///
    /// Note:
    ///
    /// - Remember to call `Response.deinit` after using.
    pub fn getUpdates(self: *Bot, method_struct: methods.GetUpdates) !Response {
        return self.client.invokeGet(method_struct);
    }

    /// Get updates from the Telegram Bot API in a loop.
    pub fn getUpdatesLoop(
        self: *Bot,
        handleUpdate: fn (bot: *Bot, update: objects.Update) void,
    ) !void {
        var max_update_id: ?i64 = null;
        while (true) {
            const next = if (max_update_id) |id| .{ .offset = id + 1 } else .{};
            const response = try self.getUpdates(next);
            defer response.deinit();

            const parsed_object = response.toObject([]objects.Update, .{}) catch |err| {
                std.debug.print("failed to parse object: {}\n", .{err});
                std.debug.print("plain:\n{s}\n", .{response.buf});
                continue;
            };
            defer parsed_object.deinit();

            printObjectIfError([]objects.Update, parsed_object.value);

            const updates = parsed_object.value.result orelse continue;
            std.debug.print("I got {} update(s)\n", .{updates.len});

            for (updates) |update| {
                max_update_id = if (max_update_id) |id|
                    @max(id, update.update_id)
                else
                    update.update_id;

                handleUpdate(self, update);
            }
        }
    }
};

/// Print the error of the object if it is an error.
fn printObjectIfError(comptime T: type, object: objects.Object(T)) void {
    // print error.
    if (!object.ok) {
        std.debug.print("server response an error:\n", .{});
        if (object.description) |desc| {
            std.debug.print("  description: {s}\n", .{desc});
        }
        if (object.error_code) |err_code| {
            std.debug.print("  error_code: {}\n", .{err_code});
        }
        if (object.parameters) |params| {
            std.debug.print("  parameters:\n", .{});
            if (params.migrate_to_chat_id) |migrate| {
                std.debug.print("    migrate_to_chat_id: {}\n", .{migrate});
            }
            if (params.retry_after) |retry| {
                std.debug.print("    retry_after: {}\n", .{retry});
            }
        }
    }
}
