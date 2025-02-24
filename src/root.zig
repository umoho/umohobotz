pub const telegram = struct {
    pub const bot = @import("telegram/bot.zig");
    pub const client = @import("telegram/client.zig");
    pub const objects = @import("telegram/objects.zig");
};

pub const url = struct {
    pub const query_string = @import("url/query_string.zig");
    pub const url = @import("url/url.zig");
};
