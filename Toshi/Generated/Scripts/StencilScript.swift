import Foundation
import Files
import PathKit
import ShellOut
import Stencil

enum StencilScriptError: Error {
    case
    couldNotLoadDictionary
}

func hasFileChanged(named fileName: String) throws -> Bool {
    let diff = try shellOut(to: ShellOutCommand(string: "git diff --name-only"))

    let filesInDiff = diff
        .components(separatedBy: "\n") // Split the file names into an array
        .flatMap { $0.components(separatedBy: "/").last } // Take the last path component of each file name

    return filesInDiff.contains(fileName)
}

func loadDictionary(from file: File) throws -> [String: String] {
    guard let dictionary = NSDictionary(contentsOfFile: file.path) as? [String: String] else {
        throw StencilScriptError.couldNotLoadDictionary
    }

    return dictionary
}

struct LocalizedString {
    let key: String
    let value: String
}

guard let sourceRootPath = ProcessInfo.processInfo.environment["SRCROOT"] else {
    fatalError("Could not access source root!")
}

let rootFolder = try Folder(path: sourceRootPath)

let toshiFolder = try rootFolder.subfolder(named: "Toshi")
let generatedFolder = try toshiFolder.subfolder(named: "Generated")
let templatesFolder = try generatedFolder.subfolder(named: "Templates")
let codeFolder = try generatedFolder.subfolder(named: "Code")

let resourcesFolder = try toshiFolder.subfolder(named: "Resources")
let baseLanguageFolder = try resourcesFolder.subfolder(named: "Base.lproj")

let localizableFileName = "Localizable.strings"

guard try hasFileChanged(named: localizableFileName) else {
    print("\(localizableFileName) has not changed, not regenerating")
    exit(0)
}

let localizableFile = try baseLanguageFolder.file(named: localizableFileName)
let localizableContents = try loadDictionary(from: localizableFile)

let sortedKeys = localizableContents.keys.sorted()
let localizedStrings: [LocalizedString] = sortedKeys.map { key in
    let value = localizableContents[key]!
    let valueWithoutNewlineCharacters = value.replacingOccurrences(of: "\n", with: "\\n")
    return LocalizedString(key: key, value: valueWithoutNewlineCharacters)
}

let fileSystemLoader = FileSystemLoader(paths: [ Path(templatesFolder.path) ])
let environment = Environment(loader: fileSystemLoader)

let localizedPlurals = [
    LocalizedString(key: "plural_one", value: "Going for %d plurals"),
    LocalizedString(key: "plural_two", value: "There are %d noises")
]

let context: [String: Any] = [
    "developer_language": "en",
    "localized_strings": localizedStrings,
    "localized_plurals": localizedPlurals
]

let fileContents = try environment.renderTemplate(name: "LocalizedStrings.swift.stencil", context: context)

let file = try codeFolder.createFileIfNeeded(withName: "LocalizedStrings.swift")
try file.write(string: fileContents)

print("Rendered \(file.name)")
