const std = @import("std");

const Allocator = std.mem.Allocator;
const Uri = std.Uri;
const Request = std.http.Client.Request;
const StdClient = std.http.Client;

const query_string = @import("../url/query_string.zig");
const url = @import("../url/url.zig");

const Object = @import("objects.zig").Object;

const server_header_buf_size = 4096;
const response_buf_size = 1024 * 1024;

/// Client for sending HTTPS requests to Telegram Bot API.
pub const Client = struct {
    /// The allocator used by myself, and client also use this allocator.
    allocator: Allocator,

    /// Client from `std.http`.
    client: StdClient,

    /// The prefix of the Telegram Bot API URI.
    api_uri_prefix: []const u8,

    /// Initialize the client.
    pub fn init(allocator: Allocator, token: []const u8) !Client {
        return Client{
            .allocator = allocator,
            .client = .{ .allocator = allocator },
            .api_uri_prefix = try urlPrefixWithToken(allocator, token),
        };
    }

    /// Deinitialize the client.
    pub fn deinit(self: *Client) void {
        self.allocator.free(self.api_uri_prefix);
        self.client.deinit();
    }

    /// Send GET request to Telegram Bot API.
    ///
    /// Note:
    ///
    /// - Remember to free the returned slice using `Response.deinit`.
    pub fn invokeGet(self: *Client, method: anytype) !Response {
        // build URI.
        const method_name = @typeName(@TypeOf(method));
        const uri_str = try url.buildUrl(self.allocator, self.api_uri_prefix, method_name, method);
        defer self.allocator.free(uri_str);
        const uri = try Uri.parse(uri_str);

        // send request.
        var request = try requestGet(&self.client, uri);
        defer request.deinit();

        // read response.
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
};

/// Send GET request to the server.
///
/// Note:
///
/// - Remember to call `request.deinit()` after using the request.
fn requestGet(client: *StdClient, uri: Uri) !Request {
    var header_buf: [4096]u8 = undefined;
    var request = try client.open(.GET, uri, .{
        .server_header_buffer = &header_buf,
    });
    errdefer request.deinit();

    try request.send();
    try request.finish();
    try request.wait();

    return request;
}

/// The server response.
///
/// Note:
///
/// - Remember to free the returned slice using my `deinit`.
/// - It's be created by `Client`.
const Response = struct {
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
        return parseFromSlice(Value, self.allocator, self.buf.items, options);
    }

    /// Parse the response to `Object`.
    pub fn toResponseObject(
        self: @This(),
        comptime T: type,
        options: ParseOptions,
    ) !Parsed(Object(T)) {
        return parseFromSlice(Object(T), self.allocator, self.buf.items, options);
    }

    /// Deinitialize the response.
    pub fn deinit(self: @This()) void {
        self.allocator.free(self.buf);
    }
};

/// Build the URL prefix with the token.
///
/// Note:
///
/// - Remember to free the returned slice using `allocator.free`.
fn urlPrefixWithToken(allocator: Allocator, token: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    try result.appendSlice("https://api.telegram.org/bot");
    try result.appendSlice(token);
    try result.append('/');

    return result.toOwnedSlice();
}
