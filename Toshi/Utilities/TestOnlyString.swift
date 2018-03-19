// Copyright (c) 2018 Token Browser, Inc
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

// Strings which will only be used during UI testing and thus do not need to be localized or instantiated.
enum TestOnlyString {
    
    // MARK: - Static strings
    
    static let okButtonTitle = "OK"
    static let testAlertTitle = "TEST ALERT"

    // MARK: - Dynamic strings
    
    static func readTermsAlertMessage(termsURL: URL) -> String {
        return "Go read the terms and conditions at \(termsURL.absoluteString)"
    }
}
