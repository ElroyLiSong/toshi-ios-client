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

protocol SendTokenViewConfiguratorDelegate: class {
    func didReceiveScanEvent(_ configurator: SendTokenViewConfigurator)
    func didReceiveContinueEvent(_ configurator: SendTokenViewConfigurator, params: [String: Any])
}

final class SendTokenViewConfigurator: NSObject {

    private let addressPlaceholder = "0x..."
    let inlineButtonHeight: CGFloat = 40
    let inlineButtonCornerRadius: CGFloat = 20

    weak var delegate: SendTokenViewConfiguratorDelegate?

    var layoutGuide: UILayoutGuide?

    var viewConfiguration: TokenTypeViewConfiguration {
        didSet {
            adjustViewsVisibility()
            setupSentValueText()
        }
    }

    private weak var view: UIView?

    private var isShowingFinalValueAlert = false

    private var isMaxValueSelected: Bool = false {
        didSet {
            maxButton.isSelected = isMaxValueSelected
            maxButton.backgroundColor = isMaxValueSelected ? Theme.tintColor : Theme.viewBackgroundColor
            maxButton.layer.borderWidth = isMaxValueSelected ? 0 : 1

            primaryValueTextField.isUserInteractionEnabled = !isMaxValueSelected

            primaryValueTextField.textColor = isMaxValueSelected ? Theme.placeholderTextColor : Theme.darkTextColor

            configureSymbolField()
        }
    }

    private lazy var amountTitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.text = Localized.wallet_amount_label
        label.textColor = Theme.greyTextColor
        label.font = Theme.preferredProTextMedium(range: 13...15)

