import Foundation
import Postbox
import SwiftSignalKit
import TelegramCore

/// Local-only archive of deleted and edited messages (TrollGram Anti-Delete /
/// Edit History).
///
/// Everything is written as JSON under `Documents/TrollArchive/`. Nothing is
/// ever sent to the server and the archive survives app restarts.
public final class TrollMessageArchive {
    public static let shared = TrollMessageArchive()

    public struct Entry: Codable {
        public let peerId: Int64
        public let messageId: Int32
        public let date: Int32
        public let authorId: Int64?
        public let text: String
        public let kind: String
        public let savedAt: Int32
    }

    private let queue = DispatchQueue(label: "app.trollgram.ios.archive")
    private let fileURL: URL

    private init() {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
        let directory = documents + "/TrollArchive"
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        self.fileURL = URL(fileURLWithPath: directory + "/messages.json")
    }

    /// Snapshots the given messages. Safe to call from a postbox transaction:
    /// the actual disk write is asynchronous.
    public func capture(transaction: Transaction, ids: [MessageId]) {
        var entries: [Entry] = []
        for id in ids {
            guard let message = transaction.getMessage(id) else {
                continue
            }
            entries.append(Entry(
                peerId: message.id.peerId.toInt64(),
                messageId: message.id.id,
                date: message.timestamp,
                authorId: message.author?.id.toInt64(),
                text: message.text,
                kind: "deleted",
                savedAt: Int32(CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970)
            ))
        }
        if !entries.isEmpty {
            self.append(entries)
        }
    }

    /// Records the previous version of an edited message.
    public func captureEdit(transaction: Transaction, id: MessageId, previousText: String) {
        guard let message = transaction.getMessage(id) else {
            return
        }
        self.append([Entry(
            peerId: message.id.peerId.toInt64(),
            messageId: message.id.id,
            date: message.timestamp,
            authorId: message.author?.id.toInt64(),
            text: previousText,
            kind: "edited",
            savedAt: Int32(CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970)
        )])
    }

    private func append(_ entries: [Entry]) {
        self.queue.async {
            var stored = self.load()
            stored.append(contentsOf: entries)
            if stored.count > 20000 {
                stored.removeFirst(stored.count - 20000)
            }
            if let data = try? JSONEncoder().encode(stored) {
                try? data.write(to: self.fileURL)
            }
        }
    }

    public func load() -> [Entry] {
        guard let data = try? Data(contentsOf: self.fileURL),
              let entries = try? JSONDecoder().decode([Entry].self, from: data) else {
            return []
        }
        return entries
    }

    public func clear() {
        self.queue.async {
            try? FileManager.default.removeItem(at: self.fileURL)
        }
    }

    public var archivePath: String {
        return self.fileURL.path
    }
}
