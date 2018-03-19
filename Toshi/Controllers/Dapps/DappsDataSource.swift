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

enum DappsDataSourceItemType {
    case dappSearched
    case dappFront
    case searchWithGoogle
    case goToUrl
    case seeAll
}

struct DappsDataSourceItem {
    let type: DappsDataSourceItemType
    private var title: String?
    private var details: String?
    private var iconPath: String?
    private(set) var dapp: Dapp?

    init(type: DappsDataSourceItemType, title: String? = nil, details: String? = nil, iconPath: String? = nil) {
        self.type = type
        self.title = title
        self.details = details
        self.iconPath = iconPath
    }

    init(type: DappsDataSourceItemType, dapp: Dapp) {
        self.type = type
        self.dapp = dapp
    }

    var displayTitle: String? {
        return dapp?.name ?? title
    }

    var displayDetails: String? {
        return dapp?.description ?? details
    }

    var itemIconPath: String? {
        return dapp?.avatarPath ?? iconPath
    }
}

struct DappsDataSourceSection {
    var name: String?
    var categoryId: Int?
    var items: [DappsDataSourceItem] = []

    init(name: String? = nil, categoryId: Int? = nil, items: [DappsDataSourceItem]) {
        self.name = name
        self.items = items
        self.categoryId = categoryId
    }
}

enum DappsDataSourceMode {
    case frontPage
    case allOrFiltered
}

protocol DappsDataSourceDelegate: class {
    func dappsDataSourcedidReload(_ dataSource: DappsDataSource)
    func dappsDataSourceDidEncounterError(_ dataSource: DappsDataSource, _ error: ToshiError)
}

extension DappsDataSourceDelegate {

    // We can define default behaviour of showing an alert with relevant error message
    func dappsDataSourceDidEncounterError(_ dataSource: DappsDataSource, _ error: ToshiError) {
        let alert = UIAlertController.dismissableAlert(title: error.localizedDescription)
        Navigator.presentModally(alert)
    }
}

struct DappsQueryData {

    var isSearching: Bool
    var searchText: String
    var limit: Int
    var offset: Int
    var categoryId: Int?

    init(searchText: String = "", limit: Int = 100, offset: Int = 0, categoryId: Int? = nil, isSearching: Bool = false) {
        self.searchText = searchText
        self.limit = limit
        self.offset = offset
        self.categoryId = categoryId
        self.isSearching = isSearching
    }
    
    var mode: DappsDataSourceMode {
        guard isSearching || !searchText.isEmpty || categoryId != nil else { return .frontPage }
        return .allOrFiltered
    }

    var shouldResetFetchedDapps: Bool {
        return offset == 0 || mode == .frontPage
    }
}

final class DappsDataSource {

    weak var delegate: DappsDataSourceDelegate?

    private var content: [DappsDataSourceSection] = []
    private(set) var categoriesInfo: DappCategoryInfo?

    private let idClient = IDAPIClient.shared

    private lazy var reloadOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        queue.name = "Reload dapps queue"

