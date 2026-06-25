// Declares DoChatStudio file types and provides helpers for managing application file folders.

import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var doChatStudio: UTType {
        UTType(importedAs: "org.example.dochatstudio.document")
    }
    static var doChatModel: UTType {
        UTType(importedAs: "org.example.dochatstudio.model")
    }
    static var doChat: UTType {
        UTType(importedAs: "org.example.dochatstudio.runtime")
    }
    static var GGMLUniversalFile: UTType {
        UTType(importedAs: "org.example.dochatstudio.gguf")
    }
    static var doChatConfig: UTType {
        UTType(importedAs: "org.example.dochatstudio.config")
    }
}

// MARK: - FileController

class FileController {

    /// The name of the subfolder inside the Documents directory.
    let folderName: String

    /// A shared instance of FileManager.
    let fileManager = FileManager.default

    /// Initialize with the name of the target folder (e.g. "x")
    init(folderName: String) {
        self.folderName = folderName
    }

    /// Returns the URL of the target folder in Documents.
    /// The folder is created if it does not already exist.
    private var folderURL: URL? {
        do {
            // Locate the Documents directory.
            let documentsURL = try fileManager.url(for: .documentDirectory,
                                                   in: .userDomainMask,
                                                   appropriateFor: nil,
                                                   create: true)
            // Append the folder name to Documents.
            let targetFolder = documentsURL.appendingPathComponent(folderName, isDirectory: true)

            // Create the folder if it doesn’t exist.
            if !fileManager.fileExists(atPath: targetFolder.path) {
                try fileManager.createDirectory(at: targetFolder,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            }
            return targetFolder
        } catch {
            print("Error accessing or creating folder \(folderName): \(error)")
            return nil
        }
    }

    // MARK: - A. Import (Validate & Copy) a File

    /// Validates that the source file exists and copies it into the target folder.
    /// - Parameter sourceURL: The URL of the file to import (may be non‑sandboxed).
    /// - Returns: The URL of the copied file in the sandbox, or `nil` if an error occurred.
    func importFile(from sourceURL: URL) -> URL? {
        // Ensure the target folder exists.
        guard let targetFolder = self.folderURL else {
            print("Target folder is not available.")
            return nil
        }

        // On iOS, if the source URL is from outside the sandbox, try to access it securely.
        #if os(iOS)
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        #endif

        // Validate that the source file exists.
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            print("Source file does not exist: \(sourceURL)")
            return nil
        }

        // Define the destination URL using the same file name.
        let destinationURL = targetFolder.appendingPathComponent(sourceURL.lastPathComponent)

        // Optionally, remove any existing file at the destination.
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.removeItem(at: destinationURL)
            } catch {
                print("Error removing existing file at destination: \(error)")
                return nil
            }
        }

        // Copy the file to the target folder.
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            print("Successfully imported file to: \(destinationURL)")
            return destinationURL
        } catch {
            print("Error copying file: \(error)")
            return nil
        }
    }

    // MARK: - B. Scan the Target Folder

    /// Scans the target folder and returns an array of file URLs.
    /// - Parameter fileType: An optional file extension (without the dot, e.g. "txt" or "png").
    ///                       If provided, only files with this extension will be returned.
    /// - Returns: An array of file URLs found in the target folder. Returns an empty array on error.
    func scanFolder(fileType: String? = nil) -> [URL] {
        guard let targetFolder = self.folderURL else {
            print("Target folder is not available.")
            return []
        }
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: targetFolder,
                                                               includingPropertiesForKeys: nil,
                                                               options: [])
            // If a fileType is provided and is not an empty string, filter the results.
            if let fileType = fileType, !fileType.isEmpty {
                return fileURLs.filter { $0.pathExtension.lowercased() == fileType.lowercased() }
            } else {
                return fileURLs
            }
        } catch {
            print("Error scanning folder \(targetFolder): \(error)")
            return []
        }
    }

    // MARK: - C. Retrieve a File URL by Name

    /// Returns a valid URL (non-optional) for a file with the given name in the target folder.
    /// Note: This does not verify that the file exists.
    /// - Parameter fileName: The name of the file.
    /// - Returns: The complete URL for the file in the target folder.
    func fileURL(for fileName: String) -> URL {
        guard let targetFolder = self.folderURL else {
            fatalError("Target folder \(folderName) is not available.")
        }
        return targetFolder.appendingPathComponent(fileName)
    }

    // MARK: - D. Rename a File

    /// Renames a file at the given URL to the new file name.
    /// - Parameters:
    ///   - fileURL: The current URL of the file.
    ///   - newName: The new name for the file (including extension).
    /// - Returns: The new URL if renaming is successful, or `nil` if an error occurred.
    func renameFile(at fileURL: URL, to newName: String) -> URL? {
        // Ensure the file exists.
        guard fileManager.fileExists(atPath: fileURL.path) else {
            print("File does not exist at \(fileURL)")
            return nil
        }
        // Create the new URL in the same directory with the new name.
        let newURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try fileManager.moveItem(at: fileURL, to: newURL)
            print("File renamed to: \(newURL)")
            return newURL
        } catch {
            print("Error renaming file from \(fileURL) to \(newURL): \(error)")
            return nil
        }
    }

    // MARK: - E. Get File Metadata

    /// Returns basic metadata for the file at the specified URL.
    /// - Parameter fileURL: The URL of the file.
    /// - Returns: A dictionary of file attributes if retrieval is successful, or `nil` if an error occurred.
    func metadata(for fileURL: URL) -> [FileAttributeKey: Any]? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            return attributes
        } catch {
            print("Error retrieving metadata for file at \(fileURL): \(error)")
            return nil
        }
    }
}
