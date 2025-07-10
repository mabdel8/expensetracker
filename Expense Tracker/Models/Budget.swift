//
//  Budget.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData

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