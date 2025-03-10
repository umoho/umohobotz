/// Successful completion.
pub const Completion = struct {
    id: ?[]const u8 = null,
    choices: ?[]const struct {
        text: ?[]const u8 = null,
        index: ?i64 = null,
        finish_reason: ?[]const u8 = null,
    } = null,
};

pub const ChatCompletion = struct {
    id: ?[]const u8 = null,
    choices: ?[]const struct {
        message: struct {
            role: ?[]const u8 = null,
            content: ?[]const u8 = null,
        },
    } = null,
};
