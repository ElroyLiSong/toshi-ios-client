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

@testable import Toshi
import XCTest

// MARK: - Robot to deal with the Sign In With Passphrase page of the app

protocol SignInRobot: BasicRobot { }

// MARK: The various buttons which are on the passphrase page

enum SignInScreenButton {
    case
    back,
    howWork,
    signIn,
    wordsLeft(words: Int)
    
    var accessibilityLabel: String {
        switch self {
        case .back:
            return Localized.back_action_title
        case .howWork:
            return Localized.passphrase_sign_in_explanation_title
        case .signIn:
            return Localized.passphrase_sign_in_button
        case .wordsLeft(let words):
            return LocalizedPlural("passphrase_sign_in_button_placeholder", for: words)
        }
    }
}

// MARK: - Default Implementation

extension SignInRobot {
    
    // MARK: - Actions
    
    func select(button: SignInScreenButton,
                file: StaticString = #file,
                line: UInt = #line) -> SignInRobot {
        tapButtonWith(accessibilityLabel: button.accessibilityLabel,
                      file: file,
                      line: line)
        
        return self
    }
    
    // MARK: - Validators
    
    @discardableResult
    func validateOnSignInScreen(file: StaticString = #file,
                                line: UInt = #line) -> SignInRobot {
        confirmViewVisibleWith(accessibilityLabel: Localized.passphrase_sign_in_title,
                               file: file,
                               line: line)
        
        return self
    }
    
    @discardableResult
    func validateOffSignInScreen(file: StaticString = #file,
                                 line: UInt = #line) -> SignInRobot {
        confirmViewGoneWith(accessibilityLabel: Localized.passphrase_sign_in_title,
                            file: file,
                            line: line)
        
        return self
    }
}
