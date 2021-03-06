//
//  IPAFileManager.swift
//  appdb
//
//  Created by ned on 28/04/2019.
//  Copyright © 2019 ned. All rights reserved.
//

import Foundation
import UIKit
import Swifter
import ZIPFoundation

struct LocalIPAFile: Hashable {
    var filename: String = ""
    var size: String = ""
}

struct IPAFileManager {

    static var shared = IPAFileManager()
    private init() { }

    let supportedFileExtensions: [String] = ["ipa", "zip"]

    private var localServer: HttpServer!
    private var backgroundTask: BackgroundTaskUtil?

    func documentsDirectoryURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    func inboxDirectoryURL() -> URL {
        documentsDirectoryURL().appendingPathComponent("Inbox")
    }

    func url(for ipa: LocalIPAFile) -> URL {
        documentsDirectoryURL().appendingPathComponent(ipa.filename)
    }

    func urlFromFilename(filename: String) -> URL {
        documentsDirectoryURL().appendingPathComponent(filename)
    }

    // MARK: - Clear temporary folder - there may be leftovers

    func clearTmpDirectory() {
        do {
            var tmpDirURL: URL!

            if #available(iOS 10.0, *) {
                tmpDirURL = FileManager.default.temporaryDirectory
            } else {
                tmpDirURL = URL(fileURLWithPath: NSTemporaryDirectory())
            }
            let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: tmpDirURL.path)
            try tmpDirectory.forEach { file in
                try FileManager.default.removeItem(atPath: tmpDirURL.appendingPathComponent(file).path)
            }
        } catch { }
    }

    // MARK: - Rename file

    func rename(file: LocalIPAFile, to: String) {
        guard FileManager.default.fileExists(atPath: documentsDirectoryURL().appendingPathComponent(file.filename).path) else {
            Messages.shared.showError(message: "File not found at given path".prettified)
            return
        }
        let startURL = documentsDirectoryURL().appendingPathComponent(file.filename)
        let endURL = documentsDirectoryURL().appendingPathComponent(to)
        do {
            try FileManager.default.moveItem(at: startURL, to: endURL)
        } catch let error {
            Messages.shared.showError(message: error.localizedDescription)
        }
    }

    // MARK: - Delete file

    func delete(file: LocalIPAFile) {
        guard FileManager.default.isDeletableFile(atPath: documentsDirectoryURL().appendingPathComponent(file.filename).path) else {
            Messages.shared.showError(message: "File not found at given path".localized())
            return
        }
        do {
            try FileManager.default.removeItem(at: documentsDirectoryURL().appendingPathComponent(file.filename))
        } catch let error {
            Messages.shared.showError(message: error.localizedDescription)
        }
    }

    // MARK: - Retrieve file size

    func getSize(from filename: String) -> String {
        let url = documentsDirectoryURL().appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            Messages.shared.showError(message: "File not found at given path".localized())
            return ""
        }
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            guard let fileSize = resourceValues.fileSize else {
                Messages.shared.showError(message: "File size not found in resource values".localized())
                return ""
            }
            return Global.humanReadableSize(bytes: Int64(fileSize))
        } catch let error {
            Messages.shared.showError(message: error.localizedDescription)
            return ""
        }
    }

    // MARK: - Get a base 64 encoded string from Info.plist file

    func base64ToJSONInfoPlist(from file: LocalIPAFile) -> String? {

        let randomName = Global.randomString(length: 5)
        let tmp = documentsDirectoryURL().appendingPathComponent(randomName, isDirectory: true)

        func exit(_ errorMessage: String) -> String? {
            Messages.shared.showError(message: errorMessage.prettified)
            do {
                try FileManager.default.removeItem(atPath: tmp.path)
                return nil
            } catch {
                return nil
            }
        }
        do {
            let ipaUrl = documentsDirectoryURL().appendingPathComponent(file.filename)
            guard FileManager.default.fileExists(atPath: ipaUrl.path) else { return exit("IPA Not found") }
            if FileManager.default.fileExists(atPath: tmp.path) { try FileManager.default.removeItem(atPath: tmp.path) }
            try FileManager.default.createDirectory(atPath: tmp.path, withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: ipaUrl, to: tmp)
            let payload = tmp.appendingPathComponent("Payload", isDirectory: true)
            guard FileManager.default.fileExists(atPath: payload.path) else { return exit("IPA is missing Payload folder") }
            let contents = try FileManager.default.contentsOfDirectory(at: payload, includingPropertiesForKeys: nil)
            guard let dotApp = contents.first(where: { $0.pathExtension == "app" }) else { return exit("IPA is missing .app folder") }
            let infoPlist = dotApp.appendingPathComponent("Info.plist", isDirectory: false)
            guard FileManager.default.fileExists(atPath: infoPlist.path) else { return exit("IPA is missing Info.plist file") }
            guard let dict = NSDictionary(contentsOfFile: infoPlist.path) else { return exit("Unable to read contents of Info.plist file") }
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            guard let jsonString = String(data: jsonData, encoding: String.Encoding.utf8) else { return exit("Unable to encode Info.plist file") }
            try FileManager.default.removeItem(atPath: tmp.path)
            return jsonString.toBase64()
        } catch let error {
            Messages.shared.showError(message: error.localizedDescription)
            do {
                try FileManager.default.removeItem(atPath: tmp.path)
                return nil
            } catch {
                return nil
            }
        }
    }

    // MARK: - Get bundle id from ipa file

    func getBundleId(from file: LocalIPAFile) -> String? {

        let randomName = Global.randomString(length: 5)
        let tmp = documentsDirectoryURL().appendingPathComponent(randomName, isDirectory: true)

        func exit(_ errorMessage: String) -> String? {
            Messages.shared.showError(message: errorMessage.prettified)
            do {
                try FileManager.default.removeItem(atPath: tmp.path)
                return nil
            } catch {
                return nil
            }
        }
        do {
            let ipaUrl = documentsDirectoryURL().appendingPathComponent(file.filename)
            guard FileManager.default.fileExists(atPath: ipaUrl.path) else { return exit("IPA Not found") }
            if FileManager.default.fileExists(atPath: tmp.path) { try FileManager.default.removeItem(atPath: tmp.path) }
            try FileManager.default.createDirectory(atPath: tmp.path, withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: ipaUrl, to: tmp)
            let payload = tmp.appendingPathComponent("Payload", isDirectory: true)
            guard FileManager.default.fileExists(atPath: payload.path) else { return exit("IPA is missing Payload folder") }
            let contents = try FileManager.default.contentsOfDirectory(at: payload, includingPropertiesForKeys: nil)
            guard let dotApp = contents.first(where: { $0.pathExtension == "app" }) else { return exit("IPA is missing .app folder") }
            let infoPlist = dotApp.appendingPathComponent("Info.plist", isDirectory: false)
            guard FileManager.default.fileExists(atPath: infoPlist.path) else { return exit("IPA is missing Info.plist file") }
            guard let dict = NSDictionary(contentsOfFile: infoPlist.path) else { return exit("Unable to read contents of Info.plist file") }
            guard let bundleId = dict["CFBundleIdentifier"] as? String else { return exit("Unable to find bundle id in Info.plist") }
            try FileManager.default.removeItem(atPath: tmp.path)
            return bundleId
        } catch let error {
            Messages.shared.showError(message: error.localizedDescription)
            do {
                try FileManager.default.removeItem(atPath: tmp.path)
                return nil
            } catch {
                return nil
            }
        }
    }

    // MARK: - Change bundle id and return eventual new filename

    func changeBundleId(for file: LocalIPAFile, from oldBundleId: String, to newBundleId: String, overwriteFile: Bool) -> String? {

        let randomName = Global.randomString(length: 5)
        let tmp = documentsDirectoryURL().appendingPathComponent(randomName, isDirectory: true)

        func exit(_ errorMessage: String) -> String? {
            Messages.shared.showError(message: errorMessage.prettified)
            do {
                try FileManager.default.removeItem(atPath: tmp.path)
                return nil
            } catch {
                return nil
            }
        }
        do {
            let ipaUrl = documentsDirectoryURL().appendingPathComponent(file.filename)
            guard FileManager.default.fileExists(atPath: ipaUrl.path) else { return exit("IPA Not found") }
            if FileManager.default.fileExists(atPath: tmp.path) { try FileManager.default.removeItem(atPath: tmp.path) }
            try FileManager.default.createDirectory(atPath: tmp.path, withIntermediateDirectories: true)
            try FileManager.default.unzipItem(at: ipaUrl, to: tmp)
            let payload = tmp.appendingPathComponent("Payload", isDirectory: true)
            guard FileManager.default.fileExists(atPath: payload.path) else { return exit("IPA is missing Payload folder") }
            let contents = try FileManager.default.contentsOfDirectory(at: payload, includingPropertiesForKeys: nil)
            guard let dotApp = contents.first(where: { $0.pathExtension == "app" }) else { return exit("IPA is missing .app folder") }

            // Search recursively in .app folder for files named 'Info.plist'
            let enumerator = FileManager.default.enumerator(atPath: dotApp.path)
            if let filePaths = enumerator?.allObjects as? [String] {
                let infoPlists = filePaths.filter { $0.contains("Info.plist") }

                // For each file found, replace old bundle id with new one
                for plist in infoPlists {
                    let infoPlist = dotApp.appendingPathComponent(plist, isDirectory: false)
                    if FileManager.default.fileExists(atPath: infoPlist.path), let dict = NSMutableDictionary(contentsOfFile: infoPlist.path) {
                        if let oldValue = dict["CFBundleIdentifier"] as? String, oldValue.contains(oldBundleId) {
                            let newValue = oldValue.replacingOccurrences(of: oldBundleId, with: newBundleId)
                            dict.setValue(newValue, forKey: "CFBundleIdentifier")
                            dict.write(to: infoPlist, atomically: true)
                        }
                    }
                }
            }

            var destinationUrl: URL!

            if !overwriteFile {
                destinationUrl = documentsDirectoryURL().appendingPathComponent(file.filename.dropLast(4) + " (\(newBundleId)).ipa")
                var i: Int = 0
                while FileManager.default.fileExists(atPath: destinationUrl.path) {
                    i += 1
                    destinationUrl = documentsDirectoryURL().appendingPathComponent(file.filename.dropLast(4) + " (\(newBundleId))_\(i).ipa")
                }
            } else {
                destinationUrl = ipaUrl
                try FileManager.default.removeItem(atPath: ipaUrl.path)
            }

            try FileManager.default.zipItem(at: payload, to: destinationUrl, compressionMethod: .deflate)
            try FileManager.default.removeItem(atPath: tmp.path)

            return destinationUrl.lastPathComponent
        } catch let error {
            Messages.shared.showError(message: error.localizedDescription)
            do {
                try FileManager.default.removeItem(atPath: tmp.path)
                return nil
            } catch {
                return nil
            }
        }
    }

    // MARK: - Copy file

    func copyToDocuments(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        var endURL = documentsDirectoryURL().appendingPathComponent(url.lastPathComponent)
        if !FileManager.default.fileExists(atPath: endURL.path) {
            do {
                try FileManager.default.copyItem(at: url, to: endURL)
            } catch {}
        } else {
            var i: Int = 0
            while FileManager.default.fileExists(atPath: endURL.path) {
                i += 1
                let newName = url.deletingPathExtension().lastPathComponent + " (\(i)).\(url.pathExtension)"
                endURL = documentsDirectoryURL().appendingPathComponent(newName)
            }
            do {
                try FileManager.default.copyItem(at: url, to: endURL)
            } catch {}
        }
    }

    // MARK: - Move files

    func moveToDocuments(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        var endURL = documentsDirectoryURL().appendingPathComponent(url.lastPathComponent)
        if !FileManager.default.fileExists(atPath: endURL.path) {
            do {
                try FileManager.default.moveItem(at: url, to: endURL)
            } catch {}
        } else {
            var i: Int = 0
            while FileManager.default.fileExists(atPath: endURL.path) {
                i += 1
                let newName = url.deletingPathExtension().lastPathComponent + " (\(i)).\(url.pathExtension)"
                endURL = documentsDirectoryURL().appendingPathComponent(newName)
            }
            do {
                try FileManager.default.moveItem(at: url, to: endURL)
            } catch {}
        }
    }

    func moveEventualIPAFilesToDocumentsDirectory(from directory: URL) {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        let inboxContents = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let ipas = inboxContents?.filter { supportedFileExtensions.contains($0.pathExtension.lowercased()) }
        for ipa in ipas ?? [] {
            let url = directory.appendingPathComponent(ipa.lastPathComponent)
            moveToDocuments(url: url)
        }
    }

    // MARK: - List all local ipas in documents folder

    func listLocalIpas() -> [LocalIPAFile] {
        var result = [LocalIPAFile]()

        moveEventualIPAFilesToDocumentsDirectory(from: inboxDirectoryURL())

        let contents = try? FileManager.default.contentsOfDirectory(at: documentsDirectoryURL(), includingPropertiesForKeys: nil)
        let ipas = contents?.filter { supportedFileExtensions.contains($0.pathExtension.lowercased()) }
        for ipa in ipas ?? [] {
            let filename = ipa.lastPathComponent
            let size = getSize(from: filename)
            let ipa = LocalIPAFile(filename: filename, size: size)
            if !result.contains(ipa) { result.append(ipa) }
        }
        result = result.sorted { $0.filename.localizedStandardCompare($1.filename) == .orderedAscending }
        return result
    }
}

protocol LocalIPAServer {
    mutating func startServer()
    mutating func stopServer()
}

// MARK: - LocalIPAServer: starts a local server on port 8080 and serves ipas in documents directory until stopped

extension IPAFileManager: LocalIPAServer {
    func getIpaLocalUrl(from ipa: LocalIPAFile) -> String {
         "http://127.0.0.1:8080/\(ipa.filename)"
    }

    mutating func startServer() {
        localServer = HttpServer()
        localServer["/:path"] = shareFilesFromDirectory(documentsDirectoryURL().path)
        do {
            try localServer.start(8080)
            backgroundTask = BackgroundTaskUtil()
            backgroundTask?.start()
        } catch {
            stopServer()
        }
    }

    mutating func stopServer() {
        localServer.stop()
        backgroundTask = nil
    }
}
