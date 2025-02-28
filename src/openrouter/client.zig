const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Client = struct {
    base: BaseClient,
    api_key: []const u8,

    http_referer: ?[]const u8 = null,
    x_title: ?[]const u8 = null,

    const Uri = std.Uri;
    const Request = std.http.Client.Request;
    const StdClient = std.http.Client;
    const Header = std.http.Header;

    const BaseClient = @import("../http/client.zig").BaseClient;

    const requests = @import("requests.zig");
    const responses = @import("responses.zig");

    const server_header_buf_size = 4096;

    /// Initialize the client.
    ///
    /// Note:
    ///
    /// - Remember to call `deinit` after using the client.
    pub fn init(allocator: std.mem.Allocator, api_key: []const u8) Client {
        return .{
            .base = .{
                .allocator = allocator,
                .client = StdClient.init(allocator),
            },
            .api_key = api_key,
        };
    }

    /// Deinitialize the client.
    pub fn deinit(self: *Client) void {
        self.base.client.deinit();
    }

    /// Send request to the server.
    ///
    /// Note:
    ///
    /// - Remember to free the returned slice using `Response.deinit`.
    pub fn sendRequest(self: *Client, method: Method, request: anytype) !Response {
        const uri = method.url;
        const body = try std.json.stringify(request, .{ .allocator = self.base.allocator });
        defer self.base.allocator.free(body);

        const returned_request = switch (method.method) {
            .POST => try self.base.requestPost(uri, body),
            else => unreachable, // TODO: implement GET.
        };

        return try self.base.readResponse(&returned_request);
    }

    /// Send POST request to the server.
    ///
    /// Note:
    ///
    /// - Remember to free the returned value by `Request.deinit`.
    /// - Returned value should outlive the request.
    pub fn requestPost(self: *Client, uri: Uri, body: []const u8) !Request {
        var header_buf: [server_header_buf_size]u8 = undefined;
        var request = try self.base.client.open(.POST, uri, .{
            .server_header_buffer = &header_buf,
        });
        errdefer request.deinit();

        // set content type to `application/json`.
        request.headers.content_type = .{ .override = "application/json" };

        // set authorization header.
        const auth_header = try self.setAuthorization(request);
        defer self.base.allocator.free(auth_header);

        // set rankings headers.
        const owned_headers = try self.setRankingsHeaders(request);
        defer self.base.allocator.free(owned_headers);

        // `request.writeAll` will use this.
        request.transfer_encoding = .{ .content_length = body.len };

        try request.send();
        try request.writeAll(body);
        try request.finish();
        try request.wait();

        return request;
    }

    /// Set authorization header.
    ///
    /// Note:
    ///
    /// - Remember to free the returned value by `self.base.allocator.free`.
    /// - Returned value should outlive the request.
    fn setAuthorization(self: *Client, request: *Request) ![]const u8 {
        const auth_header = try std.fmt.allocPrint(
            self.base.allocator,
            "Bearer {}",
            .{self.api_key},
        );

        request.headers.authorization = .{ .override = auth_header };

        return auth_header;
    }

    /// Set rankings headers.
    ///
    /// Note:
    ///
    /// - Remember to free the returned value by `self.base.allocator.free`.
    /// - Returned value should outlive the request.
    fn setRankingsHeaders(self: *Client, request: *Request) ![]const Header {
        var header_list = std.ArrayList(Header).init(self.base.allocator);
        defer header_list.deinit();

        if (self.http_referer) |referer| {
            try header_list.append(.{ .name = "HTTP-Referer", .value = referer });
        }
        if (self.x_title) |title| {
            try header_list.append(.{ .name = "X-Title", .value = title });
        }

        const owned_headers = header_list.toOwnedSlice();
        request.extra_headers = owned_headers;

        return owned_headers;
    }
};

/// The server response.
///
/// Note:
///
/// - Remember to free the returned slice using my `deinit`.
/// - It's be created by `Client`.
pub const Response = struct {
    base: BaseResponse,

    const Parsed = std.json.Parsed;
    const Value = std.json.Value;
    const ParseOptions = std.json.ParseOptions;

    const BaseResponse = @import("../http/client.zig").Response;

    /// Parse the response to JSON `Value`.
    pub fn toJson(
        self: @This(),
        options: ParseOptions,
    ) !Parsed(Value) {
        return self.base.toJson(options);
    }

    /// Parse the response to `T`.
    pub fn to(
        self: @This(),
        comptime T: type,
        options: ParseOptions,
    ) !Parsed(T) {
        return self.base.to(T, options);
    }

    /// Deinitialize the response.
    pub fn deinit(self: @This()) void {
        self.base.deinit();
    }
};

const Method = enum(struct {
    method: std.http.Method,
    url: []const u8,
}) {
    completion = .{
        .method = .POST,
        .url = "https://openrouter.ai/api/v1/completions",
    },
    chat_completion = .{
        .method = .POST,
        .url = "https://openrouter.ai/api/v1/chat/completions",
    },
};
