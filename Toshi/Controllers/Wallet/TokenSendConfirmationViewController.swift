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

import TinyConstraints
import UIKit

protocol TokenSendConfirmationDelegate: class {
    func tokenSendConfirmationControllerDidFinish(_ controller: TokenSendConfirmationViewController)
}

final class TokenSendConfirmationViewController: UIViewController {

    weak var delegate: TokenSendConfirmationDelegate?

    private let params: [String: Any]

    private let token: Token

    private lazy var amountToSend: NSDecimalNumber = {
        guard let valueString = params[PaymentParameters.value] as? String else { return NSDecimalNumber.zero }
        return NSDecimalNumber(hexadecimalString: valueString)
    }()

    let paymentManager: PaymentManager

    private lazy var recipientAddress: String = {
        return params[PaymentParameters.to] as? String ?? ""
    }()

    private let showFiatAsPrimary: Bool

    // MARK: - Lazy views

    private lazy var hud: LoadingHUD = {
        return LoadingHUD(addedToView: self.view)
    }()

    private lazy var amountSection: SendConfirmationSection = {
        return SendConfirmationSection(sectionTitle: Localized.wallet_send_confirmation_amount_title)
    }()

    private lazy var totalValueSection: SendConfirmationSection = {
        return SendConfirmationSection(sectionTitle: Localized.wallet_send_confirmation_total_title, primaryCurrencyBold: true)
    }()

    private lazy var networkFeesSection: SendConfirmationSection = {
        return SendConfirmationSection(sectionTitle: Localized.wallet_send_confirmation_fees_title)
    }()

    private lazy var recipientHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = Localized.wallet_send_confirmation_recipient_header
        label.font = Theme.preferredRegular()
        label.textColor = Theme.darkTextHalfAlpha

