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

// MARK: - Profiles View Controller Type

public enum ProfilesViewControllerType {
    case favorites
    case newChat
    case newGroupChat
    case updateGroupChat
    
    var title: String {
        switch self {
        case .favorites:
            return Localized("profiles_navigation_title_favorites")
        case .newChat:
            return Localized("profiles_navigation_title_new_chat")
        case .newGroupChat:
            return Localized("profiles_navigation_title_new_group_chat")
        case .updateGroupChat:
            return Localized("profiles_navigation_title_update_group_chat")
        }
    }
}

protocol ProfilesListCompletionOutput: class {
    func didFinish(_ controller: ProfilesViewController, selectedProfilesIds: [String])
}

// MARK: - Profiles View Controller

final class ProfilesViewController: UIViewController {

    let type: ProfilesViewControllerType
    private var searchBarText: String = ""

    private(set) var selectedProfiles = Set<TokenUser>()

    private(set) weak var output: ProfilesListCompletionOutput?

    let emptyView = EmptyView(title: Localized("favorites_empty_title"), description: Localized("favorites_empty_description"), buttonTitle: Localized("invite_friends_action_title"))
    var shouldShowEmptyView: Bool { return type == .favorites }

    var scrollView: UIScrollView {
        switch type {
        case .favorites:
            return tableView
        case .newChat,
             .newGroupChat,
             .updateGroupChat:
            return searchResultView
        }
    }

    var scrollViewBottomInset: CGFloat = 0.0

    private lazy var searchResultView: BrowseSearchResultView = {
        let view = BrowseSearchResultView()
        view.searchDelegate = self
        view.isHidden = true
        view.isMultipleSelectionMode = isMultipleSelectionMode

        return view
    }()

    // MARK: - Lazy Vars

