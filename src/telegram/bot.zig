const std = @import("std");

const Allocator = std.mem.Allocator;

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
    /// - Remember to call `deinit` after using the bot.
    pub fn invokeGet(self: *Bot, method: anytype) !Response {
        return self.client.invokeGet(method);
    }
};
