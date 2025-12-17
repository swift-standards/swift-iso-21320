// ISO_21320.swift
//
// ISO/IEC 21320-1:2015 - Information technology — Document Container File — Part 1: Core
//
// This standard defines a restricted subset of the ZIP file format for use as a
// document container. It is used by EPUB, ODF (OpenDocument), and OOXML (Office Open XML).
//
// Key restrictions (per ISO 21320-1):
// - Compression: only stored (0) or deflate (8)
// - No encryption
// - No digital signatures
// - No multi-volume/segmented archives
// - No "patched data" features
//
// Reference: https://www.iso.org/standard/60101.html

public import Standards

/// ISO/IEC 21320-1 Document Container File format.
///
/// A restricted ZIP format subset designed for document interchange.
/// Used by EPUB 3, ODF, and OOXML formats.
///
/// ## Example
///
/// ```swift
/// var archive = ISO_21320.Archive()
/// archive.addFile(path: "mimetype", data: Array("application/epub+zip".utf8), compress: false)
/// archive.addFile(path: "META-INF/container.xml", data: containerXML)
/// archive.addFile(path: "EPUB/content.opf", data: packageDocument)
/// let bytes = archive.finalize()
/// ```
public enum ISO_21320 {}