    private lazy var cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancel(_:)))
    private lazy var doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapDone(_:)))
    private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd(_:)))

    private lazy var tableView: UITableView = {
        let tableView = UITableView()

        BasicTableViewCell.register(in: tableView)
        tableView.estimatedRowHeight = 80
        tableView.backgroundColor = Theme.viewBackgroundColor
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self

        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.dimsBackgroundDuringPresentation = false
        controller.hidesNavigationBarDuringPresentation = false
        controller.searchBar.delegate = self
        controller.searchBar.barTintColor = Theme.viewBackgroundColor
        controller.searchBar.tintColor = Theme.tintColor

        switch type {
        case .favorites:
            controller.searchBar.placeholder = Localized("profiles_search_favorites_placeholder")
        case .newChat,
             .newGroupChat,
             .updateGroupChat:
            controller.searchBar.placeholder = Localized("profiles_search_users_placeholder")
        }

        guard #available(iOS 11.0, *) else {
            controller.searchBar.searchBarStyle = .minimal
            controller.searchBar.backgroundColor = Theme.viewBackgroundColor
            controller.searchBar.layer.borderWidth = .lineHeight
            controller.searchBar.layer.borderColor = Theme.borderColor.cgColor

            return controller
        }

        let searchField = controller.searchBar.value(forKey: "searchField") as? UITextField
        searchField?.backgroundColor = Theme.inputFieldBackgroundColor

        return controller
    }()

    private var isMultipleSelectionMode: Bool {
        switch type {
        case .newGroupChat,
             .updateGroupChat:
            return true
        case .newChat,
             .favorites:
            return false
        }
    }

    private(set) var dataSource: ProfilesDataSource

    // MARK: - Initialization

    required public init(datasource: ProfilesDataSource, output: ProfilesListCompletionOutput? = nil) {

        self.dataSource = datasource

        self.type = datasource.type

        super.init(nibName: nil, bundle: nil)

        self.dataSource.changesOutput = self

        title = type.title
        self.output = output
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        registerForKeyboardNotifications()

        setupTableHeader()
        setupNavigationBarButtons()

        definesPresentationContext = true

        let appearance = UIButton.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        appearance.setTitleColor(Theme.greyTextColor, for: .normal)

        updateHeaderWithSelections()

        displayContacts()

        view.addSubview(tableView)
        tableView.edges(to: view)

        switch type {
        case .favorites:
            setupEmptyView()
        case .newChat,
             .newGroupChat,
             .updateGroupChat:
            view.addSubview(searchResultView)
            searchResultView.edges(to: view)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        preferLargeTitleIfPossible(true)

        showOrHideEmptyState()

        dataSource.searchText = ""
        
        if dataSource.type != .updateGroupChat {
            dataSource.excludedProfilesIds = []
        }

        if let indexPathForSelectedRow = searchResultView.indexPathForSelectedRow {
            searchResultView.deselectRow(at: indexPathForSelectedRow, animated: true)
        }

        if #available(iOS 11.0, *) {
            // Insets are handled properly on iOS 11.
        } else {
            /// We have to adjust the insets to the bottom of the searchbar manually on iOS10
            let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
            let navigationBarHeight = navigationController?.navigationBar.frame.size.height ?? 0
            let searchBarHeight = (tableView.tableHeaderView as? ProfilesHeaderView)?.searchBar?.frame.height ?? 0

            searchResultView.contentInset.top = statusBarHeight + navigationBarHeight + searchBarHeight
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for view in searchController.searchBar.subviews {
            view.clipsToBounds = false
        }
        searchController.searchBar.superview?.clipsToBounds = false
    }

    private func updateHeaderWithSelections() {
        guard isMultipleSelectionMode else { return }
        guard
            let header = tableView.tableHeaderView as? ProfilesHeaderView,
            let selectedProfilesView = header.addedHeader else {
                assertionFailure("Couldn't access header!")
                return
        }

        selectedProfilesView.updateDisplay(with: selectedProfiles)
    }

    // MARK: - View Setup

    private func setupTableHeader() {
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            tableView.tableHeaderView = ProfilesHeaderView(type: type, delegate: self)
        } else {
            tableView.tableHeaderView = ProfilesHeaderView(with: searchController.searchBar, type: type, delegate: self)

            if Navigator.topViewController == self {
                tableView.layoutIfNeeded()
            }
        }
    }
    
    private func setupEmptyView() {
        guard shouldShowEmptyView else { return }

        view.addSubview(emptyView)
        emptyView.actionButton.addTarget(self, action: #selector(emptyViewButtonPressed(_:)), for: .touchUpInside)
        emptyView.edges(to: layoutGuide())
    }
    
    private func setupNavigationBarButtons() {
        switch type {
        case .newChat:
            navigationItem.leftBarButtonItem = cancelButton
        case .favorites:
            navigationItem.rightBarButtonItem = addButton
        case .newGroupChat, .updateGroupChat:
            navigationItem.rightBarButtonItem = doneButton
            doneButton.isEnabled = false
        }
    }

    private func displayContacts() {
        reloadData()
        showOrHideEmptyState()
    }

    func isProfileSelected(_ profile: TokenUser) -> Bool {
        return selectedProfiles.contains(profile)
    }

    func updateSelection(with profile: TokenUser) {
        if selectedProfiles.contains(profile) {
            selectedProfiles.remove(profile)
        } else {
            selectedProfiles.insert(profile)
        }
    }

    func rightBarButtonEnabled() -> Bool {
        switch type {
        case .newChat,
             .updateGroupChat,
             .favorites:
            return true
        default:
            return selectedProfiles.count > 1
        }
    }
    
    // MARK: - Action Handling
    
    @objc func emptyViewButtonPressed(_ button: ActionButton) {
        shareWithSystemSheet(item: Localized("sharing_action_item"))
    }

    // MARK: - Action Handling
    
    private func showOrHideEmptyState() {
        guard shouldShowEmptyView else { return }
        let emptyViewHidden = (searchController.isActive || !dataSource.isEmpty)
        emptyView.isHidden = emptyViewHidden
        tableView.tableHeaderView?.isHidden = !emptyViewHidden
    }
    
    @objc private func didTapCancel(_ button: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc private func didTapAdd(_ button: UIBarButtonItem) {
        let addContactSheet = UIAlertController(title: Localized("favorites_add_title"), message: nil, preferredStyle: .actionSheet)
        
        addContactSheet.addAction(UIAlertAction(title: Localized("favorites_add_by_username"), style: .default, handler: { _ in
            self.searchController.searchBar.becomeFirstResponder()
        }))
        
        addContactSheet.addAction(UIAlertAction(title: Localized("invite_friends_action_title"), style: .default, handler: { _ in

            self.shareWithSystemSheet(item: Localized("sharing_action_item"))
        }))
        
        addContactSheet.addAction(UIAlertAction(title: Localized("favorites_scan_code"), style: .default, handler: { _ in
            Navigator.presentScanner()
        }))

        addContactSheet.addAction(UIAlertAction(title: Localized("cancel_action_title"), style: .cancel, handler: nil))
        
        addContactSheet.view.tintColor = Theme.tintColor
        present(addContactSheet, animated: true)
    }
    
    @objc private func didTapDone(_ button: UIBarButtonItem) {
        guard selectedProfiles.count > 0 else {
            assertionFailure("No selected profiles?!")

            return
        }

        let membersIdsArray = selectedProfiles.sorted { $0.username < $1.username }.map { $0.address }

        selectedProfiles.forEach { user in
            SessionManager.shared.contactsManager.refreshContact(user)
        }

        switch type {
        case .updateGroupChat:
            navigationController?.popViewController(animated: true)
            output?.didFinish(self, selectedProfilesIds: membersIdsArray)
        case .newGroupChat:
            guard let groupModel = TSGroupModel(title: "", memberIds: NSMutableArray(array: membersIdsArray), image: UIImage(named: "avatar-edit-placeholder"), groupId: nil) else { return }

            let viewModel = NewGroupViewModel(groupModel)
            let groupViewController = GroupViewController(viewModel, configurator: NewGroupConfigurator())
            navigationController?.pushViewController(groupViewController, animated: true)
        case .favorites,
             .newChat:
            // Do nothing
            break
        }
    }

    // MARK: - Table View Reloading

    func reloadData() {
        if #available(iOS 11.0, *) {
            // Must perform batch updates on iOS 11 or you'll get super-wonky layout because of the headers.
            tableView.performBatchUpdates({
                self.tableView.reloadData()
            }, completion: nil)
        } else {
            tableView.reloadData()
        }
    }
}

