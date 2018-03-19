import Foundation
import Files
import PathKit
import Stencil

struct LocalizedString {
    let key: String
    let value: String
}

guard let rootFolder = Folder.current.parent?.parent else {
    fatalError("Could not access root folder")
}

let generatedFolder = try rootFolder.subfolder(named: "Generated")
let templatesFolder = try generatedFolder.subfolder(named: "Templates")
let codeFolder = try generatedFolder.subfolder(named: "Code")

let fileSystemLoader = FileSystemLoader(paths: [ Path(templatesFolder.path) ])
let environment = Environment(loader: fileSystemLoader)

let localizedStrings = [
    LocalizedString(key: "string_one", value: "This is string one"),
    LocalizedString(key: "string_two", value: "This is string two"),
]

let localizedPlurals = [
    LocalizedString(key: "plural_one", value: "Going for %d plurals"),
    LocalizedString(key: "plural_two", value: "There are %d noises"),
]

let context: [String: Any] = [
    "developer_language" : "English",
    "localized_strings" : localizedStrings,
    "localized_plurals" : localizedPlurals,
]

let fileContents = try environment.renderTemplate(name: "LocalizedStrings.swift.stencil", context: context)

let file = try codeFolder.createFileIfNeeded(withName: "LocalizedStrings.swift")
try file.write(string: fileContents)

print("Rendered \(file.name)")
