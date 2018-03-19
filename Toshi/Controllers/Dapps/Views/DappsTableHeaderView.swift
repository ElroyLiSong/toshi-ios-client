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
import QuartzCore

protocol DappsSearchHeaderViewDelegate: class {
    func didRequireCollapsedState(_ headerView: DappsTableHeaderView)
    func didRequireDefaultState(_ headerView: DappsTableHeaderView)
    func dappsSearchDidUpdateSearchText(_ headerView: DappsTableHeaderView, searchText: String)
}

final class DappsTableHeaderView: UIView {

    let collapsedStateScrollPercentage: CGFloat = 1
    let expandedStateScrollPercentage: CGFloat = 0

    private var screenWidth = UIScreen.main.bounds.width

    private(set) lazy var sizeRange: ClosedRange<CGFloat> = -280 ... (-59 - UIApplication.shared.statusBarFrame.height)
    private weak var delegate: DappsSearchHeaderViewDelegate?

    private lazy var minTextFieldWidth: CGFloat = screenWidth - (2 * 40)
    private lazy var maxTextFieldWidth: CGFloat = screenWidth - (2 * 15)

    private var heightConstraint: NSLayoutConstraint?

    private var searchStackBottomConstraint: NSLayoutConstraint?
    private var searchStackLeftConstraint: NSLayoutConstraint?
    private var searchStackRightConstraint: NSLayoutConstraint?
    private var searchStackHeightConstraint: NSLayoutConstraint?

    private var shouldShowCancelButton = false

    private lazy var expandedBackgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = Theme.tintColor
        backgroundView.isUserInteractionEnabled = false

