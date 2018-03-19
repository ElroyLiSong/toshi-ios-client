// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import EarlGrey
import UIKit
@testable import Toshi
import XCTest

// MARK: - Concrete implementation of Robot pattern for Earl Grey

class EarlGreyRobot {
    
    private func retriveElementOfClass<T>(_ clazz: T.Type, _ completion: @escaping (T?) -> Void) -> GREYActionBlock where T: AnyObject {
        return GREYActionBlock(name: "Get element of class \(T.self)",
            constraints: grey_kindOfClass(T.self),
            perform: { element, _ in
                guard let typedElement = element as? T else {
                    return false
                }
                
                completion(typedElement)
                return true
        })
    }
    
    private func viewWith(label: String,
                          file: StaticString,
                          line: UInt) -> GREYElementInteraction {
        // Accessibility replaces newlines with spaces.
        let labelWithoutNewlines = label.replacingOccurrences(of: "\n", with: " ")
        
        return earlFromFile(file: file, line: line)
            .selectElement(with: grey_allOf([
                grey_accessibilityLabel(labelWithoutNewlines)
            ]))
            .atIndex(0)
    }
    
    private func buttonWith(label: String,
                            file: StaticString,
                            line: UInt) -> GREYElementInteraction {
        return earlFromFile(file: file, line: line)
            .selectElement(with: grey_allOf([
                grey_accessibilityLabel(label),
                grey_accessibilityTrait(UIAccessibilityTraitButton)
            ]))
            .atIndex(0)
    }
    
    private func cellWith(label: String,
                          file: StaticString,
                          line: UInt) -> GREYElementInteraction {
        return self.earlFromFile(file: file, line: line)
            .selectElement(with: grey_allOf([
                grey_descendant(grey_accessibilityLabel(label)),
                grey_sufficientlyVisible(),
                grey_kindOfClass(UITableViewCell.self)
            ]))
            .usingSearch(grey_scrollInDirection(.down, 100),
                         onElementWith: grey_kindOfClass(UITableView.self))

    }
    
    private func viewWith(identifier: String,
                          file: StaticString,
                          line: UInt) -> GREYElementInteraction {
        return earlFromFile(file: file, line: line)
            .selectElement(with: grey_accessibilityID(identifier))
    }
    
    private func earlFromFile(file: StaticString, line: UInt) -> EarlGreyImpl {
        return EarlGreyImpl.invoked(fromFile: file.description, lineNumber: line)
    }
}

// MARK: - EarlGrey implementations of `BasicRobot` requirements.

extension EarlGreyRobot: BasicRobot {
    
    func confirmViewVisibleWith(accessibilityLabel: String, file: StaticString, line: UInt) {
        viewWith(label: accessibilityLabel, file: file, line: line)
            .assert(with: grey_sufficientlyVisible())
    }
    
    func confirmViewVisibleWith(accessibilityIdentifier: AccessibilityIdentifier, file: StaticString, line: UInt) {
        viewWith(identifier: accessibilityIdentifier.rawValue, file: file, line: line)
            .assert(with: grey_sufficientlyVisible())
    }
    
    func confirmViewGoneWith(accessibilityLabel: String, file: StaticString, line: UInt) {
        viewWith(label: accessibilityLabel, file: file, line: line)
            .assert(with: grey_notVisible())
    }
    
    func confirmViewGoneWith(accessibilityIdentifier: AccessibilityIdentifier, file: StaticString, line: UInt) {
        viewWith(identifier: accessibilityIdentifier.rawValue, file: file, line: line)
            .assert(with: grey_notVisible())
    }

    func tapButtonWith(accessibilityLabel: String, file: StaticString, line: UInt) {
        buttonWith(label: accessibilityLabel, file: file, line: line)
            .perform(grey_tap())
    }
    
    func tapCellWith(accessibilityLabel: String, file: StaticString, line: UInt) {
        cellWith(label: accessibilityLabel, file: file, line: line)
            .perform(grey_tap())
    }
    
    func tapViewWith(accessibilityLabel: String, file: StaticString, line: UInt) {
        viewWith(label: accessibilityLabel, file: file, line: line)
            .perform(grey_tap())
    }
}

// MARK: - Mix-in Robots

extension EarlGreyRobot: MyProfileRobot { /*mix-in */ }
extension EarlGreyRobot: SplashScreenRobot { /* mix-in */ }
extension EarlGreyRobot: SignInRobot { /* mix-in */ }
extension EarlGreyRobot: TabBarRobot { /* mix-in */ }
