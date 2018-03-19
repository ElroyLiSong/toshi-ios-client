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

// MARK: - Robot to deal with the "Me" tab in the app

protocol MyProfileRobot: BasicRobot { }

// MARK: The various cells which can be selected.

enum MyProfileCell {
    case
    advanced,
    balance,
    detailedProfile,
    localCurrency,
    qrCode,
    signOut,
    storePassphrase
    
    var accessibilityLabel: String {
        switch self {
        case .advanced:
            return Localized("settings_cell_advanced")
        case .balance:
            assertionFailure("You need to set this up on the balance cell before you use it")
            return "TODO"
        case .detailedProfile:
            assertionFailure("You need to set this up on the detailed profile cell before you use it")
            return "TODO"
        case .localCurrency:
            return Localized("currency_picker_title")
        case .qrCode:
            return Localized("settings_cell_qr")
        case .signOut:
            return Localized("settings_cell_signout")
        case .storePassphrase:
            return Localized("settings_cell_passphrase")
        }
    }
}

// The options which can be selected from the sign out dialog

enum SignOutDialogOption {
    case
    cancel,
    delete,
    signOut
    
    var accessibilityLabel: String {
        switch self {
        case .cancel:
            return Localized("cancel_action_title")
        case .delete:
            return Localized("settings_signout_action_delete")
        case .signOut:
            return Localized("settings_signout_action_signout")
        }
    }
}

// MARK: - Default implementation

extension MyProfileRobot {
    
    // MARK: - Actions
    
    @discardableResult
    func select(cell: MyProfileCell,
                file: StaticString = #file,
                line: UInt = #line) -> MyProfileRobot {
        tapCellWith(accessibilityLabel: cell.accessibilityLabel,
                    file: file,
                    line: line)
        
        return self
    }
    
    @discardableResult
    func select(signOutOption: SignOutDialogOption,
                file: StaticString = #file,
                line: UInt = #line) -> MyProfileRobot {
        tapButtonWith(accessibilityLabel: signOutOption.accessibilityLabel,
                      file: file,
                      line: line)
        
        return self
    }
    
    // MARK: - Validators
    
    @discardableResult
    func validateOnMyProfileScreen(file: StaticString = #file,
                                   line: UInt = #line) -> MyProfileRobot {
        confirmViewVisibleWith(accessibilityLabel: Localized("settings_cell_qr"),
                               file: file,
                               line: line)
        
        return self
    }
    
    @discardableResult
    func validateOffMyProfileScreen(file: StaticString = #file,
                                    line: UInt = #line) -> MyProfileRobot {
        confirmViewGoneWith(accessibilityLabel: Localized("settings_cell_qr"),
                            file: file,
                            line: line)
        
        return self
    }
    
    @discardableResult
    func validateNoFundsSignOutDialogShowing(file: StaticString = #file,
                                             line: UInt = #line) -> MyProfileRobot {
        confirmViewVisibleWith(accessibilityLabel: Localized("settings_signout_nofunds_title"),
                               file: file,
                               line: line)
        
        return self
    }
    
    @discardableResult
    func validateNoFundsSignOutDialogGone(file: StaticString = #file,
                                          line: UInt = #line) -> MyProfileRobot {
        confirmViewGoneWith(accessibilityLabel: Localized("settings_signout_nofunds_title"),
                            file: file,
                            line: line)
        
        return self
    }
}
