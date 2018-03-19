import Foundation
import Files
import PathKit
import Stencil

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

let localizableFile = try baseLanguageFolder.file(named: "Localizable.strings")
guard let localizableContents = NSDictionary(contentsOfFile: localizableFile.path) as? [String: String] else {
    fatalError("Could not load localizable contents")
}

let localizedStrings: [LocalizedString] = localizableContents.map { tuple in
    let (key, value) = tuple
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
