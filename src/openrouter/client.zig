const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Client = struct {
    allocator: Allocator,
    api_key: []const u8,
    client: StdClient,

    http_referer: ?[]const u8 = null,
    x_title: ?[]const u8 = null,

    const Uri = std.Uri;
    const Request = std.http.Client.Request;
    const StdClient = std.http.Client;
    const Header = std.http.Header;

    const requests = @import("requests.zig");
    const responses = @import("responses.zig");

    const server_header_buf_size = 4096;
    const response_buf_size = 1024 * 1024;

    /// Initialize the client.
    ///
    /// Note:
    ///
    /// - Remember to call `deinit` after using the client.
    pub fn init(allocator: std.mem.Allocator, api_key: []const u8) Client {
        return .{
            .allocator = allocator,
            .api_key = api_key,
            .client = std.http.Client.init(allocator),
        };
    }

    /// Deinitialize the client.
    pub fn deinit(self: *Client) void {
        self.client.deinit();
    }

    /// Send request to the server.
    ///
    /// Note:
    ///
    /// - Remember to free the returned slice using `Response.deinit`.
    pub fn sendRequest(self: *Client, method: Method, request: anytype) !Response {
        const uri = method.url;
        const body = try std.json.stringify(request, .{ .allocator = self.allocator });
        defer self.allocator.free(body);

        const returned_request = switch (method.method) {
            .POST => try self.requestPost(uri, body),
            else => unreachable, // TODO: implement GET.
        };

        return try self.readResponse(&returned_request);
    }

    /// Read response from request and return owned buffer.
    ///
    /// Note:
    ///
    /// - Remember to free the returned slice using `Response.deinit`.
    fn readResponse(self: *Client, request: *Request) !Response {
        var response_buf: [response_buf_size]u8 = undefined;
        const read_size = try request.readAll(&response_buf);

        // let buffer be owned.
        var result = try self.allocator.alloc(u8, read_size);
        @memcpy(result[0..read_size], response_buf[0..read_size]);
        errdefer self.allocator.free(result);

        return Response{
            .allocator = self.allocator,
            .buf = result,
        };
    }

    /// Send POST request to the server.
    ///
    /// Note:
    ///
    /// - Remember to call `request.deinit()` after using the request.
    fn requestPost(self: *Client, uri: Uri, body: []const u8) !Request {
        var header_buf: [server_header_buf_size]u8 = undefined;
        var request = try self.client.open(.POST, uri, .{
            .server_header_buffer = &header_buf,
        });
        errdefer request.deinit();

        // set content type to `application/json`.
        request.headers.content_type = .{ .override = "application/json" };

        // set authorization header.
        const auth_header = try self.setAuthorization(request);
        defer self.allocator.free(auth_header);

        // set rankings headers.
        const owned_headers = try self.setRankingsHeaders(request);
        defer self.allocator.free(owned_headers);

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
    /// - Remember to free the returned value by `self.allocator.free`.
    /// - Returned value should outlive the request.
    fn setAuthorization(self: *Client, request: *Request) ![]const u8 {
        const auth_header = try std.fmt.allocPrint(
            self.allocator,
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
    /// - Remember to free the returned value by `self.allocator.free`.
    /// - Returned value should outlive the request.
    fn setRankingsHeaders(self: *Client, request: *Request) ![]const Header {
        var header_list = std.ArrayList(Header).init(self.allocator);
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
    allocator: Allocator,
    buf: []u8,

    const parseFromSlice = std.json.parseFromSlice;
    const Parsed = std.json.Parsed;
    const Value = std.json.Value;
    const ParseOptions = std.json.ParseOptions;

    /// Parse the response to JSON `Value`.
    pub fn toJson(
        self: @This(),
        options: ParseOptions,
    ) !Parsed(Value) {
        return parseFromSlice(Value, self.allocator, self.buf, options);
    }

    /// Parse the response to `T`.
    pub fn to(
        self: @This(),
        comptime T: type,
        options: ParseOptions,
    ) !Parsed(T) {
        return parseFromSlice(T, self.allocator, self.buf, options);
    }

    /// Deinitialize the response.
    pub fn deinit(self: @This()) void {
        self.allocator.free(self.buf);
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
