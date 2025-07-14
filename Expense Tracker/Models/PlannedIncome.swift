//
//  PlannedIncome.swift
//  Expense Tracker
//
//  Created by Abdalla Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData

@Model
class PlannedIncome {
    var name: String = ""
    var amount: Double = 0.0
    var month: Date = Date()
    
    init(name: String = "", amount: Double = 0.0, month: Date = Date()) {
        self.name = name
        self.amount = amount
        self.month = month
    }
    
    // Computed property for formatted amount
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
} 