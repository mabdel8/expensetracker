//
//  Account.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData

enum AccountType: String, CaseIterable, Codable {
    case debitCard = "Debit Card"
    case cash = "Cash"
    case paypal = "PayPal"
    case creditCard = "Credit Card"
    
    var iconName: String {
        switch self {
        case .debitCard:
            return "creditcard.fill"
        case .cash:
            return "banknote.fill"
        case .paypal:
            return "globe"
        case .creditCard:
            return "creditcard.fill"
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

@Model
class Account {
    var name: String = ""
    var accountType: AccountType = AccountType.debitCard
    var colorHex: String = "219EBC"
    var lastFourDigits: String? = nil
    var createdDate: Date = Date()
    
    // Relationship: An account can have many transactions
    @Relationship(deleteRule: .nullify)
    var transactions: [Transaction]? = []
    
    init(name: String = "", accountType: AccountType = AccountType.debitCard, colorHex: String = "219EBC", lastFourDigits: String? = nil) {
        self.name = name
        self.accountType = accountType
        self.colorHex = colorHex
        self.lastFourDigits = lastFourDigits
        self.createdDate = Date()
    }
    
    // Computed properties for convenience
    var displayName: String {
        if let lastFour = lastFourDigits, !lastFour.isEmpty {
            return "\(name) ••••\(lastFour)"
        }
        return name
    }
    
    var totalBalance: Double {
        guard let transactions = transactions else { return 0.0 }
        return transactions.reduce(0.0) { total, transaction in
            if transaction.type == .income {
                return total + transaction.amount
            } else {
                return total - transaction.amount
            }
        }
    }
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: totalBalance)) ?? "$0.00"
    }
    
    var transactionCount: Int {
        return transactions?.count ?? 0
    }
} 