        return label
    }()

    private lazy var toTitleLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.text = Localized.wallet_to_label
        label.textColor = Theme.greyTextColor
        label.font = Theme.preferredProTextMedium(range: 13...15)

        return label
    }()

    private lazy var addressTextView: PlaceholderTextView = {
        let view = PlaceholderTextView(placeholder: addressPlaceholder)
        view.font = Theme.mediumMonospaced(size: 17)
        view.text = addressPlaceholder
        view.returnKeyType = .done
        view.tintColor = Theme.tintColor
        view.textColor = Theme.greyTextColor
        view.adjustsFontForContentSizeCategory = true
        view.set(height: 40)
        view.delegate = self
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = false
        view.isEditable = true
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.textContainer.maximumNumberOfLines = 0

        return view
    }()

    private lazy var addressErrorLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.text = ""
        label.textColor = Theme.errorColor
        label.font = Theme.preferredFootnote()

        return label
    }()

    private lazy var balanceLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.text = String(format: Localized.wallet_token_balance_format, self.token.symbol, self.token.displayValueString)
        label.textColor = Theme.lightGreyTextColor
        label.font = Theme.preferredProTextRegular(range: 13...15)
        label.tag = SendTokenViews.balanceLabel.rawValue

        return label
    }()

    private lazy var secondaryValueLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.text = EthereumConverter.fiatValueString(forWei: NSDecimalNumber.zero, exchangeRate: ExchangeRateClient.exchangeRate)
        label.font = Theme.preferredHeavy()
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.height(20)
        label.tag = SendTokenViews.secondaryValueLabel.rawValue

        return label
    }()

    private lazy var primaryValueTextField: UITextField = {
        let view = UITextField(withAutoLayout: true)
        view.keyboardType = self.token.decimals == 0 ? .numberPad : .decimalPad
        view.adjustsFontSizeToFitWidth = true
        view.delegate = self
        view.tintColor = Theme.tintColor
        view.placeholder = self.token.decimals == 0 ? "0" : "0.0"
        view.font = Theme.preferredProTextBold(range: 36...40)
        view.contentVerticalAlignment = .center
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.set(height: 40)
        view.contentVerticalAlignment = .center

        return view
    }()

    private lazy var symbolField: UITextField = {
        let view = UITextField()

        view.isUserInteractionEnabled = true
        view.textColor = Theme.placeholderTextColor
        view.delegate = self
        view.font = primaryValueTextField.font
        view.contentVerticalAlignment = .center
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.set(height: 40)
        view.contentVerticalAlignment = .center
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .horizontal)

        return view
    }()

    private lazy var maxButton: UIButton = {
        let button = UIButton.borderedButton(with: Theme.lightGreyTextColor)
        button.setTitle(Localized.wallet_max_value_title, for: .normal)
        button.addTarget(self, action: #selector(maxButtonTapped(_:)), for: .touchUpInside)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.setTitleColor(Theme.lightTextColor, for: .selected)
        button.backgroundColor = Theme.viewBackgroundColor
        button.height(inlineButtonHeight)
        button.width(67)
        button.layer.cornerRadius = inlineButtonCornerRadius
        button.tag = SendTokenViews.maxButton.rawValue

        return button
    }()

    private lazy var swapButton: UIButton = {
        let button = UIButton.borderedButton(with: Theme.lightGreyTextColor)
        button.setImage(#imageLiteral(resourceName: "swap"), for: .normal)
        button.addTarget(self, action: #selector(swapButtonTapped), for: .touchUpInside)
        button.height(inlineButtonHeight)
        button.width(inlineButtonHeight)
        button.layer.cornerRadius = inlineButtonCornerRadius
        button.tag = SendTokenViews.swapButton.rawValue

        return button
    }()

    private lazy var pasteButton: UIButton = {
        let button = UIButton.borderedButton(with: Theme.lightGreyTextColor)
        button.setTitle(Localized.text_editing_options_paste, for: .normal)
        button.addTarget(self, action: #selector(pasteButtonTapped), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.height(inlineButtonHeight)
        button.layer.cornerRadius = inlineButtonCornerRadius

        return button
    }()

    private lazy var scanButton: UIButton = {
        let button = UIButton.borderedButton(with: Theme.lightGreyTextColor)
        button.setImage(#imageLiteral(resourceName: "scan"), for: .normal)
        button.setTitle(Localized.wallet_scan_QR_label, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat.smallInterItemSpacing)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: CGFloat.smallInterItemSpacing, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        button.height(inlineButtonHeight)
        button.width(button.intrinsicContentSize.width + CGFloat.smallInterItemSpacing * 2)
        button.layer.cornerRadius = inlineButtonCornerRadius

        return button
    }()

    private lazy var continueButton: ActionButton = {
        let button = ActionButton(margin: CGFloat.defaultMargin)
        button.title = Localized.continue_action_title
        button.addTarget(self, action: #selector(didTapContinueButton), for: .touchUpInside)
        button.height(50)
        button.isEnabled = false

        return button
    }()

    private lazy var valueEnablingTapGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(valueEnableTapGestureReceived(_:)))
    }()

    private lazy var addressEnablingTapGesture: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(addressEnableTapGestureReceived(_:)))
    }()

    var destinationAddress: String = "" {
        didSet {
            let isPlaceholder = destinationAddress == addressPlaceholder || destinationAddress.isEmpty
            addressTextView.textColor = isPlaceholder ? Theme.lightGreyTextColor : Theme.darkTextColor
            validateState()
        }
    }

    var isFilled: Bool {
        let valueText = primaryValueTextField.text ?? ""
        return !destinationAddress.isEmpty || !valueText.isEmpty
    }

    let token: Token
    let viewModel: SendTokenViewModel

    init(token: Token, view: UIView) {
        self.token = token
        self.viewModel = SendTokenViewModel(token: token)

        let tokenType: TokenType = token.isEtherToken ? .fiatRepresentable : .nonFiatRepresentable
        self.viewConfiguration = TokenTypeViewConfiguration(isActive: false, tokenType: tokenType, primaryValue: .token)
        self.view = view

        super.init()
        self.adjustViewsVisibility()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: .UIKeyboardDidHide, object: nil)
    }

    @objc private func valueEnableTapGestureReceived(_ gesture: UIGestureRecognizer) {
        guard !primaryValueTextField.isFirstResponder else {
            return
        }
        primaryValueTextField.becomeFirstResponder()
    }

    @objc private func addressEnableTapGestureReceived(_ gesture: UIGestureRecognizer) {
        guard !addressTextView.isFirstResponder else {
            addressTextView.resignFirstResponder()
            return
        }
        addressTextView.becomeFirstResponder()
    }

    func configureView(_ view: UIView) {
        guard let layoutGuide = layoutGuide else {
            assertionFailure("No known layout guide on configurator")
            return
        }

        let stackView = UIStackView()
        stackView.addBackground(with: Theme.viewBackgroundColor)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.axis = .vertical

        view.addSubview(stackView)
        stackView.top(to: view)
        stackView.leftToSuperview()
        stackView.rightToSuperview()

        let valueContainerView = setupValueContainerView()
        valueContainerView.addGestureRecognizer(valueEnablingTapGesture)
        stackView.addArrangedSubview(valueContainerView)
        stackView.addSpacing(CGFloat.mediumInterItemSpacing, after: valueContainerView)
        stackView.addStandardBorder(margin: CGFloat.defaultMargin)
        let addressContainerView = setupAddressContainerView()
        addressContainerView.addGestureRecognizer(addressEnablingTapGesture)
        stackView.addArrangedSubview(addressContainerView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapMainView(_:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        view.addSubview(continueButton)
        continueButton.leftToSuperview(offset: CGFloat.largeInterItemSpacing)
        continueButton.right(to: view, offset: -CGFloat.largeInterItemSpacing)
        continueButton.bottom(to: layoutGuide, offset: -CGFloat.largeInterItemSpacing)

        primaryValueTextField.becomeFirstResponder()
    }

    func updateDestinationAddress(to address: String) {
        destinationAddress = address
        addressTextView.text = address
    }

    @objc private func didTapMainView(_ gesture: UITapGestureRecognizer) {
        view?.endEditing(true)
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        validateState()
    }

    @objc private func maxButtonTapped(_ button: UIButton) {

        guard !isMaxValueSelected else {
            primaryValueTextField.text = ""
            configureSecondaryValueLabel()
            isMaxValueSelected = false
            primaryValueTextField.becomeFirstResponder()

            return
        }

        guard token.canShowFiatValue else {
            setMaxValue()
            return
        }

        isShowingFinalValueAlert = true
        let alert = UIAlertController(title: Localized.wallet_final_amount_alert_title, message: Localized.wallet_final_amount_alert_message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Localized.alert_ok_action_title, style: .default, handler: { _ in
            self.isShowingFinalValueAlert = false
            self.setMaxValue()
        })

        let cancelAction = UIAlertAction(title: Localized.cancel_action_title, style: .cancel, handler: { _ in
            self.isShowingFinalValueAlert = false
        })

        alert.addAction(okAction)
        alert.addAction(cancelAction)

        Navigator.presentModally(alert)
    }

    private func setMaxValue() {
        var primaryValueText: String?

        isMaxValueSelected = true

        switch viewConfiguration.primaryValue {
        case .token:
            primaryValueText = token.displayValueString
        case .fiat:
            if let ether = token as? EtherToken {
                primaryValueText = EthereumConverter.fiatValueString(forWei: ether.wei, exchangeRate: ExchangeRateClient.exchangeRate, withCurrencyCode: false)
            }
        }

        primaryValueTextField.text = primaryValueText
        primaryValueTextField.layoutIfNeeded()

        adjustToNewValue()
    }

    @objc private func swapButtonTapped() {

        guard primaryValueTextField.hasText else {
            viewConfiguration.primaryValue = viewConfiguration.primaryValue.opposite
            configureSymbolField()
            configureSecondaryValueLabel()
            return
        }

        let valuesTexts = viewModel.swappedValuesText(for: viewConfiguration, isMaxValueSelected: isMaxValueSelected, primaryValueText: primaryValueTextField.currentOrEmptyText)
        primaryValueTextField.text = valuesTexts.primaryValueText
        secondaryValueLabel.text = valuesTexts.secondaryValueText

        viewConfiguration.primaryValue = viewConfiguration.primaryValue.opposite

        configureSymbolField()
    }

    @objc private func pasteButtonTapped() {
        primaryValueTextField.resignFirstResponder()

        viewConfiguration.isActive = isMaxValueSelected

        if let pasteboardString = UIPasteboard.general.string, !pasteboardString.isEmpty {
            destinationAddress = pasteboardString
            addressTextView.text = pasteboardString
        }
    }

    @objc private func scanButtonTapped() {
        delegate?.didReceiveScanEvent(self)
    }

    @objc private func didTapContinueButton() {
        let valueText = primaryValueTextField.text ?? ""
        let finalValueInWeiHex = viewModel.finalValueHexString(for: viewConfiguration, valueText: valueText)

        var params: [String: Any] = [PaymentParameters.from: Cereal.shared.paymentAddress,
                                     PaymentParameters.to: destinationAddress,
                                     PaymentParameters.value: finalValueInWeiHex]

        if !token.canShowFiatValue {
            params[PaymentParameters.tokenAddress] = token.contractAddress
        }

        if isMaxValueSelected && token.canShowFiatValue {
            params[PaymentParameters.value] = PaymentParameters.maxValue
        }

        proceed(with: params)
    }

    private func proceed(with params: [String: Any]) {
        self.delegate?.didReceiveContinueEvent(self, params: params)
    }

    private func setupSentValueText() {
        adjustAddressErrorLabelHidden(to: true)
        showBalanceText()
    }

    private func validateState() {
        adjustAddressErrorLabelHidden(to: true)
        showBalanceText()

        let valueText = primaryValueTextField.text ?? ""
        let errorViews = viewModel.errorViews(for: viewConfiguration, inputValueText: valueText, address: destinationAddress)
        for errorView in errorViews {
            switch errorView {
            case .addressLabel:
                adjustAddressErrorLabelHidden(to: false)
                addressErrorLabel.text = Localized.wallet_invalid_ethereum_address_error
            case .balanceLabel:
                showInsuffisientBalanceError()
            default:
                break
            }
        }

        continueButton.isEnabled = errorViews.isEmpty && !valueText.isEmpty && !destinationAddress.isEmpty
    }

    private func showInsuffisientBalanceError() {
        adjustBalanceLabelHidden(to: false)
        balanceLabel.text = viewModel.insuffisientBalanceString(for: viewConfiguration)
        balanceLabel.textColor = Theme.errorColor
    }

    private func showBalanceText() {
        balanceLabel.text = viewModel.balanceString(for: viewConfiguration)
        balanceLabel.textColor = Theme.lightGreyTextColor
    }

    private func adjustAddressErrorLabelHidden(to hidden: Bool) {
        guard addressErrorLabel.isHidden != hidden else { return }

        addressErrorLabel.isHidden = hidden

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.view?.layoutIfNeeded()
        }, completion: nil)
    }

    private func adjustBalanceLabelHidden(to hidden: Bool) {
        guard balanceLabel.isHidden != hidden else { return }

        balanceLabel.isHidden = hidden
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.view?.layoutIfNeeded()
        }, completion: nil)
    }

    private func setupValueContainerView() -> UIView {
        let containerView = UIView()
        containerView.width(UIScreen.main.bounds.width)
        containerView.setContentCompressionResistancePriority(.required, for: .vertical)
        containerView.setContentHuggingPriority(.required, for: .vertical)

        let valueStackView = UIStackView()
        valueStackView.axis = .vertical
        valueStackView.alignment = .fill

        let margin = CGFloat.defaultMargin

        containerView.addSubview(valueStackView)
        valueStackView.leftToSuperview(offset: margin)
        valueStackView.right(to: containerView, offset: -margin)
        valueStackView.topToSuperview(offset: margin)
        valueStackView.bottomToSuperview(offset: -CGFloat.smallInterItemSpacing)
        valueStackView.addArrangedSubview(amountTitleLabel)
        valueStackView.addSpacing(margin, after: amountTitleLabel)

        let inputStackView = UIStackView()
        inputStackView.axis = .horizontal
        inputStackView.alignment = .center
        inputStackView.distribution = .equalSpacing

        let textfieldStackView = UIStackView()
        textfieldStackView.axis = .horizontal
        textfieldStackView.alignment = .center
        textfieldStackView.distribution = .fillProportionally
        textfieldStackView.addArrangedSubview(primaryValueTextField)
        textfieldStackView.addSpacing(CGFloat.smallInterItemSpacing, after: primaryValueTextField)
        textfieldStackView.addArrangedSubview(symbolField)

        inputStackView.addArrangedSubview(textfieldStackView)
        inputStackView.addSpacing(CGFloat.mediumInterItemSpacing, after: textfieldStackView)

        let buttonsStackView = UIStackView()
        buttonsStackView.axis = .horizontal
        buttonsStackView.alignment = .center
        buttonsStackView.distribution = .fillProportionally
        buttonsStackView.addWithCenterConstraint(view: maxButton)
        buttonsStackView.addSpacing(CGFloat.smallInterItemSpacing, after: maxButton)
        buttonsStackView.addWithCenterConstraint(view: swapButton)

        inputStackView.addArrangedSubview(buttonsStackView)

        valueStackView.addArrangedSubview(inputStackView)
        valueStackView.addSpacing(margin, after: inputStackView)
        valueStackView.addArrangedSubview(secondaryValueLabel)
        valueStackView.addSpacing(margin, after: secondaryValueLabel)
        valueStackView.addArrangedSubview(balanceLabel)
        valueStackView.addSpacing(CGFloat.mediumInterItemSpacing, after: balanceLabel)

        return containerView
    }

    private func setupAddressContainerView() -> UIView {
        let addressContainerView = UIView()
        addressContainerView.setContentCompressionResistancePriority(.required, for: .vertical)
        addressContainerView.setContentHuggingPriority(.required, for: .vertical)
        addressContainerView.width(UIScreen.main.bounds.width)
        let addressStackView = UIStackView()
        addressStackView.axis = .vertical
        addressStackView.alignment = .leading
        addressStackView.clipsToBounds = true

        let margin = CGFloat.defaultMargin

        addressContainerView.addSubview(addressStackView)
        addressStackView.leftToSuperview(offset: margin)
        addressStackView.right(to: addressContainerView, offset: -margin)
        addressStackView.topToSuperview(offset: margin)
        addressStackView.bottomToSuperview(offset: -margin)

        addressStackView.addArrangedSubview(toTitleLabel)
        addressStackView.addSpacing(CGFloat.largeInterItemSpacing, after: toTitleLabel)

        addressStackView.addWithDefaultConstraints(view: addressTextView, margin: CGFloat.mediumInterItemSpacing)
        addressStackView.addSpacing(CGFloat.smallInterItemSpacing, after: addressTextView)

        addressStackView.addArrangedSubview(addressErrorLabel)
        addressStackView.addSpacing(CGFloat.mediumInterItemSpacing, after: addressErrorLabel)

        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.alignment = .center

        buttonStackView.addArrangedSubview(pasteButton)
        buttonStackView.addSpacing(CGFloat.smallInterItemSpacing, after: pasteButton)
        buttonStackView.addArrangedSubview(scanButton)

        addressStackView.addArrangedSubview(buttonStackView)
        addressStackView.addSpacing(CGFloat.largeInterItemSpacing, after: buttonStackView)

        return addressContainerView
    }

    private func adjustViewsVisibility() {
        view?.layoutIfNeeded()

        // show or hide views

        maxButton.isHidden = !viewConfiguration.visibleViews.contains(.maxButton)
        swapButton.isHidden = !viewConfiguration.visibleViews.contains(.swapButton)
        balanceLabel.isHidden = !viewConfiguration.visibleViews.contains(.balanceLabel)
        secondaryValueLabel.isHidden = !viewConfiguration.visibleViews.contains(.secondaryValueLabel)

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.view?.layoutIfNeeded()
        }, completion: nil)
    }

    private func configureSymbolField() {
        guard let text = primaryValueTextField.text else { return }

        switch viewConfiguration.primaryValue {
        case .token:
            symbolField.text = token.symbol
        case .fiat:
            symbolField.text = TokenUser.current?.localCurrency
        }

        symbolField.textColor = (text.isEmpty || isMaxValueSelected) ? Theme.placeholderTextColor : Theme.darkTextColor

        symbolField.font = primaryValueTextField.font
    }

    private func configureSecondaryValueLabel() {
        secondaryValueLabel.text = viewModel.secondaryValueText(for: viewConfiguration, isMaxValueSelected: isMaxValueSelected, valueText: primaryValueTextField.text)
    }

    private func adjustToNewValue() {
        configureSymbolField()
        configureSecondaryValueLabel()

        checkInputValueAgainstBalance()
    }

    private func checkInputValueAgainstBalance() {
        let inputValue = primaryValueTextField.text ?? ""
        if viewModel.isInsuffisientBalance(for: viewConfiguration, inputValueText: inputValue) {
            showInsuffisientBalanceError()
        } else {
            showBalanceText()
        }
    }
}

