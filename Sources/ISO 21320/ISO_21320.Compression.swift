// ISO_21320.Compression.swift

extension ISO_21320 {
    /// Compression-related types for ISO 21320-1.
    public enum Compression {}
}

extension ISO_21320.Compression {
    /// Compression methods allowed by ISO 21320-1.
    ///
    /// Per ISO 21320-1, only two compression methods are permitted:
    /// - stored (0): No compression
    /// - deflate (8): DEFLATE compression per RFC 1951
    public enum Method: UInt16, Sendable, Hashable {
        /// No compression (method 0).
        ///
        /// Data is stored as-is without any transformation.
        case stored = 0

        /// DEFLATE compression (method 8).
        ///
        /// Data is compressed using the DEFLATE algorithm defined in RFC 1951.
        case deflate = 8
    }
}
