//
//  Category.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class Category {
    @Attribute(.unique)
    var name: String
    var iconName: String // SF Symbol name
    var colorHex: String // Store color as a hex string
    var transactionType: TransactionType // Is this an income or expense category?
    
    // Relationship: A category can have many transactions
    @Relationship(deleteRule: .cascade)
    var transactions: [Transaction]? = []
    
    // Relationship: A category can have many recurring subscriptions
    @Relationship(deleteRule: .cascade)
    var recurringSubscriptions: [RecurringSubscription]? = []
    
    // Relationship: A category can have many budget allocations
    @Relationship(deleteRule: .cascade)
    var budgets: [CategoryBudget]? = []
    
    init(name: String, iconName: String, colorHex: String, transactionType: TransactionType) {
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.transactionType = transactionType
    }
    
    // Computed property to get Color from hex string
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    // Get budget allocation for a specific month
    func getBudgetAllocation(for month: Date) -> CategoryBudget? {
        let calendar = Calendar.current
        return budgets?.first { budget in
            calendar.isDate(budget.month, equalTo: month, toGranularity: .month)
        }
    }
    
    // Get allocated amount for a specific month
    func getAllocatedAmount(for month: Date) -> Double {
        return getBudgetAllocation(for: month)?.allocatedAmount ?? 0
    }
}

// Extension to create Color from hex string
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
} 