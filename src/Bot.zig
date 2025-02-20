const std = @import("std");

const Allocator = std.mem.Allocator;
const Client = std.http.Client;
const Request = Client.Request;
const Uri = std.Uri;
const JsonParsed = std.json.Parsed;
const JsonValue = std.json.Value;

const ServerHeaderBuffer = [4096]u8;
const String = std.ArrayList(u8);

allocator: Allocator,
client: Client,
api_uri_prefix: []const u8,

const Bot = @This();

pub fn deinit(bot: *Bot) void {
    bot.client.deinit();
    // TODO: any other resource needs to free?
}

pub fn invoke(bot: *Bot, method: []const u8, content: anytype, comptime buf_len: usize) !ResponseBody {
    var content_str = String.init(bot.allocator);
    defer content_str.deinit();

    switch (@TypeOf(content)) {
        // TODO: support JSON value.
        JsonValue => try std.json.stringify(content, .{}, content_str.writer()),
        else => try content_str.appendSlice(@as([]const u8, content)),
    }

    const body = try bot.invokePlain(method, content_str.items, buf_len);
    errdefer body.deinit();

    return .{
        .allocator = bot.allocator,
        .buf = body,
    };
}

test "invoke" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var bot = Bot{
        .allocator = allocator,
        .client = .{ .allocator = allocator },
        .api_uri_prefix = "http://postman-echo.com/",
    };
    defer bot.deinit();

    const body = try bot.invoke("post", "", 8192);
    defer body.deinit();
    const paresd = try body.toJson();
    defer paresd.deinit();

    paresd.value.dump();
}

fn invokePlain(bot: *Bot, method: []const u8, content: []u8, comptime buf_len: usize) !String {
    const uri_str = try bot.makeUriString(method);
    defer uri_str.deinit();
    const uri = try Uri.parse(uri_str.items);

    var request = try bot.postContentToServer(uri, content);
    defer request.deinit();

    var buf: [buf_len]u8 = undefined;
    const bytes = try request.reader().readAll(&buf);
    std.log.debug("read {} bytes", .{bytes});

    var body = String.init(bot.allocator);
    errdefer body.deinit();
    try body.appendSlice(buf[0..bytes]);

    return body;
}

test "invoke plain" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var bot = Bot{
        .allocator = allocator,
        .client = .{ .allocator = allocator },
        .api_uri_prefix = "http://postman-echo.com/",
    };
    defer bot.deinit();

    const body = try bot.invokePlain("post", "", 8192);
    defer body.deinit();

    std.debug.print("body:\n{s}\n", .{body.items});
}

fn postContentToServer(bot: *Bot, uri: Uri, content: []u8) !Request {
    var header_buf: ServerHeaderBuffer = undefined;
    var request = try bot.client.open(.POST, uri, .{ .server_header_buffer = &header_buf });
    errdefer request.deinit();

    try request.send();
    if (content.len != 0) {
        try request.writer().writeAll(content);
    }
    try request.finish();
    try request.wait();

    return request;
}

test "write content to server" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var bot = Bot{
        .allocator = allocator,
        .client = .{ .allocator = allocator },
        .api_uri_prefix = "http://postman-echo.com/",
    };
    defer bot.deinit();

    const uri_str = try bot.makeUriString("post");
    defer uri_str.deinit();
    const uri = try Uri.parse(uri_str.items);

    var request = try bot.postContentToServer(uri, "");
    defer request.deinit();

    std.debug.print("status: {}\n", .{request.response.status});
}

/// Concat `api_uri_prefix` and `method`.
// TODO: implement an URI generation function.
fn makeUriString(bot: *Bot, method: []const u8) !String {
    var buffer = String.init(bot.allocator);
    errdefer buffer.deinit();

    try buffer.appendSlice(bot.api_uri_prefix);
    try buffer.appendSlice(method);

    std.log.debug("made URI '{s}'", .{buffer.items});

    return buffer;
}

test "make URI string" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var bot = Bot{
        .allocator = allocator,
        .client = .{ .allocator = allocator },
        .api_uri_prefix = "http://postman-echo.com/",
    };
    defer bot.deinit();

    const uri_str = try bot.makeUriString("post");
    defer uri_str.deinit();
    const uri = try Uri.parse(uri_str.items);

    std.debug.print("URI: '{}'\n", .{uri});
}

const ResponseBody = struct {
    allocator: Allocator,
    buf: String,

    pub fn toJson(self: @This()) !JsonParsed(JsonValue) {
        return std.json.parseFromSlice(JsonValue, self.allocator, self.buf.items, .{});
    }

    pub fn deinit(self: @This()) void {
        self.buf.deinit();
    }
};
