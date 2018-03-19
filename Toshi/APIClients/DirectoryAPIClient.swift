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
import Haneke
import SweetFoundation
import Teapot

typealias DappCompletion = (_ dapps: [Dapp]?, _ error: ToshiError?) -> Void
typealias DappsFrontPageCompletion = (_ frontPageResult: DappsFrontPage?, _ error: ToshiError?) -> Void
typealias QueriedDappsCompletion = (_ dappsResult: QueriedDappsResults?, _ error: ToshiError?) -> Void

enum DirectoryAPIClientKeys {
    static let dappsFrontPageCacheKey = "DappsFrontPageCacheKey"
}

final class DirectoryAPIClient {

    static let shared: DirectoryAPIClient = DirectoryAPIClient()

    private let cache = Shared.dataCache

    var teapot: Teapot
    var baseURL: URL

    convenience init(teapot: Teapot, cacheEnabled: Bool = true) {
        self.init()
        self.teapot = teapot
        
        if !cacheEnabled {
            cache.removeAll()
        }
    }

    private init() {
        baseURL = URL(string: ToshiDirectoryServiceURLPath)!
        teapot = Teapot(baseURL: baseURL)
    }

    /// Gets Dapps front page info from the server. Caches.
    ///
    /// - Parameters:
    ///   - completion: The completion closure to execute when the request completes
    ///                 - dappsFrontpageResults: A list of categories ncluding dapps, and categories info, or nil
    ///                 - toshiError: A toshiError if any error was encountered, or nil
    func getDappsFrontPage(completion: @escaping DappsFrontPageCompletion) {
        let path = "/v1/dapps/frontpage"

        cache.fetch(key: DirectoryAPIClientKeys.dappsFrontPageCacheKey).onSuccess { data in
            var frontPage: DappsFrontPage?
            do {
                let jsonDecoder = JSONDecoder()
                frontPage = try jsonDecoder.decode(DappsFrontPage.self, from: data)
            } catch { return }

            DispatchQueue.main.async {
                completion(frontPage, nil)
            }
        }

        teapot.get(path) { [weak self] result in

            var frontPage: DappsFrontPage?
            var resultError: ToshiError?

            switch result {
            case .success(let json, _):
                guard let data = json?.data else {
                    DispatchQueue.main.async {
                        completion(nil, .invalidPayload)
                    }
                    return
                }

                self?.cache.set(value: data, key: DirectoryAPIClientKeys.dappsFrontPageCacheKey)

                do {
                    let jsonDecoder = JSONDecoder()
                    frontPage = try jsonDecoder.decode(DappsFrontPage.self, from: data)
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, .invalidResponseJSON)
                    }
                    return
                }

            case .failure(_, _, let error):
                DLog(error.localizedDescription)
                resultError = ToshiError(withTeapotError: error)
            }

            DispatchQueue.main.async {
                completion(frontPage, resultError)
            }
        }
    }

    /// Gets Dapps list from the server for a given optional query. Does not cache.
    ///
    /// - Parameters:
    ///   - query: A query data for dapps search, paging, limit or category filter (contains offset, limit, query and category)
    ///   - completion: The completion closure to execute when the request completes
    ///                 - dappsFrontpageResults: A list of categories ncluding dapps, and categories info, or nil
    ///                 - toshiError: A toshiError if any error was encountered, or nil
    func getQueriedDapps(queryData: DappsQueryData, completion: @escaping QueriedDappsCompletion) {
        var path = "/v1/dapps?offset=\(queryData.offset)&limit=\(queryData.limit)"

        if !queryData.searchText.isEmpty {
            let query = queryData.searchText.addingPercentEncoding(withAllowedCharacters: IDAPIClient.allowedSearchTermCharacters) ?? queryData.searchText
            path.append("&query=\(query)")
        }

        if let categoryId = queryData.categoryId {
            path.append("&category=\(String(categoryId))")
        }

        teapot.get(path) { result in
            var dappsResults: QueriedDappsResults?
            var resultError: ToshiError?

            switch result {
            case .success(let json, _):
                guard let data = json?.data else {
                    DispatchQueue.main.async {
                        completion(nil, .invalidPayload)
                    }
                    return
                }

                do {
                    let jsonDecoder = JSONDecoder()
                    dappsResults = try jsonDecoder.decode(QueriedDappsResults.self, from: data)
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, .invalidResponseJSON)
                    }
                    return
                }

            case .failure(_, _, let error):
                DLog(error.localizedDescription)
                resultError = ToshiError(withTeapotError: error)
            }

            DispatchQueue.main.async {
                completion(dappsResults, resultError)
            }
        }
    }
}