        return label
    }()

    private lazy var recipientAddressLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.semiboldMonospaced(size: 20)
        label.numberOfLines = 0
        label.text = self.recipientAddress.toLines(count: 2)

        return label
    }()

    private lazy var confirmButton: ActionButton = {
        let button = ActionButton(margin: 0)
        button.title = Localized.confirm_action_title
        button.isEnabled = false
        button.addTarget(self,
                         action: #selector(confirmButtonTapped),
                         for: .touchUpInside)
        
        return button
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.errorColor

        return label
    }()

    // MARK: - Initialization

    init(token: Token, params: [String: Any]) {
        self.params = params
        self.token = token
        self.showFiatAsPrimary = true

        self.paymentManager = PaymentManager(parameters: params)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let paymentInfoView = setupPaymentInfoView()
        setupRecipientView(betweenTopAnd: paymentInfoView)

        view.backgroundColor = Theme.viewBackgroundColor
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped(_:)))

        showPaymentInfo()
    }

    private func showPaymentInfo() {
        hud.state = .loading(text: nil)
        hud.show()

        paymentManager.fetchRawPaymentInfo { [weak self] rawPaymentInfo in
            DispatchQueue.main.async {

                guard let strongSelf = self else { return }
                strongSelf.hud.hide()

                let fractionDigits: Int = 7

                let exchangeRate = ExchangeRateClient.exchangeRate

                if strongSelf.token.isEtherToken {
                    let fiatText = EthereumConverter.fiatValueStringWithCode(forWei: rawPaymentInfo.payedValue, exchangeRate: exchangeRate)
                    let etherText = EthereumConverter.ethereumValueString(forWei: rawPaymentInfo.payedValue, fractionDigits: fractionDigits)
                    strongSelf.amountSection.setupWith(primaryCurrencyString: fiatText, secondaryCurrencyString: etherText)
                } else {
                    var primaryString = "\(strongSelf.amountToSend) \(strongSelf.token.symbol)"
                    if !strongSelf.token.canShowFiatValue {
                        primaryString = "\(strongSelf.amountToSend.toHexString.toDisplayValue(with: strongSelf.token.decimals)) \(strongSelf.token.symbol)"
                    }

                    strongSelf.amountSection.setupWith(primaryCurrencyString: primaryString, secondaryCurrencyString: nil)
                }

                let totalFiatString = EthereumConverter.fiatValueStringWithCode(forWei: rawPaymentInfo.totalValue, exchangeRate: exchangeRate)
                let totalEthereumString = EthereumConverter.ethereumValueString(forWei: rawPaymentInfo.totalValue, fractionDigits: fractionDigits)
                strongSelf.totalValueSection.setupWith(primaryCurrencyString: totalFiatString, secondaryCurrencyString: totalEthereumString)

                let estimatedFeesFiatString = EthereumConverter.fiatValueStringWithCode(forWei: rawPaymentInfo.estimatedFees, exchangeRate: exchangeRate)
                let estimatedFeesEtherString = EthereumConverter.ethereumValueString(forWei: rawPaymentInfo.estimatedFees, fractionDigits: fractionDigits)
                strongSelf.networkFeesSection.setupWith(primaryCurrencyString: estimatedFeesFiatString, secondaryCurrencyString: estimatedFeesEtherString)

                strongSelf.confirmButton.isEnabled = rawPaymentInfo.sufficientBalance

                if !rawPaymentInfo.sufficientBalance {
                    strongSelf.errorLabel.isHidden = false
                    strongSelf.errorLabel.text = String(format: Localized.wallet_insuffisient_balance_generic, rawPaymentInfo.balanceString)
                }
            }
        }
    }

    @objc private func cancelButtonTapped(_ item: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    // MARK: - View Setup

    private func setupRecipientView(betweenTopAnd viewToPinToTopOf: UIView) {
        let recipientStackView = UIStackView()
        recipientStackView.alignment = .center
        recipientStackView.axis = .vertical
        recipientStackView.spacing = .mediumInterItemSpacing

        view.addSubview(recipientStackView)

        let viewLayoutGuide = layoutGuide()

        let stackViewTopLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(stackViewTopLayoutGuide)

        stackViewTopLayoutGuide.top(to: viewLayoutGuide)
        stackViewTopLayoutGuide.left(to: viewLayoutGuide)
        stackViewTopLayoutGuide.right(to: viewLayoutGuide)
        stackViewTopLayoutGuide.bottomToTop(of: recipientStackView)

        let stackViewBottomLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(stackViewBottomLayoutGuide)

        stackViewBottomLayoutGuide.bottomToTop(of: viewToPinToTopOf)
        stackViewBottomLayoutGuide.left(to: viewLayoutGuide)
        stackViewBottomLayoutGuide.right(to: viewLayoutGuide)
        stackViewBottomLayoutGuide.topToBottom(of: recipientStackView)

        // Ensure stack view is centered vertically in available space
        stackViewTopLayoutGuide.height(to: stackViewBottomLayoutGuide)

        recipientStackView.centerXToSuperview()

        recipientStackView.addArrangedSubview(recipientHeaderLabel)
        recipientStackView.addArrangedSubview(recipientAddressLabel)
    }

    private func setupPaymentInfoView() -> UIView {
        let paymentInfoStackView = UIStackView()
        paymentInfoStackView.axis = .vertical
        paymentInfoStackView.distribution = .fill
        paymentInfoStackView.spacing = .mediumInterItemSpacing

        view.addSubview(paymentInfoStackView)

        paymentInfoStackView.bottom(to: layoutGuide(), offset: -.largeInterItemSpacing)
        paymentInfoStackView.leftToSuperview(offset: .spacingx3)
        paymentInfoStackView.rightToSuperview(offset: .spacingx3)

        paymentInfoStackView.addArrangedSubview(amountSection)
        paymentInfoStackView.addArrangedSubview(networkFeesSection)
        if token.canShowFiatValue {
            paymentInfoStackView.addStandardBorder()
            paymentInfoStackView.addArrangedSubview(totalValueSection)
        }

        paymentInfoStackView.addArrangedSubview(confirmButton)
        paymentInfoStackView.addArrangedSubview(errorLabel)

        errorLabel.isHidden = true

        return paymentInfoStackView
    }

    // MARK: - Action Targets

    @objc private func confirmButtonTapped() {

        hud.state = .loading(text: nil)
        hud.show()
        
        paymentManager.sendPayment { [weak self] error, _ in
            guard let weakSelf = self else { return }

            guard error == nil else {
                weakSelf.hud.hide()

                let alert = UIAlertController(title: Localized.transaction_error_message, message: (error?.description ?? ToshiError.genericError.description), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: Localized.alert_ok_action_title, style: .default, handler: { _ in
                    weakSelf.navigationController?.dismiss(animated: true, completion: nil)
                }))

                Navigator.presentModally(alert)

                return
            }

            weakSelf.hud.successThenHide(after: 0.3, image: #imageLiteral(resourceName: "success_check"), text: Localized.wallet_send_confirmation_success_message, completion: {

                weakSelf.navigationController?.dismiss(animated: false, completion: {
                    weakSelf.delegate?.tokenSendConfirmationControllerDidFinish(weakSelf)
                })
            })
        }
    }
}
