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

import UIKit

// Methods which help out with testing.
extension UIViewController {
    
    /// Shows a test alert with the given message, a defined title, and an OK button to dismiss it.
    ///
    /// - Parameter message: The message to display on the alert.
    func showTestAlert(message: String) {
        guard UIApplication.isUITesting else {
            assertionFailure("DON'T CALL THIS IN PROD!")
            return
        }
        
        let alertController = UIAlertController(title: TestOnlyString.testAlertTitle,
                                                message: message,
                                                preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: TestOnlyString.okButtonTitle,
                                     style: .cancel) // Automatically dismisses the alert.
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true)
    }
}
