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
    offset: ?i64,
    limit: ?i64,
    timeout: ?i64,
    allowed_updates: ?[][]u8,
};

/// See https://core.telegram.org/bots/api#sendmessage.
pub const SendMessage = struct {
    business_connection_id: ?[]u8,
    chat_id: union { integer: i64, string: []u8 },
    message_thread_id: ?i64,
    text: []u8,
    parse_mode: ?[]u8,
    entities: ?[]void, // TODO: actual type 'MessageEntity'.
    link_preview_options: ?void, // TODO: actual type 'LinkPreviewOptions'.
    disable_notification: ?bool,
    protect_connect: ?bool,
    allow_paid_broadcast: ?bool,
    message_effect_id: ?[]u8,
    reply_parameters: ?[]void, // TODO: actual type 'ReplyParameters'.
    reply_markup: ?union {
        inline_keyboard_markup: void,
        reply_keyboard_markup: void,
        reply_keyboard_remove: void,
        force_reply: void,
    } = null,
};
