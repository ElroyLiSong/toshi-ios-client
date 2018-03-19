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
import UIKit

protocol DappInfoDelegate: class {
    func dappInfoViewDidReceiveCategoryDetailsEvent(_ cell: DappInfoView, categoryId: Int, categoryName: String)
    func dappInfoViewDidReceiveDappDetailsEvent(_ cell: DappInfoView)
}

final class DappInfoView: UIView {

    weak var delegate: DappInfoDelegate?

    var imageViewPath: String? {
        didSet {
            retrieveAvatar()
        }
    }

    var categoriesInfo: DappCategoryInfo? {
        didSet {
            setupCategoriesNamesText()
        }
    }

    private(set) lazy var leftImageView: UIImageView = {
        let leftImageView = UIImageView()
        leftImageView.contentMode = .scaleAspectFill
        leftImageView.clipsToBounds = true
        leftImageView.size(CGSize(width: 78, height: 78))
        leftImageView.layer.cornerRadius = 10

        return leftImageView
    }()

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.preferredDisplayName()
        label.textAlignment = .center

        return label
    }()

    private(set) lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = Theme.proTextRegular(size: 15)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        return label
    }()

    private(set) lazy var urlLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.lightGreyTextColor
        label.font = Theme.proTextRegular(size: 15)

        return label
    }()

    private lazy var categoriesTextView: UITextView = {
        let view = UITextView()
        view.isUserInteractionEnabled = true
        view.isScrollEnabled = false
        view.isEditable = false
        view.contentMode = .topLeft
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.textContainer.maximumNumberOfLines = 0
        view.delegate = self
        view.dataDetectorTypes = [.link]

        view.linkTextAttributes = [NSAttributedStringKey.foregroundColor.rawValue: Theme.tintColor]

        return view
    }()

    private lazy var openButton: ActionButton = {
        let button = ActionButton(margin: .defaultMargin)
        button.title = Localized.dapp_button_enter
        button.addTarget(self,
                         action: #selector(didTapOpenButton(_:)),
                         for: .touchUpInside)

        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubviewsAndConstraints()
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviewsAndConstraints() {
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.distribution = .fill

        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal
        horizontalStackView.distribution = .fill
        horizontalStackView.alignment = .center

        horizontalStackView.addArrangedSubview(leftImageView)

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fillProportionally
        stackView.setContentHuggingPriority(.required, for: .vertical)
        horizontalStackView.addSpacing(.defaultMargin, after: leftImageView)
        horizontalStackView.addArrangedSubview(stackView)

        mainStackView.addArrangedSubview(horizontalStackView)
        addSubview(mainStackView)

        mainStackView.top(to: self, offset: .spacingx4)
        mainStackView.bottom(to: self, offset: -BasicTableViewCell.imageMargin)
        mainStackView.left(to: self, offset: .defaultMargin)
        mainStackView.right(to: self, offset: -.defaultMargin)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(urlLabel)

        mainStackView.addSpacing(.spacingx4, after: horizontalStackView)
        mainStackView.addArrangedSubview(categoriesTextView)

        mainStackView.addSpacing(.spacingx4, after: categoriesTextView)
        mainStackView.addArrangedSubview(descriptionLabel)
        mainStackView.addSpacing(.spacingx4, after: descriptionLabel)
        mainStackView.addArrangedSubview(openButton)
    }

    private func setupCategoriesNamesText() {
        guard let categoriesInfo = self.categoriesInfo else {
            categoriesTextView.text = ""
            return
        }

        var namesString = ""
        let commaAndWhiteSpaceString = ", "
        let attributedString = NSMutableAttributedString()
        let attributedCommaString = NSAttributedString(string: commaAndWhiteSpaceString)

        for (categoryId, categoryName) in categoriesInfo {

            if attributedString.length > 0 {
                attributedString.append(attributedCommaString)
                namesString.append(commaAndWhiteSpaceString)
            }

            let categoryNameString = NSAttributedString(string: categoryName)
            attributedString.append(categoryNameString)
            namesString.append(categoryName)

            guard let range = namesString.range(of: categoryName) else {
                return
            }

            attributedString.addAttribute(.link, value: String(categoryId), range: NSRange(location: range.lowerBound.encodedOffset, length: categoryName.count))
        }

        attributedString.addAttribute(.font, value: Theme.proTextSemibold(size: 15), range: NSRange(location: 0, length: attributedString.length))

        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.lineSpacing = .smallInterItemSpacing
        attributedString.addAttribute(.paragraphStyle, value: mutableParagraphStyle, range: NSRange(location: 0, length: attributedString.length))

        categoriesTextView.attributedText = attributedString
    }

    private func retrieveAvatar() {
        guard let path = imageViewPath else { return }

        AvatarManager.shared.avatar(for: path) { [weak self] image, downloadedImagePath in

            guard let path = self?.imageViewPath else { return }

            if downloadedImagePath == path {
                self?.leftImageView.image = image
            }
        }
    }

    @objc private func didTapOpenButton(_ sender: UIButton) {
        delegate?.dappInfoViewDidReceiveDappDetailsEvent(self)
    }
}

extension DappInfoView: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        guard let categoryId = Int(URL.absoluteString) else { return false }
        guard let categoryName = categoriesInfo?[categoryId] else { return false }

        delegate?.dappInfoViewDidReceiveCategoryDetailsEvent(self, categoryId: categoryId, categoryName: categoryName)

        return false
    }
}
