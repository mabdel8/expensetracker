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
    
    // Relationship: A transaction can be associated with a recurring subscription
    @Relationship(inverse: \RecurringSubscription.transactions)
    var recurringSubscription: RecurringSubscription?
    
    init(name: String, date: Date, amount: Double, notes: String? = nil, type: TransactionType, category: Category? = nil, recurringSubscription: RecurringSubscription? = nil) {
        self.name = name
        self.date = date
        self.amount = amount
        self.notes = notes
        self.type = type
        self.category = category
        self.recurringSubscription = recurringSubscription
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
    
    var isRecurring: Bool {
        return recurringSubscription != nil
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