//
//  Budget.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData

@Model
class MonthlyBudget: Hashable, Equatable {
    var totalBudget: Double = 0.0
    var month: Date = Date() // First day of the month

    
    // Relationship: A monthly budget has many category allocations
    @Relationship(deleteRule: .cascade, inverse: \CategoryBudget.monthlyBudget)
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
    var allocatedAmount: Double = 0.0
    var month: Date = Date() // First day of the month
    
    // Relationship: A category budget belongs to one category
    // Note: Inverse relationship temporarily removed due to circular reference
    var category: Category?
    
    // Relationship: A category budget belongs to one monthly budget
    // Note: Inverse relationship temporarily removed due to circular reference
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

 