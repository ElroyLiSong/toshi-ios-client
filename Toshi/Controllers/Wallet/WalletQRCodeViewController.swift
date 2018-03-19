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

final class WalletQRCodeViewController: UIViewController {

    private let cornerRadius: CGFloat = 8

    private lazy var qrCodeImageView: UIImageView = {
        let imageView = UIImageView()

        let qrCodeSize: CGFloat = 140
        imageView.width(qrCodeSize)
        imageView.height(qrCodeSize)

        return imageView
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton()

        button.setImage(#imageLiteral(resourceName: "close_icon"), for: .normal)
        button.tintColor = Theme.tintColor
        button.width(.defaultButtonHeight)
        button.height(.defaultButtonHeight)

        button.accessibilityLabel = Localized.accessibility_close
        button.addTarget(self,
                         action: #selector(closeButtonTapped),
                         for: .touchUpInside)

        return button
    }()

    private let buttonCornerRadius: CGFloat = 6

    private lazy var shareButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addBorder(ofColor: Theme.tintColor)
        button.layer.cornerRadius = cornerRadius
        button.setTitle(Localized.share_action_title, for: .normal)
        button.setTitleColor(Theme.tintColor, for: .normal)
        button.addTarget(self,
                         action: #selector(shareButtonTapped),
                         for: .touchUpInside)

        return button
    }()

    private lazy var copyButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addBorder(ofColor: Theme.tintColor)
        button.layer.cornerRadius = cornerRadius
        button.setTitle(Localized.copy_action_title, for: .normal)
        button.setTitleColor(Theme.tintColor, for: .normal)
        button.addTarget(self,
                         action: #selector(copyButtonTapped),
                         for: .touchUpInside)

        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.darkTextColor
        label.font = Theme.preferredRegularMedium()
        label.text = Localized.wallet_address_title
        
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.darkTextHalfAlpha
        label.numberOfLines = 0
        label.font = Theme.preferredFootnote()
        label.text = Localized.wallet_address_description
        label.textAlignment = .center

        return label
    }()

    private lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = Theme.preferredRegularMonospaced()
        label.textAlignment = .center

        return label
    }()

    private let address: String

    // MARK: - Initialization

    init(address: String, backgroundView: UIView) {
        self.address = address.toChecksumEncodedAddress() ?? address

        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .black
        view.addSubview(backgroundView)
        backgroundView.alpha = 0.2

        let container = UIView()
        container.backgroundColor = Theme.viewBackgroundColor
        container.layer.cornerRadius = cornerRadius

        view.addSubview(container)

        container.leftToSuperview(offset: .largeInterItemSpacing)
        container.rightToSuperview(offset: .largeInterItemSpacing)
        container.centerXToSuperview()
        container.centerYToSuperview()

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill

        container.addSubview(stackView)

        stackView.topToSuperview(offset: .largeInterItemSpacing)
        stackView.leftToSuperview(offset: .largeInterItemSpacing)
        stackView.rightToSuperview(offset: .largeInterItemSpacing)
        stackView.bottomToSuperview(offset: -.largeInterItemSpacing)

        stackView.addArrangedSubview(titleLabel)
        stackView.addSpacing(.smallInterItemSpacing, after: titleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addSpacing(.giantInterItemSpacing, after: descriptionLabel)
        stackView.addArrangedSubview(qrCodeImageView)
        stackView.addSpacing(.giantInterItemSpacing, after: qrCodeImageView)
        stackView.addArrangedSubview(addressLabel)
        stackView.addSpacing(.largeInterItemSpacing, after: addressLabel)
        setupButtons(in: stackView)

        setupCloseButton(in: container)

        addressLabel.text = self.address.toLines(count: 2)
        qrCodeImageView.image = QRCodeGenerator.qrCodeImage(for: .ethereumAddress(address: self.address))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Use the other initializer!")
    }

    // MARK: - View Setup

    private func setupCloseButton(in view: UIView) {
        view.addSubview(closeButton)

        closeButton.topToSuperview()
        closeButton.leadingToSuperview()
    }

    private func setupButtons(in stackView: UIStackView) {
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = .smallInterItemSpacing

        stackView.addWithDefaultConstraints(view: buttonStackView)
        
        buttonStackView.height(.defaultButtonHeight)

        buttonStackView.addArrangedSubview(copyButton)
        buttonStackView.addArrangedSubview(shareButton)
    }

    // MARK: - Action Targets

    @objc private func closeButtonTapped() {
        self.dismiss(animated: true)
    }

    @objc private func shareButtonTapped() {
        shareWithSystemSheet(item: address)
    }

    @objc private func copyButtonTapped() {
        copyToClipboardWithGenericAlert(address)
    }
}

// MARK: - Mix-in extensions

extension WalletQRCodeViewController: ClipboardCopying { /* mix-in */ }
extension WalletQRCodeViewController: SystemSharing { /* mix-in */ }