// MARK: - Table View Delegate

extension ProfilesViewController: UITableViewDelegate {
    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let profile = dataSource.profile(at: indexPath) else { return}

        didSelectProfile(profile: profile)
    }

    func didSelectProfile(profile: TokenUser) {
        searchController.searchBar.resignFirstResponder()

        switch type {
        case .favorites:
            navigationController?.pushViewController(ProfileViewController(profile: profile), animated: true)
            UserDefaultsWrapper.selectedContact = profile.address
        case .newChat:
            output?.didFinish(self, selectedProfilesIds: [profile.address])
        case .newGroupChat, .updateGroupChat:
            updateSelection(with: profile)
            updateHeaderWithSelections()
            reloadData()
            navigationItem.rightBarButtonItem?.isEnabled = rightBarButtonEnabled()
        }
    }
}
// MARK: - Table View Data Source

extension ProfilesViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections()
    }

    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfItems(in: section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let profile = dataSource.profile(at: indexPath) else {
            assertionFailure("Could not get profile at indexPath: \(indexPath)")
            return UITableViewCell()
        }

        var shouldShowCheckmark = false
        if isMultipleSelectionMode {
            shouldShowCheckmark = true
        }

        let tableData = TableCellData(title: profile.name,
                                      subtitle: profile.displayUsername,
                                      leftImagePath: profile.avatarPath,
                                      showCheckmark: shouldShowCheckmark)

        let cellConfigurator = CellConfigurator()

        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellConfigurator.cellIdentifier(for: tableData.components), for: indexPath) as? BasicTableViewCell else {
            return UITableViewCell()
        }

        cell.checkmarkView.checked = isProfileSelected(profile)
        cell.selectionStyle = isMultipleSelectionMode ? .none : .default
        cellConfigurator.configureCell(cell, with: tableData)

        return cell
    }
}

