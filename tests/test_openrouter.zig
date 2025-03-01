const std = @import("std");

const OpenRouter = @import("src/openrouter/openrouter.zig").OpenRouter;

pub fn main() !void {
    // make allocator.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // read API key.
    const api_key = std.process.getEnvVarOwned(allocator, "OPENROUTER_API_KEY") catch {
        std.debug.print("tip: please set 'OPENROUTER_API_KEY'\n", .{});
        return;
    };
    defer allocator.free(api_key);

    // read question from env.
    const question = std.process.getEnvVarOwned(allocator, "QUESTION") catch {
        std.debug.print("tip: please set 'QUESTION'\n", .{});
        return;
    };
    defer allocator.free(question);

    var openrouter = OpenRouter.init(
        allocator,
        api_key,
    );
    defer openrouter.deinit();

    const response = try openrouter.chatCompletion(.{
        .model = "deepseek/deepseek-r1:free",
        .messages = &.{.{
            .role = "user",
            .content = question,
        }},
    });
    defer response.deinit();

    const choices = response.value.choices orelse {
        std.debug.print("error: no choices\n", .{});
        return;
    };
    const content = choices[0].message.content orelse {
        std.debug.print("error: no content\n", .{});
        return;
    };
    std.debug.print("{s}\n", .{content});
}
