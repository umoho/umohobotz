const std = @import("std");

const Allocator = std.mem.Allocator;

pub const OpenRouter = struct {
    allocator: Allocator,
    client: Client,

    const Parsed = @import("client.zig").Parsed;

    const Client = @import("client.zig").Client;

    const requests = @import("requests.zig");
    const responses = @import("responses.zig");

    pub fn init(allocator: Allocator, api_key: []const u8) OpenRouter {
        return .{
            .allocator = allocator,
            .client = Client.init(allocator, api_key),
        };
    }

    pub fn deinit(self: *OpenRouter) void {
        self.client.deinit();
    }

    pub fn completion(
        self: *OpenRouter,
        request: requests.Completion,
    ) !Parsed(responses.Completion) {
        const response = try self.client.sendRequest(.completion, request);
        defer response.deinit();

        return response.to(responses.Completion, .{});
    }

    pub fn chatCompletion(
        self: *OpenRouter,
        request: requests.ChatCompletion,
    ) !Parsed(responses.ChatCompletion) {
        const response = try self.client.sendRequest(.chat_completion, request);
        defer response.deinit();

        return response.to(request, .{});
    }
};
