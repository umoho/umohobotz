const std = @import("std");

const Allocator = std.mem.Allocator;

pub const OpenRouter = struct {
    allocator: Allocator,
    client: Client,

    const Parsed = std.json.Parsed;

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

        return response.to(responses.Completion, .{
            // NOTE: ignore unknown fields, because the response field is not complete.
            .ignore_unknown_fields = true,
            // FIXME: if not set, segfault will happen when print the response.
            .allocate = .alloc_always,
        });
    }

    pub fn chatCompletion(
        self: *OpenRouter,
        request: requests.ChatCompletion,
    ) !Parsed(responses.ChatCompletion) {
        const response = try self.client.sendRequest(.chat_completion, request);
        defer response.deinit();

        return response.to(responses.ChatCompletion, .{
            // NOTE: ignore unknown fields, because the response field is not complete.
            .ignore_unknown_fields = true,
            // FIXME: if not set, segfault will happen when print the response.
            .allocate = .alloc_always,
        });
    }
};
