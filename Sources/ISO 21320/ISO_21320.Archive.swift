// ISO_21320.Archive.swift
//
// ZIP archive writer conforming to ISO/IEC 21320-1.

public import RFC_1951

extension ISO_21320 {
    /// A document container archive (ZIP) writer.
    ///
    /// Creates ZIP archives conforming to ISO/IEC 21320-1 restrictions:
    /// - Only stored or deflate compression
    /// - No encryption
    /// - No digital signatures
    /// - Single-volume only
    ///
    /// ## Example
    ///
    /// ```swift
    /// var archive = ISO_21320.Archive()
    /// archive.add(path: "mimetype", data: Array("application/epub+zip".utf8), compress: false)
    /// archive.add(path: "content.xml", data: contentData)
    /// let bytes = archive.finalize()
    /// ```
    public struct Archive: Sendable {
        /// Files added to the archive.
        private var entries: [Entry]

        /// Creates an empty archive.
        public init() {
            self.entries = []
        }

        /// Add a file to the archive.
        ///
        /// - Parameters:
        ///   - path: The file path within the archive (use forward slashes).
        ///   - data: The file data.
        ///   - compress: Whether to use DEFLATE compression. Default is true.
        public mutating func add(
            path: String,
            data: [UInt8],
            compress: Bool = true
        ) {
            let entry = Entry(
                path: path,
                uncompressedData: data,
                compress: compress
            )
            entries.append(entry)
        }

        /// Add a file with string content.
        ///
        /// - Parameters:
        ///   - path: The file path within the archive.
        ///   - content: The string content (UTF-8 encoded).
        ///   - compress: Whether to use DEFLATE compression. Default is true.
        public mutating func add(
            path: String,
            content: String,
            compress: Bool = true
        ) {
            add(path: path, data: Array(content.utf8), compress: compress)
        }

        /// Finalize the archive and return the ZIP file bytes.
        ///
        /// After calling this method, the archive is consumed.
        ///
        /// - Returns: The complete ZIP file as bytes.
        public consuming func finalize() -> [UInt8] {
            var output: [UInt8] = []
            var centralDirectory: [UInt8] = []
            var offsets: [UInt32] = []

            // Write local file headers and data
            for entry in entries {
                offsets.append(UInt32(output.count))
                entry.writeLocalHeader(to: &output)
                output.append(contentsOf: entry.compressedData)
            }

            // Record central directory start
            let centralDirectoryOffset = UInt32(output.count)

            // Write central directory
            for (index, entry) in entries.enumerated() {
                entry.writeCentralHeader(localOffset: offsets[index], to: &centralDirectory)
            }
            output.append(contentsOf: centralDirectory)

            // Write end of central directory
            writeEndOfCentralDirectory(
                entryCount: UInt16(entries.count),
                centralDirectorySize: UInt32(centralDirectory.count),
                centralDirectoryOffset: centralDirectoryOffset,
                to: &output
            )

            return output
        }
    }
}

// MARK: - Internal Entry

extension ISO_21320.Archive {
    /// Internal entry with pre-computed compressed data.
    struct Entry: Sendable {
        let path: String
        let uncompressedData: [UInt8]
        let compressedData: [UInt8]
        let compressionMethod: ISO_21320.Compression.Method
        let crc32: UInt32
        let modificationTime: UInt16
        let modificationDate: UInt16

        init(path: String, uncompressedData: [UInt8], compress: Bool) {
            self.path = path
            self.uncompressedData = uncompressedData
            self.crc32 = ISO_21320.CRC.`32`.checksum(uncompressedData)

            // Use current-ish date: 1980-01-01 00:00:00 (minimum DOS date)
            self.modificationTime = 0
            self.modificationDate = 0x0021

            if compress && !uncompressedData.isEmpty {
                let deflated = RFC_1951.compress(uncompressedData, level: .balanced)
                // Only use compression if it actually saves space
                if deflated.count < uncompressedData.count {
                    self.compressedData = deflated
                    self.compressionMethod = .deflate
                } else {
                    self.compressedData = uncompressedData
                    self.compressionMethod = .stored
                }
            } else {
                self.compressedData = uncompressedData
                self.compressionMethod = .stored
            }
        }

