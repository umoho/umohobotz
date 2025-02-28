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

    /// Get updates from the Telegram Bot API.
    ///
    /// Note:
    ///
    /// - Remember to call `Response.deinit` after using.
    pub fn getUpdates(self: *Bot, method_struct: methods.GetUpdates) !Response {
        return self.client.invokePost(method_struct);
    }

    /// Get updates from the Telegram Bot API in a loop.
    pub fn getUpdatesLoop(
        self: *Bot,
        handleUpdate: fn (bot: *Bot, update: objects.Update) void,
    ) !void {
        var max_update_id: ?i64 = null;
        while (true) {
            // get updates from the server.
            const next: methods.GetUpdates = if (max_update_id) |id|
                .{ .offset = id + 1 }
            else
                .{};
            const response = try self.getUpdates(next);
            defer response.deinit();

            // parse the response.
            const parsed_object = response.toObject([]objects.Update, .{}) catch |err| {
                std.log.err("failed to parse object: {}", .{err});
                std.log.err("plain:\n{s}", .{response.base.buf});
                // skip this update by: increase the offset.
                // FIXME: it works ok if it's not the first time getting updates from the server,
                // but it doesn't work if it's the first time because the `max_update_id` is `null`.
                std.log.debug("max_update_id: {?}", .{max_update_id});
                if (max_update_id) |id| max_update_id = id + 1;
                continue;
            };
            defer parsed_object.deinit();
            const response_object = parsed_object.value;

            // print error if it is an error.
            if (!response_object.ok and response_object.description != null) {
                std.log.err(
                    "an error response from the server: {s}",
                    .{response_object.description.?},
                );
                continue;
            }

            // handle unread updates.
            const updates = response_object.result orelse continue;
            std.log.debug("I got {} update(s)", .{updates.len});
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
