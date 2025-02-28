const std = @import("std");

const Allocator = std.mem.Allocator;

/// Client for sending HTTPS requests to Telegram Bot API.
pub const Client = struct {
    base: BaseClient,
    api_uri_prefix: []const u8,

    const Uri = std.Uri;

    const BaseClient = @import("../http/client.zig").BaseClient;

    const query_string = @import("../url/query_string.zig");
    const url = @import("../url/url.zig");

    const server_header_buf_size = 4096;
    const response_buf_size = 1024 * 1024;

    /// Initialize the client.
    pub fn init(allocator: Allocator, token: []const u8) !Client {
        return Client{
            .base = .{
                .allocator = allocator,
                .client = .{ .allocator = allocator },
            },
            .api_uri_prefix = try urlPrefixWithToken(allocator, token),
        };
    }

    /// Deinitialize the client.
    pub fn deinit(self: *Client) void {
        self.base.allocator.free(self.api_uri_prefix);
        self.base.client.deinit();
    }

    /// Extract method name from type name
    fn getMethodName(method_name: []const u8) []const u8 {
        const last_dot_index = std.mem.lastIndexOf(u8, method_name, ".");
        return if (last_dot_index) |index|
            method_name[index + 1 ..]
        else
            method_name;
    }

    /// Send GET request to Telegram Bot API.
    ///
    /// Note:
    ///
    /// - Remember to free the returned slice using `Response.deinit`.
    pub fn invokeGet(self: *Client, method: anytype) !Response {
        const method_name = @typeName(@TypeOf(method));
        const last_name = getMethodName(method_name);
        const uri_str = try url.buildUrl(self.base.allocator, self.api_uri_prefix, last_name, method);
        defer self.base.allocator.free(uri_str);
        const uri = try Uri.parse(uri_str);

        var request = try self.base.requestGet(uri);
        defer request.deinit();

        const base_response = try self.base.readResponse(&request);
        return Response{ .base = base_response };
    }

    /// Send POST request to Telegram Bot API.
    ///
    /// Note:
    ///
    /// - Remember to free the returned slice using `Response.deinit`.
    pub fn invokePost(self: *Client, method: anytype) !Response {
        const method_name = @typeName(@TypeOf(method));
        const last_name = getMethodName(method_name);
        const uri_str = try url.buildUrl(self.base.allocator, self.api_uri_prefix, last_name, .{});
        defer self.base.allocator.free(uri_str);
        const uri = try Uri.parse(uri_str);

        var body_buf = std.ArrayList(u8).init(self.base.allocator);
        defer body_buf.deinit();
        try std.json.stringify(method, .{}, body_buf.writer());
        const body = body_buf.items;

        var request = try self.base.requestPost(uri, body);
        defer request.deinit();

        const base_response = try self.base.readResponse(&request);
        return Response{ .base = base_response };
    }
};

/// The server response.
pub const Response = struct {
    base: BaseResponse,

    const Parsed = std.json.Parsed;
    const Value = std.json.Value;
    const ParseOptions = std.json.ParseOptions;

    const BaseResponse = @import("../http/client.zig").Response;
    const Object = @import("objects.zig").Object;

    /// Parse the response to JSON `Value`.
    ///
    /// Note:
    ///
    /// - Remember to free the returned slice using `Response.deinit`.
    pub fn toJson(
        self: @This(),
        options: ParseOptions,
    ) !Parsed(Value) {
        return self.base.toJson(options);
    }

    /// Parse the response to `Object`.
    ///
    /// Note:
    ///
    /// - Remember to free the returned slice using `Response.deinit`.
    pub fn toObject(
        self: @This(),
        comptime T: type,
        options: ParseOptions,
    ) !Parsed(Object(T)) {
        return self.base.to(Object(T), options);
    }

    /// Deinitialize the response.
    pub fn deinit(self: @This()) void {
        self.base.deinit();
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
