//
//  Transaction.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData

@Model
class Transaction {
    var name: String
    var date: Date
    var amount: Double
    var notes: String?
    var type: TransactionType // To distinguish between income and expense
    
    // Relationship: A transaction belongs to one category
    @Relationship(inverse: \Category.transactions)
    var category: Category?
    
    init(name: String, date: Date, amount: Double, notes: String? = nil, type: TransactionType, category: Category? = nil) {
        self.name = name
        self.date = date
        self.amount = amount
        self.notes = notes
        self.type = type
        self.category = category
    }
    
    // Computed properties for convenience
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var isIncome: Bool {
        return type == .income
    }
    
    var isExpense: Bool {
        return type == .expense
    }
    
    var displayAmount: String {
        let prefix = isIncome ? "+" : "-"
        return "\(prefix)\(formattedAmount)"
    }
    
    var dayOfMonth: Int {
        Calendar.current.component(.day, from: date)
    }
    
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
} 