//
//  Budget.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData

@Model
class MonthlyBudget: Hashable {
    var totalBudget: Double
    var month: Date // First day of the month
    
    // Relationship: A monthly budget has many category allocations
    @Relationship(deleteRule: .cascade)
    var categoryAllocations: [CategoryBudget]? = []
    
    init(totalBudget: Double, month: Date) {
        self.totalBudget = totalBudget
        self.month = month
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(month)
    }
    
    static func == (lhs: MonthlyBudget, rhs: MonthlyBudget) -> Bool {
        return lhs.month == rhs.month
    }
    
    // Computed properties for convenience
    var formattedTotalBudget: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: totalBudget)) ?? "$0.00"
    }
    
    var allocatedBudget: Double {
        return categoryAllocations?.reduce(0) { $0 + $1.allocatedAmount } ?? 0
    }
    
    var remainingBudget: Double {
        return totalBudget - allocatedBudget
    }
    
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
    
    // Get spending for this month
    func getSpentAmount(from transactions: [Transaction]) -> Double {
        let calendar = Calendar.current
        let monthTransactions = transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: month, toGranularity: .month) &&
            transaction.type == .expense
        }
        return monthTransactions.reduce(0) { $0 + $1.amount }
    }
    
    // Get remaining budget after spending
    func getRemainingAfterSpending(from transactions: [Transaction]) -> Double {
        return totalBudget - getSpentAmount(from: transactions)
    }
}

@Model
class CategoryBudget {
    var allocatedAmount: Double
    var month: Date // First day of the month
    
    // Relationship: A category budget belongs to one category
    @Relationship(inverse: \Category.budgets)
    var category: Category?
    
    // Relationship: A category budget belongs to one monthly budget
    @Relationship(inverse: \MonthlyBudget.categoryAllocations)
    var monthlyBudget: MonthlyBudget?
    
    init(allocatedAmount: Double, month: Date, category: Category?) {
        self.allocatedAmount = allocatedAmount
        self.month = month
        self.category = category
    }
    
    // Computed properties for convenience
    var formattedAllocatedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: allocatedAmount)) ?? "$0.00"
    }
    
    // Get spending for this category in this month
    func getSpentAmount(from transactions: [Transaction]) -> Double {
        let calendar = Calendar.current
        let categoryTransactions = transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: month, toGranularity: .month) &&
            transaction.type == .expense &&
            transaction.category?.name == category?.name
        }
        return categoryTransactions.reduce(0) { $0 + $1.amount }
    }
    
    // Get remaining budget for this category
    func getRemainingAmount(from transactions: [Transaction]) -> Double {
        return allocatedAmount - getSpentAmount(from: transactions)
    }
    
    // Get percentage of budget used
    func getUsagePercentage(from transactions: [Transaction]) -> Double {
        guard allocatedAmount > 0 else { return 0 }
        return (getSpentAmount(from: transactions) / allocatedAmount) * 100
    }
}

// Legacy Budget model - kept for backward compatibility if needed
// This can be removed after migration
@Model
class Budget {
    var amount: Double
    var startDate: Date
    var endDate: Date
    
    // Budget is tied to a specific expense category
    var category: Category?
    
    init(amount: Double, startDate: Date, endDate: Date, category: Category?) {
        self.amount = amount
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
    }
    
    // Computed properties for convenience
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    var durationInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var remainingDays: Int {
        let now = Date()
        if now > endDate {
            return 0
        }
        return Calendar.current.dateComponents([.day], from: now, to: endDate).day ?? 0
    }
    
    var progressPercentage: Double {
        let totalDays = durationInDays
        let daysPassed = totalDays - remainingDays
        return totalDays > 0 ? Double(daysPassed) / Double(totalDays) : 0
    }
} 