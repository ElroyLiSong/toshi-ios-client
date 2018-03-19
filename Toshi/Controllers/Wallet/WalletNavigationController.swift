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

class WalletNavigationController: UINavigationController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return (topViewController == viewControllers.first) ? .lightContent : .default
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        tabBarItem = UITabBarItem(title: Localized.tab_bar_title_wallet, image: #imageLiteral(resourceName: "tab3"), tag: 0)
        tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }

    required init?(coder _: NSCoder) {
        fatalError("")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            self.navigationBar.prefersLargeTitles = true
        }
    }

    // MARK: - Nav Bar Color Handling

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if let colorable = viewController as? NavBarColorChanging {
            setNavigationBarColors(with: colorable)
        }

        super.pushViewController(viewController, animated: animated)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        guard let colorChangingVC = previousViewController as? NavBarColorChanging else {
            // Just call super and be done with it.
            return super.popViewController(animated: animated)
        }

        setNavigationBarColors(with: colorChangingVC)

        // Start the transition by calling super so we get a transition coordinator
        let poppedViewController = super.popViewController(animated: animated)

        transitionCoordinator?.animate(alongsideTransition: nil, completion: { [weak self] _ in
            guard let topColorChangingVC = self?.topViewController as? NavBarColorChanging else { return }
            self?.setNavigationBarColors(with: topColorChangingVC)
        })

        return poppedViewController
    }

    private var previousViewController: UIViewController? {
        guard viewControllers.count > 1 else {
            return nil
        }
        return viewControllers[viewControllers.count - 2]
    }

    private func setNavigationBarColors(with colorChangingObject: NavBarColorChanging) {
        navigationBar.tintColor = colorChangingObject.navTintColor
        navigationBar.barTintColor = colorChangingObject.navBarTintColor
        navigationBar.shadowImage = colorChangingObject.navShadowImage
        if let titleColor = colorChangingObject.navTitleColor {
            navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: titleColor]
        } else {
            navigationBar.titleTextAttributes = nil
        }
    }
}

// MARK: - Color Changing Protocol

/*
 Generally ganked from https://gist.github.com/Sorix/1d8543b18cfd76c12c36525bc280a35d

 Workaround for the fact that when you pop a view controller non-interactively, the colors,
 especially the title color, do not render correctly after the pop.

 Will add Radar here once filed.
 */

protocol NavBarColorChanging: class {

    var navTintColor: UIColor? { get }
    var navBarTintColor: UIColor? { get }
    var navTitleColor: UIColor? { get }
    var navShadowImage: UIImage? { get }
}

extension WalletViewController: NavBarColorChanging {
    var navTintColor: UIColor? { return nil }
    var navBarTintColor: UIColor? { return Theme.tintColor }
    var navTitleColor: UIColor? { return Theme.lightTextColor }
    var navShadowImage: UIImage? { return UIImage() }
}

extension DappsViewController: NavBarColorChanging {
    var navTintColor: UIColor? { return nil }
    var navBarTintColor: UIColor? { return Theme.tintColor }
    var navTitleColor: UIColor? { return Theme.lightTextColor }
    var navShadowImage: UIImage? { return UIImage() }
}

extension TokenEtherDetailViewController: NavBarColorChanging {
    var navTintColor: UIColor? { return Theme.tintColor }
    var navBarTintColor: UIColor? { return Theme.navigationBarColor }
    var navTitleColor: UIColor? { return Theme.darkTextColor }
    var navShadowImage: UIImage? { return nil }
}

extension DappViewController: NavBarColorChanging {
    var navTintColor: UIColor? { return nil }
    var navBarTintColor: UIColor? { return nil }
    var navTitleColor: UIColor? { return Theme.darkTextColor }
    var navShadowImage: UIImage? { return UIImage() }
}

extension DappsListViewController: NavBarColorChanging {
    var navTintColor: UIColor? { return Theme.tintColor }
    var navBarTintColor: UIColor? { return Theme.navigationBarColor }
    var navTitleColor: UIColor? { return Theme.darkTextColor }
    var navShadowImage: UIImage? { return nil }
}

extension SOFAWebController: NavBarColorChanging {
    var navTintColor: UIColor? { return Theme.tintColor }
    var navBarTintColor: UIColor? { return Theme.navigationBarColor }
    var navTitleColor: UIColor? { return Theme.darkTextColor }
    var navShadowImage: UIImage? { return nil }
}

extension CollectibleViewController: NavBarColorChanging {
    var navTintColor: UIColor? { return Theme.tintColor }
    var navBarTintColor: UIColor? { return Theme.navigationBarColor }
    var navTitleColor: UIColor? { return Theme.darkTextColor }
    var navShadowImage: UIImage? { return nil }
}
