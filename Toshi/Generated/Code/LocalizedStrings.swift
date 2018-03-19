// This file is machine-generated. Please do not edit it by hand.

import Foundation

enum LocalizedKey: String {
    case
    string_one,
    string_two

    var currentValue: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}

struct Localized { 
    /// Value in English: "This is string one"
    static let string_one = LocalizedKey.string_one.currentValue
    /// Value in English: "This is string two"
    static let string_two = LocalizedKey.string_two.currentValue
}

enum LocalizedPluralKey: String {
    case
    plural_one,
    plural_two

    func currentValue(for count: Int) -> String {
        let format = NSLocalizedString(self.rawValue, comment: "")
        return String.localizedStringWithFormat(format, count)
    }
}

enum LocalizedPlural { 
    /// Value in English: "Going for %d plurals"
    static func plural_one(for count: Int) -> String {
        return LocalizedPluralKey.plural_one.currentValue(for: count)
    }
    /// Value in English: "There are %d noises"
    static func plural_two(for count: Int) -> String {
        return LocalizedPluralKey.plural_two.currentValue(for: count)
    }
}