extension SendTokenViewConfigurator: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        // We should ignore gesture recognizer if the view is UIControl, so action button touchUpInside control event is received
        return !(touch.view is UIControl)
    }
}

extension SendTokenViewConfigurator: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        adjustAddressErrorLabelHidden(to: true)

        if range.length == 0 && text == "\n" {
            textView.resignFirstResponder()
        }

        // We should not allow clearing the placeholder
        let isClearingPlaceholder = (textView.text == addressPlaceholder && text.isEmpty)

        // Pasting while text view is a placehlder, the string from pasteboard is with whitespace in front
        // we should just replace text with pasted string
        if textView.text == addressPlaceholder && !text.isEmpty {
            let newText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            textView.text = newText.isEmpty ? addressPlaceholder : newText
            destinationAddress = textView.text

            return false
        }

        if let currentText = textView.text,
            let textRange = Range(range, in: currentText) {
            let updatedText = currentText.replacingCharacters(in: textRange,
                                                              with: text)
            if !isClearingPlaceholder {
                destinationAddress = updatedText
            }
        }

        return !isClearingPlaceholder
    }
}

extension SendTokenViewConfigurator: UITextFieldDelegate {

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        viewConfiguration.isActive = isMaxValueSelected || isShowingFinalValueAlert
        configureSymbolField()

        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == symbolField {
            primaryValueTextField.becomeFirstResponder()
            return false
        }

        adjustAddressErrorLabelHidden(to: true)
        viewConfiguration.isActive = true
        configureSymbolField()
        checkInputValueAgainstBalance()

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if isMaxValueSelected {
            isMaxValueSelected = false
        }

        if let text = textField.text,
            let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange,
                                                       with: string)
            textField.text = updatedText
            adjustToNewValue()
        }

        return false
    }
}