// MARK: - Mix-in extensions

extension ProfilesViewController: SystemSharing { /* mix-in */ }

// MARK: - Search Bar Delegate
extension ProfilesViewController: UISearchBarDelegate {
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil

        searchBar.setShowsCancelButton(false, animated: true)
        searchResultView.isHidden = true
        searchResultView.searchResults = []
    }

    func searchBar(_: UISearchBar, textDidChange searchText: String) {

        searchResultView.isHidden = false

        if searchText.isEmpty {
            searchResultView.searchResults = []
        }

        reload(searchText: searchText)
    }
}

// MARK: - Keyboard Adjustable

extension ProfilesViewController: KeyboardAdjustable {

    var keyboardWillShowSelector: Selector {
        return #selector(keyboardShownNotificationReceived(_:))
    }

    var keyboardWillHideSelector: Selector {
        return #selector(keyboardHiddenNotificationReceived(_:))
    }

    @objc private func keyboardShownNotificationReceived(_ notification: NSNotification) {
        keyboardWillShow(notification)
    }

    @objc private func keyboardHiddenNotificationReceived(_ notification: NSNotification) {
        keyboardWillHide(notification)
    }
}

// MARK: - Search Results Updating

extension ProfilesViewController: UISearchResultsUpdating {
    
    public func updateSearchResults(for searchController: UISearchController) {

        switch type {
        case .favorites:
            dataSource.searchText = searchController.searchBar.text ?? ""
        case .newChat,
             .newGroupChat,
             .updateGroupChat:
            // Do nothing
            break
        }
    }
}

// MARK: - Profiles Add Group Header Delegate

extension ProfilesViewController: ProfilesAddGroupHeaderDelegate {
    
    func newGroup() {
        let datasource = ProfilesDataSource(type: .newGroupChat)
        let groupChatSelection = ProfilesViewController(datasource: datasource)
        navigationController?.pushViewController(groupChatSelection, animated: true)
    }
}

// MARK: - Profiles Datasource Changes Output

extension ProfilesViewController: ProfilesDatasourceChangesOutput {

    func datasourceDidChange(_ datasource: ProfilesDataSource, yapDatabaseChanges: [YapDatabaseViewRowChange]) {

        if navigationController?.topViewController == self && tabBarController?.selectedViewController == navigationController {
            tableView.beginUpdates()

            for rowChange in yapDatabaseChanges {

                switch rowChange.type {
                case .delete:
                    guard let indexPath = rowChange.indexPath else { continue }
                    tableView.deleteRows(at: [indexPath], with: .none)
                case .insert:
                    guard let newIndexPath = rowChange.newIndexPath else { continue }
                    tableView.insertRows(at: [newIndexPath], with: .none)
                case .move:
                    guard let newIndexPath = rowChange.newIndexPath, let indexPath = rowChange.indexPath else { continue }
                    tableView.deleteRows(at: [indexPath], with: .none)
                    tableView.insertRows(at: [newIndexPath], with: .none)
                case .update:
                    guard let indexPath = rowChange.indexPath else { continue }
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
            }

            tableView.endUpdates()
        } else {
            tableView.reloadData()
        }

        showOrHideEmptyState()
    }

    @objc private func reload(searchText: String) {
        searchBarText = searchText
        IDAPIClient.shared.searchContacts(name: searchText) { [weak self] users in
            if let searchBarText = self?.searchBarText, searchText == searchBarText {
                self?.searchResultView.searchResults = users
            }
        }
    }
}

// MARK: - Search Selection Delegate

extension ProfilesViewController: SearchSelectionDelegate {

    func didSelectSearchResult(user: TokenUser) {
        didSelectProfile(profile: user)
    }

    func isSearchResultSelected(user: TokenUser) -> Bool {
        return isProfileSelected(user)
    }
}
