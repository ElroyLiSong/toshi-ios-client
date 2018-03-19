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

enum TokenType {
    case fiatRepresentable
    case nonFiatRepresentable
}

enum PrimaryValue {
    case token
    case fiat

    var opposite: PrimaryValue {
        switch self {
        case .token:
            return .fiat
        case .fiat:
            return .token
        }
    }
}

struct TokenTypeViewConfiguration {
    var isActive: Bool
    var tokenType: TokenType
    var primaryValue: PrimaryValue

    init(isActive: Bool, tokenType: TokenType, primaryValue: PrimaryValue) {
        self.isActive = isActive
        self.tokenType = tokenType
        self.primaryValue = primaryValue
    }

    var visibleViews: SendTokenViews {
        switch (tokenType, isActive) {
        case (.fiatRepresentable, true):
            return [.maxButton, .swapButton, .secondaryValueLabel, .balanceLabel]
        case (.fiatRepresentable, false):
            return .secondaryValueLabel
        case (.nonFiatRepresentable, true):
            return [.balanceLabel, .maxButton]
        case (.nonFiatRepresentable, false):
            return []
        }
    }
}

struct SendTokenViews: OptionSet {
    let rawValue: Int

    static let maxButton = SendTokenViews(rawValue: 1 << 0)
    static let swapButton = SendTokenViews(rawValue: 1 << 1)
    static let secondaryValueLabel = SendTokenViews(rawValue: 1 << 2)
    static let balanceLabel = SendTokenViews(rawValue: 1 << 3)
    static let addressLabel = SendTokenViews(rawValue: 1 << 4)
}

extension SendTokenViews: Hashable {
    var hashValue: Int {
        return rawValue
    }
}

final class SendTokenViewModel {

    var token: Token

    private lazy var inputNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2