        return queue
    }()

    private(set) var fetchedDappsItems: [DappsDataSourceItem] = []
    private var nextOffsetToFetch: Int?

    var queryData: DappsQueryData {
        didSet {
            fetchItems()
        }
    }

    var mode: DappsDataSourceMode { return queryData.mode }

    init(mode: DappsDataSourceMode) {
        self.queryData = DappsQueryData()
    }

    func cancelSearch() {
        // We want to trigger queryData setter only once here, after both searchText and isSearching are changed, not twice
        // as it will cause table view reload animation glitch. Thus we are pulling this setup to a separate variable
        var presentQueryData = queryData
        presentQueryData.searchText = ""
        presentQueryData.isSearching = false

        queryData = presentQueryData
    }

    private func fetchFrontPage() {
        reloadOperationQueue.cancelAllOperations()

        let operation = BlockOperation()
        weak var weakOperation = operation

        operation.addExecutionBlock { [weak self] in

            guard let strongSelf = self, let strongOperation = weakOperation else { return }

            DirectoryAPIClient.shared.getDappsFrontPage(completion: { dappsFrontPage, error in
                guard !strongOperation.isCancelled else { return }

                strongSelf.categoriesInfo = dappsFrontPage?.categoriesInfo

                if let encounteredError = error {
                    DispatchQueue.main.async {
                        strongSelf.delegate?.dappsDataSourceDidEncounterError(strongSelf, encounteredError)
                    }
                    return
                }

                guard let frontPage = dappsFrontPage else { return }
                var results: [DappsDataSourceSection] = []

                // Fetched categories

                var fetchedDappsSections: [DappsDataSourceSection] = []

                for (index, category) in frontPage.categories.enumerated() {

                    var items = category.dapps.map { DappsDataSourceItem(type: .dappFront, dapp: $0) }

                    if index == frontPage.categories.count - 1 {
                        items.append(DappsDataSourceItem(type: .seeAll, title: Localized.dapps_see_all_button_title))
                    }

                    fetchedDappsSections.append(DappsDataSourceSection(name: frontPage.categoriesInfo[category.categoryId], categoryId: category.categoryId, items: items))
                }

                guard !strongOperation.isCancelled else { return }

                results.append(contentsOf: fetchedDappsSections)

                DispatchQueue.main.async {
                    strongSelf.content = results
                    strongSelf.delegate?.dappsDataSourcedidReload(strongSelf)
                }
            })
        }

        reloadOperationQueue.addOperation(operation)
    }

    private func fetchAllOrFilteredDapps() {
        reloadOperationQueue.cancelAllOperations()

        let operation = BlockOperation()
        weak var weakOperation = operation

        operation.addExecutionBlock { [weak self] in

            guard let strongSelf = self, let strongOperation = weakOperation else { return }

            var results: [DappsDataSourceSection] = []
            results.append(strongSelf.resultsForSearchText(strongSelf.queryData.searchText))

            DirectoryAPIClient.shared.getQueriedDapps(queryData: strongSelf.queryData, completion: { queriedResults, error in

                guard !strongOperation.isCancelled else { return }

                strongSelf.categoriesInfo = queriedResults?.results.categories

                if let searchedText = queriedResults?.query {
                    guard searchedText == strongSelf.queryData.searchText else { return }
                }

                if let encounteredError = error {
                    strongSelf.delegate?.dappsDataSourceDidEncounterError(strongSelf, encounteredError)
                    return
                }

                // Fetched dapps section
                if let items = queriedResults?.results.dapps.map({ dapp -> DappsDataSourceItem in
                    return DappsDataSourceItem(type: .dappSearched, dapp: dapp)
                }), !items.isEmpty {
                    strongSelf.fetchedDappsItems.append(contentsOf: items)
                    results.append(DappsDataSourceSection(name: Localized.dapps_section_title, items: strongSelf.fetchedDappsItems))
                }

                guard !strongOperation.isCancelled else { return }

                if let limit = queriedResults?.limit,
                    let offset = queriedResults?.offset,
                    let total = queriedResults?.total, limit + offset < total {

                    strongSelf.nextOffsetToFetch = strongSelf.queryData.offset + limit
                }

                DispatchQueue.main.async {
                    strongSelf.content = results
                    strongSelf.delegate?.dappsDataSourcedidReload(strongSelf)
                }
            })
        }

        reloadOperationQueue.addOperation(operation)
    }

    func resultsForSearchText(_ searchText: String) -> DappsDataSourceSection {
        var items: [DappsDataSourceItem] = []

        // Go to URL item
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let item = DappsDataSourceItem(type: . searchWithGoogle, title: searchText)

            items.append(item)
        }

        // Search with Google item
        if let possibleURLString = searchText.asPossibleURLString,
            possibleURLString.isValidURL {
            let item = DappsDataSourceItem(type: .goToUrl, title: searchText)
            items.append(item)
        }

        return DappsDataSourceSection(items: items)
    }

    func adjustToSearchText(_ searchText: String) {
        content = [self.resultsForSearchText(searchText)]
        delegate?.dappsDataSourcedidReload(self)
    }

    func cancelFetch() {
        reloadOperationQueue.cancelAllOperations()
    }

    // MARK: - Public Data source API

    var numberOfSections: Int {
        return content.count
    }

    func numberOfItems(in section: Int) -> Int {
        guard section < content.count else { return 0 }
        let dappsSection = content[section]
        return dappsSection.items.count
    }

    func fetchItems() {
        if queryData.shouldResetFetchedDapps {
            fetchedDappsItems = []
        }

        switch mode {
        case .frontPage:
            fetchFrontPage()
        case .allOrFiltered:
            fetchAllOrFilteredDapps()
        }
    }

    func fetchNextPage() {
        guard let nextOffset = nextOffsetToFetch else { return }

        nextOffsetToFetch = nil
        queryData.offset = nextOffset
    }

    func reloadWithSearchText(_ searchText: String) {
        queryData.searchText = searchText
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> DappsDataSourceItem? {
        guard indexPath.section < content.count else { return nil }

        let section = content[indexPath.section]
        guard indexPath.row < section.items.count else { return nil }

        return section.items[indexPath.row]
    }

    func section(at index: Int) -> DappsDataSourceSection? {
        guard index < content.count else { return nil }

        return content[index]
    }
}
