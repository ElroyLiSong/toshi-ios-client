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

final class TokenEtherDetailViewController: UIViewController {

    private lazy var iconImageView: AvatarImageView = {
        let imageView = AvatarImageView()
        imageView.contentMode = .scaleAspectFit

        imageView.width(.defaultAvatarHeight)
        imageView.height(.defaultAvatarHeight)

        imageView.contentMode = .scaleAspectFit

        return imageView
    }()

    private lazy var tokenValueLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.preferredTitle3(range: 24...38)
        label.textColor = Theme.darkTextColor
        label.textAlignment = .center

        return label
    }()

    private lazy var fiatValueLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.preferredTitle3(range: 15...25)
        label.textColor = Theme.darkTextHalfAlpha
        label.textAlignment = .center

        return label
    }()

    private lazy var sendButton: ActionButton = {
        let button = ActionButton(margin: 0, cornerRadius: 4)
        button.title = Localized.wallet_token_detail_send
        button.addTarget(self,
                         action: #selector(sendButtonTapped),
                         for: .touchUpInside)

        return button
    }()

    private lazy var receiveButton: ActionButton = {
        let button = ActionButton(margin: 0, cornerRadius: 4)
        button.title = Localized.wallet_token_detail_receive
        button.addTarget(self,
                         action: #selector(receiveButtonTapped),
                         for: .touchUpInside)

        return button
    }()

    private var token: Token

    var tokenContractAddress: String {
        return token.contractAddress
    }

    // MARK: - Initialization

    init(token: Token) {
        self.token = token

        super.init(nibName: nil, bundle: nil)

        let background = setupContentBackground()
        setupMainStackView(with: background)
        view.backgroundColor = Theme.lightGrayBackgroundColor

        configure(for: token)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Setup

    private func setupContentBackground() -> UIView {
        let background = UIView()
        background.backgroundColor = Theme.viewBackgroundColor
        view.addSubview(background)

        background.top(to: layoutGuide())
        background.leftToSuperview()
        background.rightToSuperview()

        let bottomBorder = BorderView()
        background.addSubview(bottomBorder)

        bottomBorder.edgesToSuperview(excluding: .top)
        bottomBorder.addHeightConstraint()

        return background
    }

    private func setupMainStackView(with background: UIView) {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .vertical

        background.addSubview(stackView)

        stackView.topToSuperview(offset: .giantInterItemSpacing)
        stackView.leftToSuperview(offset: .spacingx3)
        stackView.rightToSuperview(offset: .spacingx3)
        stackView.bottomToSuperview(offset: -.largeInterItemSpacing)

        stackView.addArrangedSubview(iconImageView)
        stackView.addSpacing(.mediumInterItemSpacing, after: iconImageView)

        stackView.addWithDefaultConstraints(view: tokenValueLabel)

        addFiatValueIfNeeded(to: stackView, after: tokenValueLabel)

        addButtons(to: stackView)
    }

    private func addFiatValueIfNeeded(to stackView: UIStackView, after previousView: UIView) {
        let bottomView: UIView
        if token.canShowFiatValue == true {
            stackView.addSpacing(.smallInterItemSpacing, after: previousView)
            stackView.addWithDefaultConstraints(view: fiatValueLabel)
            bottomView = fiatValueLabel
        } else {
            bottomView = previousView
        }

        stackView.addSpacing(.giantInterItemSpacing, after: bottomView)
    }

    private func addButtons(to stackView: UIStackView) {
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.spacing = .mediumInterItemSpacing

        stackView.addWithDefaultConstraints(view: buttonStackView)

        buttonStackView.addArrangedSubview(sendButton)
        buttonStackView.addArrangedSubview(receiveButton)
    }

    // MARK: - Setup For Token

    private func configure(for token: Token) {
        title = token.name

        if let ether = token as? EtherToken {
            iconImageView.image = token.localIcon
            tokenValueLabel.text = EthereumConverter.ethereumValueString(forWei: ether.wei, fractionDigits: 6)
            fiatValueLabel.text = EthereumConverter.fiatValueString(forWei: ether.wei, exchangeRate: ExchangeRateClient.exchangeRate)
        } else {
            tokenValueLabel.text = "\(token.displayValueString) \(token.symbol)"
            guard let tokenIcon = token.icon else { return }

            AvatarManager.shared.avatar(for: tokenIcon) { [weak self] image, _ in
                self?.iconImageView.image = image
            }
        }
    }

    // MARK: - Action Targets

    @objc private func sendButtonTapped() {
        let sendTokenController = SendTokenViewController(token: token, tokenType: token.canShowFiatValue ? .fiatRepresentable : .nonFiatRepresentable)
        sendTokenController.delegate = self
        let navigationController = UINavigationController(rootViewController: sendTokenController)

        Navigator.presentModally(navigationController)
    }

    @objc private func receiveButtonTapped() {
        guard let screenshot = tabBarController?.view.snapshotView(afterScreenUpdates: false) else {
            assertionFailure("Could not screenshot?!")
            return
        }
        
        let walletQRController = WalletQRCodeViewController(address: Cereal.shared.paymentAddress, backgroundView: screenshot)
        walletQRController.modalTransitionStyle = .crossDissolve
        present(walletQRController, animated: true)
    }

    func update(with token: Token) {
        self.token = token
        configure(for: token)
    }
}

extension TokenEtherDetailViewController: SendTokenViewControllerDelegate {

    func sendTokenControllerDidFinish(_ controller: UIViewController?) {
        controller?.dismiss(animated: true) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