        return formatter
    }()

    init(token: Token) {
        self.token = token
    }

    func finalValueHexString(for viewConfiguration: TokenTypeViewConfiguration, valueText: String) -> String {

        var final: NSDecimalNumber = .zero

        switch (viewConfiguration.tokenType, viewConfiguration.primaryValue) {
        case (.fiatRepresentable, .fiat):
            if let ether = token as? EtherToken {
                let fiatString = EthereumConverter.fiatValueString(forWei: ether.wei, exchangeRate: ExchangeRateClient.exchangeRate, withCurrencyCode: false)
                if fiatString == valueText {
                    final = ether.wei
                } else {
                    let ether = etherNumberFromFiatText(valueText)
                    if ether.isANumber {
                        final = ether.multiplying(byPowerOf10: EthereumConverter.weisToEtherPowerOf10Constant)
                    }
                }
            }

        case (.fiatRepresentable, .token):
            if let ether = token as? EtherToken, ether.displayValueString == valueText {
                final = ether.wei
            } else {
                final = NSDecimalNumber(string: valueText, locale: Locale.current).multiplying(by: EthereumConverter.weisToEtherConstant)
            }

        case (.nonFiatRepresentable, .token):
            final = NSDecimalNumber(string: valueText, locale: Locale.current)
            let tokenToWeiPower = Int16(token.decimals)
            final = final.multiplying(byPowerOf10: tokenToWeiPower)
        default:
            break
        }

        return final.toHexString
    }

    func secondaryValueText(for viewConfiguration: TokenTypeViewConfiguration, isMaxValueSelected: Bool, valueText: String?) -> String {
        if let primaryValueText = valueText, !primaryValueText.isEmpty {
            return nonEmptySecondaryValueString(for: viewConfiguration, isMaxValueSelected: isMaxValueSelected, primaryValueText: primaryValueText)
        }
        return emptySecondaryValueString(for: viewConfiguration)
    }

    func swappedValuesText(for viewConfiguration: TokenTypeViewConfiguration, isMaxValueSelected: Bool, primaryValueText: String) -> (primaryValueText: String, secondaryValueText: String) {
        var primaryValueResultText = ""
        var secondaryValueResultText = ""

        switch viewConfiguration.primaryValue {
        case .token:
            var wei: NSDecimalNumber = .zero
            if isMaxValueSelected {
                wei = NSDecimalNumber(hexadecimalString: token.value)
            } else {
                let eth = NSDecimalNumber(string: primaryValueText, locale: Locale.current)
                wei = EthereumConverter.etherToWei(eth)
            }

            let convertedToFiat = EthereumConverter.fiatValueString(forWei: wei, exchangeRate: ExchangeRateClient.exchangeRate, withCurrencyCode: false)

            secondaryValueResultText = "\(primaryValueText) \(token.symbol)"
            primaryValueResultText = convertedToFiat

        case .fiat:
            var wei: NSDecimalNumber = .zero
            var ethValueString = ""
            if isMaxValueSelected {
                wei = NSDecimalNumber(hexadecimalString: token.value)
                ethValueString = EthereumConverter.ethereumValueString(forWei: wei, withSymbol: false, fractionDigits: 6)
            } else {
                let ether = etherNumberFromFiatText(primaryValueText)
                ethValueString = EthereumConverter.ethereumValueString(forEther: ether, withSymbol: false, fractionDigits: 6)
                wei = EthereumConverter.etherToWei(ether)
            }

            secondaryValueResultText = EthereumConverter.fiatValueString(forWei: wei, exchangeRate: ExchangeRateClient.exchangeRate)
            primaryValueResultText = ethValueString
        }

        return (primaryValueResultText, secondaryValueResultText)
    }

    func nonEmptySecondaryValueString(for viewConfiguration: TokenTypeViewConfiguration, isMaxValueSelected: Bool, primaryValueText: String) -> String {
        var text = ""

        switch viewConfiguration.primaryValue {
        case .token:
            var wei: NSDecimalNumber = .zero
            if isMaxValueSelected {
                wei = NSDecimalNumber(hexadecimalString: token.value)
            } else {
                let eth = NSDecimalNumber(string: primaryValueText, locale: Locale.current)
                wei = EthereumConverter.etherToWei(eth)
            }

            let convertedToFiat = EthereumConverter.fiatValueString(forWei: wei, exchangeRate: ExchangeRateClient.exchangeRate)

            text = convertedToFiat

        case .fiat:
            var wei: NSDecimalNumber = .zero
            var ethValueString = ""
            if isMaxValueSelected {
                wei = NSDecimalNumber(hexadecimalString: token.value)
                ethValueString = EthereumConverter.ethereumValueString(forWei: wei, fractionDigits: 6)
            } else {
                let fiat = NSDecimalNumber(string: primaryValueText, locale: Locale.current)
                let ether = EthereumConverter.localFiatToEther(forFiat: fiat, exchangeRate: ExchangeRateClient.exchangeRate)
                ethValueString = EthereumConverter.ethereumValueString(forEther: ether, fractionDigits: 6)
            }

            text = ethValueString
        }

        return text
    }

    func emptySecondaryValueString(for viewConfiguration: TokenTypeViewConfiguration) -> String {
        switch viewConfiguration.primaryValue {
        case .token:
            return EthereumConverter.fiatValueString(forWei: NSDecimalNumber.zero, exchangeRate: ExchangeRateClient.exchangeRate)
        case .fiat:
            return EthereumConverter.ethereumValueString(forEther: 0)
        }
    }

    func balanceString(for viewConfiguration: TokenTypeViewConfiguration) -> String {

        switch viewConfiguration.tokenType {
        case .fiatRepresentable:
            let fiatString = (token as? EtherToken)?.convertToFiat() ?? ""
            return String(format: Localized.wallet_token_balance_format_with_fiat, self.token.symbol, self.token.displayValueString, fiatString)
        case .nonFiatRepresentable:
            return String(format: Localized.wallet_token_balance_format, self.token.symbol, self.token.displayValueString)
        }
    }

    func insuffisientBalanceString(for viewConfiguration: TokenTypeViewConfiguration) -> String {

        switch viewConfiguration.tokenType {
        case .fiatRepresentable:
            let fiatString = (token as? EtherToken)?.convertToFiat() ?? ""
            return String(format: Localized.wallet_insuffisient_fiat_balance_error, self.token.symbol, self.token.displayValueString, fiatString)
        case .nonFiatRepresentable:
            return String(format: Localized.wallet_insuffisient_token_balance_error, self.token.symbol, self.token.displayValueString)
        }
    }

    func isInsuffisientBalance(for viewConfiguration: TokenTypeViewConfiguration, inputValueText: String) -> Bool {
        var valueToCompareAgainst: Decimal?

        switch viewConfiguration.primaryValue {
        case .token:
            valueToCompareAgainst = Decimal(string: token.displayValueString)
        case .fiat:
            if let ether = token as? EtherToken {
                let valueString = EthereumConverter.fiatValueString(forWei: ether.wei, exchangeRate: ExchangeRateClient.exchangeRate, withCurrencyCode: false)
                valueToCompareAgainst = Decimal(string: valueString)
            }
        }

        guard let value = valueToCompareAgainst else { return false }
        guard let inputDecimalValue = Decimal(string: inputValueText) else { return false }

        return inputDecimalValue > value
    }

    func errorViews(for viewConfiguration: TokenTypeViewConfiguration, inputValueText: String, address: String) -> [SendTokenViews] {
        var errorViews: [SendTokenViews] = []

        if token.isEtherToken && !address.isEmpty && !EthereumAddress.validate(address) {
            errorViews.append(SendTokenViews.addressLabel)
        }

        if isInsuffisientBalance(for: viewConfiguration, inputValueText: inputValueText) {
            errorViews.append(SendTokenViews.balanceLabel)
        }

        return errorViews
    }

    private  func etherNumberFromFiatText(_ text: String) -> NSDecimalNumber {
        guard let currencyValue = inputNumberFormatter.number(from: text) else { return 0 }

        return EthereumConverter.localFiatToEther(forFiat: currencyValue, exchangeRate: ExchangeRateClient.exchangeRate)
    }
}
