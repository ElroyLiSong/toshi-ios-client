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

import Foundation
@testable import Toshi

// MARK: - Robot to deal with the splash screen which shows on first launch or after logout.

protocol SplashScreenRobot: BasicRobot { }

// MARK: Buttons which can be selected on the splash screen

enum SplashScreenButton {
    case
    createNewAccount,
    signIn
    
    var accessibilityLabel: String {
        switch self {
        case .createNewAccount:
            return Localized("create_account_button_title")
        case .signIn:
            return Localized("sign_in_button_title")
        }
    }
}

// MARK: Options which can be selected when the terms dialog pops up

enum TermsOption {
    case
    agree,
    cancel,
    read
    
    var accessibilityLabel: String {
        switch self {
        case .agree:
            return Localized("accept_terms_action_agree")
        case .cancel:
            return Localized("cancel_action_title")
        case .read:
            return Localized("accept_terms_action_read")
        }
    }
}

enum TermsScreenOption {
    case
    done
    
    var accessibilityLabel: String {
        switch self {
        case .done:
            return Localized("done_action_title")
        }
    }
}

// MARK: - Default Implementation

extension SplashScreenRobot {
    
    // MARK: - Actions
    
    @discardableResult
    func select(button: SplashScreenButton,
                file: StaticString = #file,
                line: UInt = #line) -> SplashScreenRobot {
        tapButtonWith(accessibilityLabel: button.accessibilityLabel,
                      file: file,
                      line: line)
        
        return self
    }
    
    @discardableResult
    func select(termsOption: TermsOption,
                file: StaticString = #file,
                line: UInt = #line) -> SplashScreenRobot {
        tapButtonWith(accessibilityLabel: termsOption.accessibilityLabel,
                      file: file,
                      line: line)
        
        return self
    }
    
    @discardableResult
    func select(termsScreenOption option: TermsScreenOption,
                file: StaticString = #file,
                line: UInt = #line) -> SplashScreenRobot {
        tapButtonWith(accessibilityLabel: option.accessibilityLabel,
                      file: file,
                      line: line)
        
        return self
    }
    
    // MARK: - Validators
    
    @discardableResult
    func validateOnSplashScreen(file: StaticString = #file,
                                line: UInt = #line) -> SplashScreenRobot {
        confirmViewVisibleWith(accessibilityLabel: Localized("welcome_title"),
                               file: file,
                               line: line)
        
        return self
    }
    
    @discardableResult
    func validateOffSplashScreen(file: StaticString = #file,
                                 line: UInt = #line) -> SplashScreenRobot {
        confirmViewGoneWith(accessibilityLabel: Localized("welcome_title"),
                            file: file,
                            line: line)
        
        return self
    }
    
    @discardableResult
    func validateTermsDialogShowing(file: StaticString = #file,
                                    line: UInt = #line) -> SplashScreenRobot {
        confirmViewVisibleWith(accessibilityLabel: TermsOption.agree.accessibilityLabel,
                               file: file,
                               line: line)
        confirmViewVisibleWith(accessibilityLabel: TermsOption.cancel.accessibilityLabel,
                               file: file,
                               line: line)
        confirmViewVisibleWith(accessibilityLabel: TermsOption.read.accessibilityLabel,
                               file: file,
                               line: line)
        
        return self
    }
    
    @discardableResult
    func validateTermsDialogGone(file: StaticString = #file,
                                 line: UInt = #line) -> SplashScreenRobot {
        confirmViewGoneWith(accessibilityLabel: TermsOption.agree.accessibilityLabel,
                            file: file,
                            line: line)
        confirmViewGoneWith(accessibilityLabel: TermsOption.cancel.accessibilityLabel,
                            file: file,
                            line: line)
        confirmViewGoneWith(accessibilityLabel: TermsOption.read.accessibilityLabel,
                            file: file,
                            line: line)
        
        return self
    }
    
    @discardableResult
    func validateFullTermsShowing(file: StaticString = #file,
                                  line: UInt = #line) -> SplashScreenRobot {
        confirmViewGoneWith(accessibilityLabel: "Toshi Terms of Service",
                            file: file,
                            line: line)
        
        return self
    }
    
    @discardableResult
    func validateFullTermsGone(file: StaticString = #file,
                               line: UInt = #line) -> SplashScreenRobot {
        confirmViewGoneWith(accessibilityLabel: "Toshi Terms of Service",
                            file: file,
                            line: line)
        
        return self
    }
}
