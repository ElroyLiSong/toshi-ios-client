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
import CameraScanner

protocol SendTokenViewControllerDelegate: class {
    func sendTokenControllerDidFinish(_ controller: UIViewController?)
}

final class SendTokenViewController: UIViewController {

    private let sectionHeight: CGFloat = 160.0

    let token: Token
    let tokenType: TokenType

    private var configurator: SendTokenViewConfigurator!
    weak var delegate: SendTokenViewControllerDelegate?

    init(token: Token, tokenType: TokenType) {
        self.token = token
        self.tokenType = tokenType

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configurator = SendTokenViewConfigurator(token: token, view: view)
        configurator.delegate = self
        configurator.layoutGuide = layoutGuide()

        navigationController?.navigationBar.isTranslucent = false

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped(_:)))

        view.backgroundColor = Theme.viewBackgroundColor

        configurator.configureView(view)
    }

    @objc private func cancelButtonTapped(_ item: UIBarButtonItem) {

        guard !configurator.isFilled else {
            showTransactionLeaveAlert()
            return
        }

        navigationController?.dismiss(animated: true, completion: nil)
    }

    private func showTransactionLeaveAlert() {
        let alertController = UIAlertController(title: Localized.wallet_transaction_leave_alert_message, message: nil, preferredStyle: .alert)
        let stayAction = UIAlertAction(title: Localized.wallet_transaction_leave_cancel_action, style: .default, handler: nil)
        let leaveAction = UIAlertAction(title: Localized.wallet_transaction_leave_confirm_action, style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        }

        alertController.addAction(stayAction)
        alertController.addAction(leaveAction)
        alertController.preferredAction = leaveAction

        Navigator.presentModally(alertController)
    }
}

extension SendTokenViewController: SendTokenViewConfiguratorDelegate {

    func didReceiveScanEvent(_ configurator: SendTokenViewConfigurator) {
        let controller = ScannerController(instructions: Localized.qr_scanner_instructions, types: [.qrCode])
        controller.delegate = self

        present(controller, animated: true, completion: nil)
    }

    func didReceiveContinueEvent(_ configurator: SendTokenViewConfigurator, params: [String: Any]) {
        let controller = TokenSendConfirmationViewController(token: token, params: params)
        controller.delegate = self
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true, completion: nil)
    }
}

extension SendTokenViewController: ScannerViewControllerDelegate {
    func scannerViewControllerDidCancel(_ controller: ScannerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    func scannerViewController(_ controller: ScannerViewController, didScanResult result: String) {

        // We need to process only ethereum address or admin login intent and ignore all the rest
        if let intent = QRCodeIntent(result: result) {
            switch intent {
            case .webSignIn(let loginToken):
                IDAPIClient.shared.adminLogin(loginToken: loginToken) {[weak self] _, _ in
                    SoundPlayer.playSound(type: .scanned)
                    self?.dismiss(animated: true)
                }
            case .addressInput(let address):
                controller.dismiss(animated: true, completion: { [weak self] in
                    self?.configurator.updateDestinationAddress(to: address)
                })
            default:
                let alert = UIAlertController(title: Localized.wallet_not_an_address_message, message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Localized.alert_ok_action_title, style: .default, handler: { _ in
                    controller.startScanning()
                }))
                alert.addAction(UIAlertAction(title: Localized.cancel_action_title, style: .cancel, handler: { _ in
                    controller.startScanning()
                }))
                Navigator.presentModally(alert)
            }
        }
    }
}

extension SendTokenViewController: TokenSendConfirmationDelegate {

    func tokenSendConfirmationControllerDidFinish(_ controller: TokenSendConfirmationViewController) {
        delegate?.sendTokenControllerDidFinish(navigationController)
    }
}
