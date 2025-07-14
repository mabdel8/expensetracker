//
//  RecurringSubscription.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }
    
    var systemImage: String {
        switch self {
        case .daily:
            return "calendar.badge.clock"
        case .weekly:
            return "calendar.badge.clock"
        case .monthly:
            return "calendar.badge.clock"
        case .yearly:
            return "calendar.badge.clock"
        }
    }
}

@Model
class RecurringSubscription {
    var name: String = ""
    var amount: Double = 0.0
    var frequency: RecurrenceFrequency = RecurrenceFrequency.monthly
    var startDate: Date = Date()
    var lastTransactionDate: Date? = nil
    var nextDueDate: Date = Date()
    var isActive: Bool = true
    var notes: String? = nil
    var type: TransactionType = TransactionType.expense
    
    // Relationship: A recurring subscription belongs to one category (must be optional for CloudKit)
    var category: Category?
    
    // Relationship: A recurring subscription can have many transactions (must be optional for CloudKit)
    @Relationship(deleteRule: .nullify, inverse: \Transaction.recurringSubscription)
    var transactions: [Transaction]? = []
    
    init(name: String = "", amount: Double = 0.0, frequency: RecurrenceFrequency = RecurrenceFrequency.monthly, startDate: Date = Date(), type: TransactionType = TransactionType.expense, category: Category? = nil, notes: String? = nil) {
        self.name = name
        self.amount = amount
        self.frequency = frequency
        self.startDate = startDate
        self.type = type
        self.category = category
        self.notes = notes
        self.isActive = true
        self.lastTransactionDate = nil
        self.nextDueDate = RecurringSubscription.calculateNextDueDate(from: startDate, frequency: frequency)
    }
    
    // Computed properties for convenience
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var displayAmount: String {
        let prefix = type == .income ? "+" : "-"
        return "\(prefix)\(formattedAmount)"
    }
    
    var isDue: Bool {
        return isActive && nextDueDate <= Date()
    }
    
    var daysSinceLastTransaction: Int {
        guard let lastDate = lastTransactionDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
    }
    
    var daysUntilNextDue: Int {
        let components = Calendar.current.dateComponents([.day], from: Date(), to: nextDueDate)
        return components.day ?? 0
    }
    
    // Calculate next due date based on frequency
    static func calculateNextDueDate(from date: Date, frequency: RecurrenceFrequency) -> Date {
        let calendar = Calendar.current
        
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
    }
    
    // Update next due date after creating a transaction
    func updateNextDueDate() {
        self.lastTransactionDate = Date()
        self.nextDueDate = RecurringSubscription.calculateNextDueDate(from: self.lastTransactionDate!, frequency: self.frequency)
    }
    
    // Create a transaction from this recurring subscription
    func createTransaction() -> Transaction {
        let transaction = Transaction(
            name: self.name,
            date: Date(),
            amount: self.amount,
            notes: self.notes,
            type: self.type,
            category: self.category
        )
        
        // Associate the transaction with this recurring subscription
        transaction.recurringSubscription = self
        
        // Update the next due date
        self.updateNextDueDate()
        
        return transaction
    }
} 