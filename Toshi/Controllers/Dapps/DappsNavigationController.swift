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

final class DappsNavigationController: UINavigationController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override init(rootViewController: UIViewController) {
        
        if let profileData = UserDefaultsWrapper.selectedApp {
            super.init(nibName: nil, bundle: nil)
            guard let json = (try? JSONSerialization.jsonObject(with: profileData, options: [])) as? [String: Any] else { return }
            
            viewControllers = [rootViewController, ProfileViewController(profile: TokenUser(json: json))]
            configureTabBarItem()
        } else {
            super.init(rootViewController: rootViewController)
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setNavigationBarHidden(true, animated: false)
        configureTabBarItem()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureTabBarItem() {
        tabBarItem = UITabBarItem(title: Localized.tab_bar_title_dapps, image: #imageLiteral(resourceName: "tab1"), tag: 0)
        tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }

    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedApp = nil
        return super.popToRootViewController(animated: animated)
    }

    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedApp = nil
        return super.popToViewController(viewController, animated: animated)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if let colorable = viewController as? NavBarColorChanging {
            setNavigationBarColors(with: colorable)
        }

        super.pushViewController(viewController, animated: animated)

        if let viewController = viewController as? ProfileViewController {
            UserDefaultsWrapper.selectedApp = viewController.profile.json
        }
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        UserDefaultsWrapper.selectedApp = nil
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