        func writeLocalHeader(to output: inout [UInt8]) {
            let pathBytes = Array(path.utf8)

            // Local file header signature
            output.append(contentsOf: [0x50, 0x4B, 0x03, 0x04])

            // Version needed to extract (2.0 for deflate)
            writeUInt16(compressionMethod == .deflate ? 20 : 10, to: &output)

            // General purpose bit flag
            writeUInt16(0, to: &output)

            // Compression method
            writeUInt16(compressionMethod.rawValue, to: &output)

            // Last mod file time
            writeUInt16(modificationTime, to: &output)

            // Last mod file date
            writeUInt16(modificationDate, to: &output)

            // CRC-32
            writeUInt32(crc32, to: &output)

            // Compressed size
            writeUInt32(UInt32(compressedData.count), to: &output)

            // Uncompressed size
            writeUInt32(UInt32(uncompressedData.count), to: &output)

            // File name length
            writeUInt16(UInt16(pathBytes.count), to: &output)

            // Extra field length
            writeUInt16(0, to: &output)

            // File name
            output.append(contentsOf: pathBytes)
        }

        func writeCentralHeader(localOffset: UInt32, to output: inout [UInt8]) {
            let pathBytes = Array(path.utf8)

            // Central file header signature
            output.append(contentsOf: [0x50, 0x4B, 0x01, 0x02])

            // Version made by (Unix, 2.0)
            writeUInt16(0x031E, to: &output)

            // Version needed to extract
            writeUInt16(compressionMethod == .deflate ? 20 : 10, to: &output)

            // General purpose bit flag
            writeUInt16(0, to: &output)

            // Compression method
            writeUInt16(compressionMethod.rawValue, to: &output)

            // Last mod file time
            writeUInt16(modificationTime, to: &output)

            // Last mod file date
            writeUInt16(modificationDate, to: &output)

            // CRC-32
            writeUInt32(crc32, to: &output)

            // Compressed size
            writeUInt32(UInt32(compressedData.count), to: &output)

            // Uncompressed size
            writeUInt32(UInt32(uncompressedData.count), to: &output)

            // File name length
            writeUInt16(UInt16(pathBytes.count), to: &output)

            // Extra field length
            writeUInt16(0, to: &output)

            // File comment length
            writeUInt16(0, to: &output)

            // Disk number start
            writeUInt16(0, to: &output)

            // Internal file attributes
            writeUInt16(0, to: &output)

            // External file attributes (Unix regular file, 0644)
            writeUInt32(0x81A40000, to: &output)

            // Relative offset of local header
            writeUInt32(localOffset, to: &output)

            // File name
            output.append(contentsOf: pathBytes)
        }
    }
}

// MARK: - End of Central Directory

extension ISO_21320.Archive {
    func writeEndOfCentralDirectory(
        entryCount: UInt16,
        centralDirectorySize: UInt32,
        centralDirectoryOffset: UInt32,
        to output: inout [UInt8]
    ) {
        // End of central directory signature
        output.append(contentsOf: [0x50, 0x4B, 0x05, 0x06])

        // Number of this disk
        writeUInt16(0, to: &output)

        // Disk where central directory starts
        writeUInt16(0, to: &output)

        // Number of central directory records on this disk
        writeUInt16(entryCount, to: &output)

        // Total number of central directory records
        writeUInt16(entryCount, to: &output)

        // Size of central directory
        writeUInt32(centralDirectorySize, to: &output)

        // Offset of start of central directory
        writeUInt32(centralDirectoryOffset, to: &output)

        // ZIP file comment length
        writeUInt16(0, to: &output)
    }
}

// MARK: - Binary Helpers

private func writeUInt16(_ value: UInt16, to output: inout [UInt8]) {
    output.append(UInt8(value & 0xFF))
    output.append(UInt8((value >> 8) & 0xFF))
}

private func writeUInt32(_ value: UInt32, to output: inout [UInt8]) {
    output.append(UInt8(value & 0xFF))
    output.append(UInt8((value >> 8) & 0xFF))
    output.append(UInt8((value >> 16) & 0xFF))
    output.append(UInt8((value >> 24) & 0xFF))
}
