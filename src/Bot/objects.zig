// TODO: JsonValue should be replace by the actual types.
const JsonValue = @import("std").json.Value;

// TODO: should we write `@TypeOf(true)` to replace there bool,
//       if the API document says that its type is 'True'?

// TODO: maybe we should develop a program to generate these types.

pub const Update = struct {
    // TODO: replace these JsonValue.
    update_id: i32,
    message: ?Message = null,
    edited_message: ?Message = null,
    channel_post: ?Message = null,
    edited_channel_post: ?Message = null,
    business_connection: ?JsonValue,
    business_message: ?Message = null,
    edited_business_message: ?Message = null,
    deleted_business_message: ?JsonValue = null,
    message_reaction: ?JsonValue = null,
    message_reaction_count: ?JsonValue = null,
    inline_query: ?JsonValue = null,
    chosen_inline_result: ?JsonValue = null,
    callback_query: ?JsonValue = null,
    shipping_query: ?JsonValue = null,
    pre_checkout_query: ?JsonValue = null,
    purchased_paid_media: ?JsonValue = null,
    poll: ?JsonValue = null,
    poll_answer: ?JsonValue = null,
    my_chat_member: ?JsonValue = null,
    chat_member: ?JsonValue = null,
    chat_join_request: ?JsonValue = null,
    chat_boost: ?JsonValue = null,
    removed_chat_boost: ?JsonValue = null,
};

