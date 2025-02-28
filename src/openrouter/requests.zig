/// This endpoint expects an object.
pub const Completion = struct {
    /// The model ID to use.
    model: []const u8,
    /// The text prompt to complete.
    prompt: []const u8,
    /// Optional. Defaults to false.
    stream: ?bool = null,
};

/// Send a chat completion request to a selected model.
pub const ChatCompletion = struct {
    /// The model ID to use.
    model: []const u8,
    messages: []const struct {
        /// Allowed values: 'system', 'user', 'assistant'.
        // TODO: enum.
        role: []const u8,
        content: []const u8,
    },
    /// Optional. Defaults to false.
    stream: ?bool = null,
};
