/// See https://core.telegram.org/bots/api#user.
pub const User = struct {
    id: i64,
    is_bot: bool,
    first_name: []u8,
    last_name: ?[]u8 = null,
    username: ?[]u8 = null,
    language_code: ?[]u8 = null,
    is_premium: ?bool = null,
    added_to_attachment_menu: ?bool = null,
    can_join_groups: ?bool = null,
    can_read_all_group_messages: ?bool = null,
    supports_inline_queries: ?bool = null,
    can_connect_to_business: ?bool = null,
    has_main_web_app: ?bool = null,
};

/// See https://core.telegram.org/bots/api#chat.
pub const Chat = struct {
    id: i64,
    type: []u8,
    title: ?[]u8 = null,
    username: ?[]u8 = null,
    first_name: ?[]u8 = null,
    last_name: ?[]u8 = null,
    is_forum: ?bool = null,
};

/// See https://core.telegram.org/bots/api#responseparameters.
pub const ResponseParameters = struct {
    migrate_to_chat_id: i64,
    retry_after: i32,
};
