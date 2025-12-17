// ISO_21320.File.swift

extension ISO_21320 {
    /// File-related types for ISO 21320-1.
    public enum File {}
}

extension ISO_21320.File {
    /// A file entry in the archive.
    ///
    /// Represents metadata and data for a single file within the container.
    public struct Entry: Sendable {
        /// The file path within the archive (forward slashes).
        public var path: String

        /// The uncompressed file data.
        public var data: [UInt8]

        /// The compression method to use.
        public var compression: ISO_21320.Compression.Method

        /// Last modification time (MS-DOS format).
        public var modificationTime: UInt16

        /// Last modification date (MS-DOS format).
        public var modificationDate: UInt16

        public init(
            path: String,
            data: [UInt8],
            compression: ISO_21320.Compression.Method = .deflate,
            modificationTime: UInt16 = 0,
            modificationDate: UInt16 = 0x0021 // 1980-01-01
        ) {
            self.path = path
            self.data = data
            self.compression = compression
            self.modificationTime = modificationTime
            self.modificationDate = modificationDate
        }
    }
}
