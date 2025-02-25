// TODO: let's generate structs by a script.
// TODO: let buildQueryString ignore null fields.
// TODO: find out a good way to get the method name. (and return type)

pub const Name = union(enum) {
    /// See https://core.telegram.org/bots/api#getupdates.
    getUpdates,
    /// See https://core.telegram.org/bots/api#getme.
    getMe,
    /// See https://core.telegram.org/bots/api#logout.
    logOut,
    /// See https://core.telegram.org/bots/api#close.
    close,
    /// See https://core.telegram.org/bots/api#sendmessage.
    sendMessage,

    string_literal: []const u8,
};

/// See https://core.telegram.org/bots/api#getupdates.
pub const GetUpdates = struct {
    offset: ?i64 = null,
    limit: ?i64 = null,
    timeout: ?i64 = null,
    allowed_updates: ?[][]const u8 = null,
};

/// See https://core.telegram.org/bots/api#sendmessage.
pub const SendMessage = struct {
    // business_connection_id: ?[]const u8 = null,
    // chat_id: union { integer: i64, string: []const u8 },
    chat_id: i64,
    // message_thread_id: ?i64 = null,
    text: []const u8,
    // parse_mode: ?[]const u8 = null,
    // entities: ?[]void = null, // TODO: actual type 'MessageEntity'.
    // link_preview_options: ?void = null, // TODO: actual type 'LinkPreviewOptions'.
    // disable_notification: ?bool = null,
    // protect_connect: ?bool = null,
    // allow_paid_broadcast: ?bool = null,
    // message_effect_id: ?[]const u8 = null,
    // reply_parameters: ?[]void = null, // TODO: actual type 'ReplyParameters'.
    // reply_markup: ?union {
    //     inline_keyboard_markup: void,
    //     reply_keyboard_markup: void,
    //     reply_keyboard_remove: void,
    //     force_reply: void,
    // } = null,
};
