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

/// MARK: -  A robot for dealing with interacting with the tab bar.
protocol TabBarRobot: BasicRobot { }

// MARK: - Tab Bar items
enum TabBarItem {
    case
    dapps,
    favorites,
    recent,
    settings,
    wallet
    
    var accessibilityLabel: String {
        switch self {
        case .dapps:
            return Localized("tab_bar_title_dapps")
        case .favorites:
            return Localized("tab_bar_title_favorites")
        case .recent:
            return Localized("tab_bar_title_recent")
        case .settings:
            return Localized("tab_bar_title_settings")
        case .wallet:
            return Localized("tab_bar_title_wallet")
        }
    }
}

// MARK: - Default implementation

extension TabBarRobot {

    // MARK: - Actions
    
    @discardableResult
    func select(item: TabBarItem,
                file: StaticString = #file,
                line: UInt = #line) -> TabBarRobot {
        tapButtonWith(accessibilityLabel: item.accessibilityLabel,
                      file: file,
                      line: line)
        
        return self
    }
    
    // MARK: - Validators
    
    @discardableResult
    func validateTabBarShowing(file: StaticString = #file,
                               line: UInt = #line) -> TabBarRobot {
        confirmViewVisibleWith(accessibilityIdentifier: .mainTabBar,
                               file: file,
                               line: line)
        
        return self
    }
    
    @discardableResult
    func validateTabBarGone(file: StaticString = #file,
                            line: UInt = #line) -> TabBarRobot {
        confirmViewGoneWith(accessibilityIdentifier: .mainTabBar,
                            file: file,
                            line: line)
            
        return self
    }
}
