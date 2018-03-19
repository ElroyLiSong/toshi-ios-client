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
@testable import Toshi
import XCTest
import Foundation
import Teapot

class DirectoryAPIClientTests: XCTestCase {

    func testGetDappsFrontPage() {

        let mockTeapot = MockTeapot(bundle: Bundle(for: PaymentManagerTests.self), mockFilename: "dappsFrontPage")
        let directoryAPIClient = DirectoryAPIClient(teapot: mockTeapot, cacheEnabled: false)

        let expectation = XCTestExpectation(description: "Get Dapps")

        directoryAPIClient.getDappsFrontPage { frontPageResult, _ in
            guard let frontPageResult = frontPageResult else {
                XCTFail("frontPageResult is nil")
                return
            }

            XCTAssertEqual(frontPageResult.categories.map { $0.categoryId }, [10, 20, 30, 40, 50, 60])

            guard frontPageResult.categories.count > 1 else {
                XCTFail("no second category of dapps in json")
                return
            }

            let dapps = frontPageResult.categories[1].dapps

            XCTAssertEqual(dapps.map { $0.name }, ["Cryptokitties", "Etherbots", "Ethercraft", "Etheremon"])
            XCTAssertEqual(dapps.map { $0.dappId }, [1673246900729414660, 1708349878154822668, 1708333788804678667, 1708300997736006666])
            XCTAssertEqual(dapps.map { $0.url.absoluteString }, ["https://www.cryptokitties.co/", "https://etherbots.io/", "https://ethercraft.io/", "https://www.etheremon.com/"])
            XCTAssertEqual(dapps.map { $0.avatarUrlString ?? "" }, ["https://bucketeer-7c93db19-eda4-413d-9025-fca45df5773a.s3.amazonaws.com/public/avatar/1673246900729414660_3ac912.png",
                                                                    "https://bucketeer-7c93db19-eda4-413d-9025-fca45df5773a.s3.amazonaws.com/public/avatar/1708349878154822668_ecda6e.jpg",
                                                                    "https://bucketeer-7c93db19-eda4-413d-9025-fca45df5773a.s3.amazonaws.com/public/avatar/1708333788804678667_944085.png",
                                                                    "https://bucketeer-7c93db19-eda4-413d-9025-fca45df5773a.s3.amazonaws.com/public/avatar/1708300997736006666_00dfcb.png"])
            XCTAssertEqual(dapps.map { $0.coverUrlString ?? "" }, ["http://goooogle.nl", "http://cover.up", "http://url.url", "http://fake-cover-url.com"])
            XCTAssertEqual(dapps.map { $0.description ?? "" }, ["CryptoKitties is a game centered around breedable, collectible, and oh-so-adorable creatures we call CryptoKitties! Each cat is one-of-a-kind and 100% owned by you; it cannot be replicated, taken away, or destroyed.",
                                                                "A decentralized Robot Wars game for the Ethereum blockchain.",
                                                                "A decentralized RPG running on the Ethereum blockchain.",
                                                                "A decentralized application built on the Ethereum network to simulate a world of monsters where you can capture, evolve a monster to defeat others."])
            XCTAssertEqual(dapps.map { $0.descriptionForSearch ?? "" }, ["CryptoKitties is a game centered around breedable, collectible, and oh-so-adorable creatures we call CryptoKitties! Each cat is one-of-a-kind and 100% owned by you; it cannot be replicated, taken away, or destroyed.",
                                                                         "A decentralized Robot Wars game for the Ethereum blockchain.",
                                                                         "A decentralized RPG running on the Ethereum blockchain.",
                                                                         "A decentralized application built on the Ethereum network to simulate a world of monsters where you can capture, evolve a monster to defeat others."])

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testGetQueriedDapps() {

        let mockTeapot = MockTeapot(bundle: Bundle(for: PaymentManagerTests.self), mockFilename: "queriedDappsResults")

        let directoryAPIClient = DirectoryAPIClient(teapot: mockTeapot, cacheEnabled: false)

        let expectation = XCTestExpectation(description: "Get Dapps")

        let queryData = DappsQueryData()

        directoryAPIClient.getQueriedDapps(queryData: queryData) { dappsResult, _ in
            guard let dappsResult = dappsResult else {
                XCTFail("dappsResult is nil")
                return
            }

            let dapps = dappsResult.results.dapps
            XCTAssertEqual(dapps.map { $0.name }, ["Axie Infinity", "Cent", "ChainMonsters"])
            XCTAssertEqual(dapps.map { $0.dappId }, [1729809212487238681, 1673246598739526658, 1704426417141318665])
            XCTAssertEqual(dapps.map { $0.url.absoluteString }, ["https://axieinfinity.com/#", "https://beta.cent.co/", "https://chainmonsters.io/"])
            XCTAssertEqual(dapps.map { $0.avatarUrlString ?? "" }, ["https://bucketeer-7c93db19-eda4-413d-9025-fca45df5773a.s3.amazonaws.com/public/avatar/1729809212487238681_4bfc03.jpg", "https://bucketeer-7c93db19-eda4-413d-9025-fca45df5773a.s3.amazonaws.com/public/avatar/1673246598739526658_613d88.png", "https://bucketeer-7c93db19-eda4-413d-9025-fca45df5773a.s3.amazonaws.com/public/avatar/1704426417141318665_393169.png"])
            XCTAssertEqual(dapps.map { $0.coverUrlString ?? "" }, ["http://fake-cover-url.com", "http://gooogle.com", "http://other-url.nl"])
            XCTAssertEqual(dapps.map { $0.description ?? "" }, ["Axie Infinity is a game about collecting and raising fantasy creatures called Axie, on the Ethereum platform.",
                                                                "Give wisdom, get money. Ask a question and offer a bounty for the best answers. The userbase then votes to determine which answers receive that bounty.",
                                                                "ChainMonsters is a 100% blockchain based monster collectible game. Every action you take, every ChainMonster you catch will be reflected in the game and on blockchain itself."])
            XCTAssertEqual(dappsResult.results.dapps.map { $0.descriptionForSearch ?? "" }, ["Axie Infinity is a game about collecting and raising fantasy creatures called Axie, on the Ethereum platform.",
                                                                                             "Give wisdom, get money. Ask a question and offer a bounty for the best answers. The userbase then votes to determine which answers receive that bounty.",
                                                                                             "ChainMonsters is a 100% blockchain based monster collectible game. Every action you take, every ChainMonster you catch will be reflected in the game and on blockchain itself."])

            XCTAssertEqual(dappsResult.results.categories.map { $0.value }, ["Games & Collectibles", "Marketplaces", "Social Media"])

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
}
