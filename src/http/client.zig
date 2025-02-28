const std = @import("std");
const Allocator = std.mem.Allocator;

/// The base client.
pub const BaseClient = struct {
    /// The allocator used by myself, and client also use this allocator.
    allocator: Allocator,

    /// Client from `std.http`.
    client: StdClient,

    const Uri = std.Uri;
    const Request = std.http.Client.Request;
    const StdClient = std.http.Client;
    const Header = std.http.Header;

    const server_header_buf_size = 4096;
    const response_buf_size = 1024 * 1024;

    /// Read response from request and return owned buffer.
    ///
    /// Note:
    ///
    /// - Remember to free the returned value by `Response.deinit`.
    /// - Returned value should outlive the request.
    pub fn readResponse(self: *BaseClient, request: *Request) !Response {
        var response_buf: [response_buf_size]u8 = undefined;
        const read_size = try request.readAll(&response_buf);

        var result = try self.allocator.alloc(u8, read_size);
        @memcpy(result[0..read_size], response_buf[0..read_size]);
        errdefer self.allocator.free(result);

        return Response{
            .allocator = self.allocator,
            .buf = result,
        };
    }

    /// Send GET request to the server.
    ///
    /// Note:
    ///
    /// - Remember to free the returned value by `Request.deinit`.
    /// - Returned value should outlive the request.
    pub fn requestGet(self: *BaseClient, uri: Uri) !Request {
        var header_buf: [server_header_buf_size]u8 = undefined;
        var request = try self.client.open(.GET, uri, .{
            .server_header_buffer = &header_buf,
        });
        errdefer request.deinit();

        try request.send();
        try request.finish();
        try request.wait();

        return request;
    }

    /// Send POST request to the server.
    ///
    /// Note:
    ///
    /// - Remember to free the returned value by `Request.deinit`.
    /// - Returned value should outlive the request.
    pub fn requestPost(self: *BaseClient, uri: Uri, body: []const u8) !Request {
        var header_buf: [server_header_buf_size]u8 = undefined;
        var request = try self.client.open(.POST, uri, .{
            .server_header_buffer = &header_buf,
        });
        errdefer request.deinit();

        request.headers.content_type = .{ .override = "application/json" };
        request.transfer_encoding = .{ .content_length = body.len };

        try request.send();
        try request.writeAll(body);
        try request.finish();
        try request.wait();

        return request;
    }
};

/// The server response.
///
/// Note:
///
/// - Remember to free the returned value by `Response.deinit`.
pub const Response = struct {
    allocator: Allocator,
    buf: []u8,

    const parseFromSlice = std.json.parseFromSlice;
    const Parsed = std.json.Parsed;
    const Value = std.json.Value;
    const ParseOptions = std.json.ParseOptions;

    /// Parse the response to JSON value.
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
