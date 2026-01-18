import Testing
@testable import ISO_21320

@Suite("ISO 21320 Tests")
struct ISO_21320_Tests {
    @Test("CRC-32 checksum")
    func crc32Checksum() {
        // Known test vector: "123456789" -> 0xCBF43926
        let data = Array("123456789".utf8)
        let crc = ISO_21320.CRC.`32`.checksum(data)
        #expect(crc == 0xCBF43926)
    }

    @Test("Empty archive")
    func emptyArchive() {
        var archive = ISO_21320.Archive()
        let bytes = archive.finalize()

        // Should have end of central directory at minimum
        #expect(bytes.count >= 22)
        // ZIP signature
        #expect(bytes[0] == 0x50)
        #expect(bytes[1] == 0x4B)
    }

    @Test("Archive with stored file")
    func archiveWithStoredFile() {
        var archive = ISO_21320.Archive()
        archive.add(path: "test.txt", content: "Hello", compress: false)
        let bytes = archive.finalize()

        // Should have local header + data + central directory + EOCD
        #expect(bytes.count > 22)
        // ZIP signature for local file header
        #expect(bytes[0] == 0x50)
        #expect(bytes[1] == 0x4B)
        #expect(bytes[2] == 0x03)
        #expect(bytes[3] == 0x04)
    }

    @Test("Archive with compressed file")
    func archiveWithCompressedFile() {
        var archive = ISO_21320.Archive()
        // Use repetitive data that compresses well
        let content = String(repeating: "Hello World! ", count: 100)
        archive.add(path: "test.txt", content: content, compress: true)
        let bytes = archive.finalize()

        // Should compress significantly
        #expect(bytes.count < content.utf8.count)
    }

    @Test("EPUB mimetype first")
    func epubMimetypeFirst() {
        var archive = ISO_21320.Archive()
        archive.add(path: "mimetype", content: "application/epub+zip", compress: false)
        archive.add(path: "META-INF/container.xml", content: "<xml/>", compress: true)
        let bytes = archive.finalize()

        // mimetype should be stored uncompressed as first entry
        // Compression method at offset 8-9 should be 0 (stored)
        #expect(bytes[8] == 0x00)
        #expect(bytes[9] == 0x00)
    }
}
