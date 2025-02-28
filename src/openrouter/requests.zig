/// This endpoint expects an object.
pub const Completion = struct {
    /// The model ID to use.
    model: []const u8,
    /// The text prompt to complete.
    prompt: []const u8,
    /// Optional. Defaults to false.
    stream: ?bool = null,
};
