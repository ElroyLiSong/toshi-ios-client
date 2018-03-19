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

typealias WalletItemResults = (_ apps: [WalletItem]?, _ error: ToshiError?) -> Void

enum WalletItemType: Int {
    case token
    case collectibles
}

protocol WalletDatasourceDelegate: class {
    func walletDatasourceDidReload(_ datasource: WalletDatasource, cachedResult: Bool)
}

final class WalletDatasource {

    private let tokenCacheKey: NSString = "Tokens"
    private let collectiblesCacheKey: NSString = "Collectibles"

    weak var delegate: WalletDatasourceDelegate?

    var itemsType: WalletItemType = .token {
        didSet {
            loadItems()
        }
    }

    private(set) var items: [WalletItem] = []
    private lazy var cache = NSCache<NSString, AnyObject>()

    init(delegate: WalletDatasourceDelegate?) {
        self.delegate = delegate
    }

    var numberOfItems: Int {
        return items.count
    }

    var isEmpty: Bool {
        return numberOfItems == 0
    }

    var contentDescription: String? {
        switch itemsType {
        case .token:
            return !isEmpty ? Localized.wallet_tokens_description : nil
        case .collectibles:
            return nil
        }
    }

    var emptyStateTitle: String {
        switch itemsType {
        case .token:
            return Localized.wallet_empty_tokens_title
        case .collectibles:
            return Localized.wallet_empty_collectibles_title
        }
    }

    var emptyStateDetails: String? {
        switch itemsType {
        case .token:
            return Localized.wallet_empty_tokens_description
        case .collectibles:
            return nil
        }
    }

    /// Determines if need to reload based on push notification userInfo
    static func shouldReload(basedOn userInfo: [AnyHashable: Any]) -> Bool {
        guard let sofaPayload = userInfo[SofaType.key] as? String, !sofaPayload.isEmpty else { return false }

        // Reload if token payment sofa message
        guard sofaPayload.hasPrefix(SofaType.tokenPayment.rawValue) else {

            // Or reload if payment sofa message
            guard let payment = SofaWrapper.wrapper(content: sofaPayload) as? SofaPayment, payment.status == .confirmed else { return false }
            return true
        }

        return true
    }

    func item(at index: Int) -> WalletItem? {
        guard index < items.count else {
            assertionFailure("Failed retrieve wallet item due to invalid index: \(index)")
            return nil
        }

        return items[index]
    }

    func loadItems(completion: ((Bool) -> Void)? = nil) {
        items = []

        switch itemsType {
        case .token:
            loadTokens(completion: completion)
        case .collectibles:
            loadCollectibles(completion: completion)
        }
    }

    private func loadTokens(completion: ((Bool) -> Void)? = nil) {
        var loadedItems: [WalletItem] = []

        useCachedObjectIfPresent(for: tokenCacheKey)

        EthereumAPIClient.shared.getBalance(fetchedBalanceCompletion: { [weak self] balance, error in

            guard error == nil else {
                completion?(false)

                guard let strongSelf = self else { return }
                strongSelf.delegate?.walletDatasourceDidReload(strongSelf, cachedResult: false)

                return
            }

            if balance.floatValue > 0 {
                let etherToken = EtherToken(valueInWei: balance)
                loadedItems.append(etherToken)
            } // else, don't show ether balance.

            EthereumAPIClient.shared.getTokens { items, error in
                guard let strongSelf = self else { return }

                guard error == nil else {
                    completion?(false)
                    strongSelf.delegate?.walletDatasourceDidReload(strongSelf, cachedResult: false)

                    return
                }

                loadedItems.append(contentsOf: items)
                strongSelf.cacheObjects(loadedItems, for: strongSelf.tokenCacheKey)

                completion?(true)
                guard strongSelf.itemsType == .token else { return }
                strongSelf.items = loadedItems
                strongSelf.delegate?.walletDatasourceDidReload(strongSelf, cachedResult: false)
            }
        })
    }
    
    private func loadCollectibles(completion: ((Bool) -> Void)? = nil) {
        useCachedObjectIfPresent(for: collectiblesCacheKey)

        EthereumAPIClient.shared.getCollectibles { [weak self] items, error in
            guard let strongSelf = self else { return }

            guard error == nil else {
                completion?(false)
                strongSelf.delegate?.walletDatasourceDidReload(strongSelf, cachedResult: false)

                return
            }

            strongSelf.cacheObjects(items, for: strongSelf.collectiblesCacheKey)
            guard strongSelf.itemsType == .collectibles else { return }

            completion?(true)
            strongSelf.items = items
            strongSelf.delegate?.walletDatasourceDidReload(strongSelf, cachedResult: false)
        }
    }
    
    private func cacheObjects(_ objects: [WalletItem], for key: NSString) {
        cache.setObject(objects as AnyObject, forKey: key)
    }

    private func useCachedObjectIfPresent(for key: NSString) {
        if let cachedVersion = cache.object(forKey: key) as? [WalletItem] {
            items = cachedVersion
        }

        delegate?.walletDatasourceDidReload(self, cachedResult: true)
    }
}
