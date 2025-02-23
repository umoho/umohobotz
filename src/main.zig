const std = @import("std");

const Bot = @import("root.zig").Bot;

const QueryString = @import("query_string.zig").QueryString;

pub fn main() !void {
    // make allocator.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // read bot token.
    const bot_token = std.process.getEnvVarOwned(allocator, "BOT_TOKEN") catch |err| {
        std.debug.print("tip: please set 'BOT_TOKEN'\n", .{});
        return err;
    };
    defer allocator.free(bot_token);

    // make API URI.
    var api_uri_prefix_concat = std.ArrayList(u8).init(allocator);
    defer api_uri_prefix_concat.deinit();
    try api_uri_prefix_concat.appendSlice("https://api.telegram.org/bot");
    try api_uri_prefix_concat.appendSlice(bot_token);
    try api_uri_prefix_concat.append('/');

    // init bot.
    var bot = Bot{
        .allocator = allocator,
        .client = .{ .allocator = allocator },
        .api_uri_prefix = api_uri_prefix_concat.items,
    };
    defer bot.deinit();

    var max_update_id: ?i64 = null;
    while (true) {
        // make GET query string.
        var query_string = QueryString.init(bot.allocator);
        defer query_string.deinit();

        if (max_update_id) |id| {
            const next_id = id + 1;

            // i64 to string.
            var offset_value_str = std.ArrayList(u8).init(bot.allocator);
            defer offset_value_str.deinit();
            try std.fmt.format(offset_value_str.writer(), "{}", .{next_id});

            try query_string.put("offset", offset_value_str.items);
        }

        // invoke API.
        const body = try bot.invokeOfGet("getUpdates", &query_string, 1024 * 1024);
        defer body.deinit();

        if (body.toResponseObject([]Bot.objects.Update)) |parsed_object| {
            // print as object.
            defer parsed_object.deinit();
            const object = parsed_object.value;
            std.debug.print("object:\n{}\n", .{object});

            // print error.
            if (!object.ok) {
                std.debug.print("server response an error:\n", .{});
                if (object.description) |description| {
                    std.debug.print("  description: {s}\n", .{description});
                }
                if (object.error_code) |error_code| {
                    std.debug.print("  error_code: {}\n", .{error_code});
                }
                if (object.parameters) |parameters| {
                    std.debug.print("  parameters:\n", .{});
                    if (parameters.migrate_to_chat_id) |migrate_to_chat_id| {
                        std.debug.print("    migrate_to_chat_id: {}\n", .{migrate_to_chat_id});
                    }
                    if (parameters.retry_after) |retry_after| {
                        std.debug.print("    retry_after: {}\n", .{retry_after});
                    }
                }
            }

            if (object.result) |updates| {
                std.debug.print("I got {} update(s)\n", .{updates.len});
                // find max update ID.
                for (updates) |update| {
                    if ((max_update_id == null) or (update.update_id > max_update_id.?)) {
                        max_update_id = update.update_id;
                    }
                }
                std.debug.print("the max update ID is {?}\n", .{max_update_id});
            }
        } else |parse_object_err| {
            std.debug.print("failed to parse object: {}\n", .{parse_object_err});
            if (body.toJson()) |parsed_json| {
                // print as json.
                defer parsed_json.deinit();
                std.debug.print("JSON:\n", .{});
                parsed_json.value.dump();
                std.debug.print("\n", .{});
            } else |parse_json_err| {
                std.debug.print("failed to parse JSON: {}\n", .{parse_json_err});
                // print as plain.
                std.debug.print("plain:\n{s}\n", .{body.buf.items});
            }
        }
    }
}