        return backgroundView
    }()

    private lazy var collapsedBackgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .white
        backgroundView.isUserInteractionEnabled = false
        backgroundView.alpha = 0.0

        return backgroundView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.viewBackgroundColor
        label.text = Localized.dapps_search_header_title
        label.font = Theme.semibold(size: 20)
        label.textAlignment = .center

        return label
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.size(CGSize(width: 48, height: 48))
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "logo")

        return imageView
    }()

    private(set) lazy var searchTextField: InsetTextField = {
        let textField = InsetTextField(xInset: 20, yInset: 0)
        textField.delegate = self
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.placeholder = Localized.dapps_search_placeholder
        textField.borderStyle = .none
        textField.layer.cornerRadius = 5

        return textField
    }()

    private lazy var searchTextFieldBackgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.backgroundColor = Theme.searchBarColor
        backgroundView.alpha = 0.0
        backgroundView.isUserInteractionEnabled = false
        backgroundView.layer.cornerRadius = 5

        return backgroundView
    }()

    private lazy var cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.setTitle(Localized.cancel_action_title, for: .normal)
        cancelButton.setTitleColor(Theme.tintColor, for: .normal)
        cancelButton.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        cancelButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        return cancelButton
    }()

    private lazy var searchFieldStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 6 // prevents jump when typing begins

        stackView.addSubview(searchTextFieldBackgroundView)
        stackView.addArrangedSubview(searchTextField)
        searchTextField.topToSuperview()
        searchTextField.bottomToSuperview()

        searchTextFieldBackgroundView.edges(to: searchTextField)

        stackView.addArrangedSubview(cancelButton)
        cancelButton.topToSuperview()
        cancelButton.bottomToSuperview()

        cancelButton.isHidden = true

        return stackView
    }()

    // MARK: - Initialization

    /// Designated initializer
    ///
    /// - Parameters:
    ///   - frame: The frame to pass through to super.
    ///   - delegate: The delegate to notify of changes.
    init(frame: CGRect, delegate: DappsSearchHeaderViewDelegate) {
        self.delegate = delegate
        super.init(frame: frame)

        backgroundColor = .clear

        addSubviewsAndConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Setup

    private func addSubviewsAndConstraints() {
        heightConstraint = height(280)

        addSubview(expandedBackgroundView)
        expandedBackgroundView.edges(to: self)

        addSubview(collapsedBackgroundView)
        collapsedBackgroundView.edges(to: self)

        let separatorView = BorderView()
        collapsedBackgroundView.addSubview(separatorView)
        separatorView.addHeightConstraint()
        separatorView.edgesToSuperview(excluding: .top)

        addSubview(searchFieldStackView)
        addSubview(iconImageView)
        addSubview(titleLabel)

        iconImageView.size(CGSize(width: 48, height: 48))
        iconImageView.centerX(to: self)
        iconImageView.bottomToTop(of: titleLabel, offset: -(.mediumInterItemSpacing))

        titleLabel.left(to: self, offset: .mediumInterItemSpacing)
        titleLabel.right(to: self, offset: -(.mediumInterItemSpacing))
        titleLabel.bottomToTop(of: searchFieldStackView, offset: -(CGFloat.giantInterItemSpacing))

        searchStackLeftConstraint = searchFieldStackView.left(to: self, offset: 40)
        searchStackRightConstraint = searchFieldStackView.right(to: self, offset: -40)
        searchStackHeightConstraint = searchFieldStackView.height(56)
        searchStackBottomConstraint = searchFieldStackView.bottom(to: self, offset: -(.giantInterItemSpacing))
    }

    func adjustNonAnimatedProperties(to percentage: CGFloat) {
        let diff = (sizeRange.lowerBound - sizeRange.upperBound) * -1
        let height = (sizeRange.lowerBound + (percentage * diff)) * -1
        heightConstraint?.constant = height

        searchStackHeightConstraint?.constant = resize(1 - percentage, in: 36 ... 56)
        searchStackLeftConstraint?.constant = resize(1 - percentage, in: 15 ... 40)
        searchStackRightConstraint?.constant = resize(percentage, in: -40 ... -15)
        searchStackBottomConstraint?.constant = percentage.map(from: 0 ... 1, to: -40 ... -15)

        if percentage >= 1 && shouldShowCancelButton {
            cancelButton.isHidden = false
            shouldShowCancelButton = false
        }
    }

    func adjustAnimatedProperties(to percentage: CGFloat) {
        expandedBackgroundView.alpha = fadeOut(percentage, in: 0.77 ... 1)
        collapsedBackgroundView.alpha = fadeIn(percentage, in: 0.77 ... 1)
        iconImageView.alpha = fadeOut(percentage, in: 0.0 ... 0.46)
        titleLabel.alpha = fadeOut(percentage, in: 0.0 ... 0.46)

        let shadowOpacity = Float((1 - percentage).map(from: 0 ... 1, to: 0 ... 0.3))
        searchTextField.addShadow(xOffset: 1, yOffset: 1, radius: 3, opacity: shadowOpacity)

        searchTextField.backgroundColor = UIColor.white.withAlphaComponent(fadeOut(percentage, in: 0.89 ... 1))
        searchTextFieldBackgroundView.alpha = fadeIn(percentage, in: 0.89 ... 1)
        searchTextField.xInset = (1 - percentage).map(from: 0 ... 1, to: 15 ... 20)
    }

    func didScroll(to percentage: CGFloat) {
        adjustAnimatedProperties(to: percentage)
        adjustNonAnimatedProperties(to: percentage)
    }

    func cancelSearch() {
        hideCancelButton()
        searchTextField.resignFirstResponder()
        searchTextField.text = nil

        delegate?.didRequireDefaultState(self)
    }

    func showCancelButton() {
        layoutIfNeeded()
        cancelButton.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }

        shouldShowCancelButton = false
    }

    private func hideCancelButton() {
        layoutIfNeeded()

        cancelButton.isHidden = true
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    private func resize(_ percentage: CGFloat, in range: ClosedRange<CGFloat>) -> CGFloat {
        return percentage.map(from: 0 ... 1, to: range).clamp(to: range)
    }

    private func fadeIn(_ percentage: CGFloat, in range: ClosedRange<CGFloat>) -> CGFloat {
        return percentage.clamp(to: range).map(from: range, to: 0 ... 1)
    }

    private func fadeOut(_ percentage: CGFloat, in range: ClosedRange<CGFloat>) -> CGFloat {
        return 1 - percentage.clamp(to: range).map(from: range, to: 0 ... 1)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Point inside is overriden to enable swiping on the header
        if searchFieldStackView.frame.contains(point) {
            return true
        } else {
            return false
        }
    }

    @objc private func didTapCancelButton() {
        hideCancelButton()
        searchTextField.resignFirstResponder()
        searchTextField.text = nil

        delegate?.didRequireDefaultState(self)
    }
}

extension DappsTableHeaderView: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        delegate?.didRequireCollapsedState(self)

        if frame.height > -sizeRange.upperBound {
            shouldShowCancelButton = true
        } else {
            showCancelButton()
        }

        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if let text = textField.text,
            let textRange = Range(range, in: text) {
            let updatedText = text.replacingCharacters(in: textRange,
                                                       with: string)

            delegate?.dappsSearchDidUpdateSearchText(self, searchText: updatedText)
        }

        return true
    }
}