pub const Message = struct {
    // TODO: replace these JsonValue.
    message_id: i32,
    message_thread_id: ?i32 = null,
    from: ?User = null,
    sender_chat: ?Chat = null,
    sender_boost_count: ?i32 = null,
    sender_business_bot: ?User = null,
    date: u32,
    business_connection_id: ?[]u8 = null,
    chat: Chat,
    forward_origin: ?JsonValue = null,
    is_topic_message: ?bool = null,
    is_automatic_forward: ?bool = null,
    reply_to_message: ?Message = null,
    external_reply: ?JsonValue = null,
    quote: ?JsonValue = null,
    reply_to_story: ?JsonValue = null,
    via_bot: ?User = null,
    edit_date: ?i32 = null, // Unix time.
    has_protected_content: ?@TypeOf(true) = null,
    is_from_offline: ?@TypeOf(true) = null,
    media_group_id: ?[]u8 = null,
    author_signature: ?[]u8 = null,
    text: ?[]u8 = null,
    entities: ?[]JsonValue = null,
    link_preview_options: ?JsonValue = null,
    effect_id: ?[]u8 = null,
    animation: ?JsonValue = null,
    audio: ?JsonValue = null,
    document: ?JsonValue = null,
    paid_media: ?JsonValue = null,
    photo: ?[]JsonValue = null,
    /// Optional. Message is a sticker, information about the sticker
    sticker: ?JsonValue = null,
    /// Optional. Message is a forwarded story
    story: ?JsonValue = null,
    /// Optional. Message is a video, information about the video
    video: ?JsonValue = null,
    /// Optional. Message is a video note, information about the video message
    video_note: ?JsonValue = null,
    /// Optional. Message is a voice message, information about the file
    voice: ?JsonValue = null,
    /// Optional. Caption for the animation, audio, document, paid media, photo, video or voice
    caption: ?[]u8 = null,
    /// Optional. For messages with a caption, special entities like usernames, URLs, bot commands, etc. that appear in the caption
    caption_entities: ?[]JsonValue = null,
    /// Optional. True, if the caption must be shown above the message media
    show_caption_above_media: ?@TypeOf(true) = null,
    /// Optional. True, if the message media is covered by a spoiler animation
    has_media_spoiler: ?@TypeOf(true) = null,
    /// Optional. Message is a shared contact, information about the contact
    contact: ?JsonValue = null,
    /// Optional. Message is a dice with random value
    dice: ?JsonValue = null,
    /// Optional. Message is a game, information about the game. More about games »
    game: ?JsonValue = null,
    /// Optional. Message is a native poll, information about the poll
    poll: ?JsonValue = null,
    /// Optional. Message is a venue, information about the venue. For backward compatibility, when this field is set, the location field will also be set
    venue: ?JsonValue = null,
    /// Optional. Message is a shared location, information about the location
    location: ?JsonValue = null,
    /// Optional. New members that were added to the group or supergroup and information about them (the bot itself may be one of these members)
    new_chat_members: ?[]User = null,
    /// Optional. A member was removed from the group, information about them (this member may be the bot itself)
    left_chat_member: ?User = null,
    /// Optional. A chat title was changed to this value
    new_chat_title: ?[]u8 = null,
    /// Optional. A chat photo was change to this value
    new_chat_photo: ?[]JsonValue = null,
    /// Optional. Service message: the chat photo was deleted
    delete_chat_photo: ?@TypeOf(true) = null,
    /// Optional. Service message: the group has been created
    group_chat_created: ?@TypeOf(true) = null,
    /// Optional. Service message: the supergroup has been created. This field can't be received in a message coming through updates, because bot can't be a member of a supergroup when it is created. It can only be found in reply_to_message if someone replies to a very first message in a directly created supergroup.
    supergroup_chat_created: ?@TypeOf(true) = null,
    /// Optional. Service message: the channel has been created. This field can't be received in a message coming through updates, because bot can't be a member of a channel when it is created. It can only be found in reply_to_message if someone replies to a very first message in a channel.
    channel_chat_created: ?@TypeOf(true) = null,
    /// Optional. Service message: auto-delete timer settings changed in the chat
    message_auto_delete_timer_changed: ?JsonValue = null,
    /// Optional. The group has been migrated to a supergroup with the specified identifier. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this identifier.
    migrate_to_chat_id: ?i64 = null,
    /// Optional. The supergroup has been migrated from a group with the specified identifier. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this identifier.
    migrate_from_chat_id: ?i64 = null,
    /// Optional. Specified message was pinned. Note that the Message object in this field will not contain further reply_to_message fields even if it itself is a reply.
    pinned_message: ?JsonValue = null,
    /// Optional. Message is an invoice for a payment, information about the invoice. More about payments »
    invoice: ?JsonValue = null,
    /// Optional. Message is a service message about a successful payment, information about the payment. More about payments »
    successful_payment: ?JsonValue = null,
    /// Optional. Message is a service message about a refunded payment, information about the payment. More about payments »
    refunded_payment: ?JsonValue = null,
    /// Optional. Service message: users were shared with the bot
    users_shared: ?JsonValue = null,
    /// Optional. Service message: a chat was shared with the bot
    chat_shared: ?JsonValue = null,
    /// Optional. The domain name of the website on which the user has logged in. More about Telegram Login »
    connected_website: ?[]u8 = null,
    /// Optional. Service message: the user allowed the bot to write messages after adding it to the attachment or side menu, launching a Web App from a link, or accepting an explicit request from a Web App sent by the method requestWriteAccess
    write_access_allowed: ?JsonValue = null,
    /// Optional. Telegram Passport data
    passport_data: ?JsonValue = null,
    /// Optional. Service message. A user in the chat triggered another user's proximity alert while sharing Live Location.
    proximity_alert_triggered: ?JsonValue = null,
    /// Optional. Service message: user boosted the chat.
    boost_added: ?JsonValue = null,
    /// Optional. Service message: chat background set
    chat_background_set: ?JsonValue = null,
    /// Optional. Service message: forum topic created
    forum_topic_created: ?JsonValue = null,
    /// Optional. Service message: forum topic edited
    forum_topic_edited: ?JsonValue = null,
    /// Optional. Service message: forum topic closed
    forum_topic_closed: ?JsonValue = null,
    /// Optional. Service message: forum topic reopened
    forum_topic_reopened: ?JsonValue = null,
    /// Optional. Service message: the 'General' forum topic hidden
    general_forum_topic_hidden: ?JsonValue = null,
    /// Optional. Service message: the 'General' forum topic unhidden
    general_forum_topic_unhidden: ?JsonValue = null,
    /// Optional. Service message: a scheduled giveaway was created
    giveaway_created: ?JsonValue = null,
    /// Optional. The message is a scheduled giveaway message
    giveaway: ?JsonValue = null,
    /// Optional. A giveaway with public winners was completed
    giveaway_winners: ?JsonValue = null,
    /// Optional. Service message: a giveaway without public winners was completed
    giveaway_completed: ?JsonValue = null,
    /// Optional. Service message: video chat scheduled
    video_chat_scheduled: ?JsonValue = null,
    /// Optional. Service message: video chat started.
    video_chat_started: ?JsonValue = null,
    /// Optional. Service message: video chat ended
    video_chat_ended: ?JsonValue = null,
    /// Optional. Service message: new participants invited to a video chat
    video_chat_participants_invited: ?JsonValue = null,
    /// Optional. Service message: data sent by a Web App
    web_app_data: ?JsonValue = null,
    /// Optional. Inline keyboard attached to the message. login_url buttons are represented as ordinary url buttons.
    reply_markup: ?JsonValue = null,
};

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
