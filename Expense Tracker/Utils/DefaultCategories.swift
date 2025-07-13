//
//  DefaultCategories.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData

struct DefaultCategories {
    
    static let expenseCategories = [
        CategoryData(name: "Bills & Utilities", iconName: "doc.text.fill", colorHex: "BB8FCE", transactionType: .expense),
        CategoryData(name: "Food & Dining", iconName: "fork.knife", colorHex: "FF6B6B", transactionType: .expense),
        CategoryData(name: "Healthcare", iconName: "heart.fill", colorHex: "F1948A", transactionType: .expense),
        CategoryData(name: "Personal Care", iconName: "person.fill", colorHex: "F8C471", transactionType: .expense),
        CategoryData(name: "Shopping", iconName: "bag.fill", colorHex: "45B7D1", transactionType: .expense),
        CategoryData(name: "Entertainment", iconName: "gamecontroller.fill", colorHex: "F7DC6F", transactionType: .expense),
        CategoryData(name: "Transportation", iconName: "car.fill", colorHex: "4ECDC4", transactionType: .expense),
        CategoryData(name: "Education", iconName: "book.fill", colorHex: "85C1E9", transactionType: .expense),
        CategoryData(name: "Travel", iconName: "airplane", colorHex: "82E0AA", transactionType: .expense)
    ]
    
    static let incomeCategories = [
        CategoryData(name: "Salary", iconName: "banknote.fill", colorHex: "58D68D", transactionType: .income),
        CategoryData(name: "Freelance", iconName: "laptopcomputer", colorHex: "5DADE2", transactionType: .income),
        CategoryData(name: "Investment", iconName: "chart.line.uptrend.xyaxis", colorHex: "F7DC6F", transactionType: .income),
        CategoryData(name: "Business", iconName: "building.2.fill", colorHex: "AF7AC5", transactionType: .income),
        CategoryData(name: "Bonus", iconName: "gift.fill", colorHex: "FF9F43", transactionType: .income),
        CategoryData(name: "Rental", iconName: "house.fill", colorHex: "54A0FF", transactionType: .income)
    ]
    
    static func createDefaultCategories(in context: ModelContext) {
        // Check if categories already exist
        let descriptor = FetchDescriptor<Category>()
        let existingCategories = try? context.fetch(descriptor)
        
        if existingCategories?.isEmpty ?? true {
            // Create expense categories
            for categoryData in expenseCategories {
                let category = Category(
                    name: categoryData.name,
                    iconName: categoryData.iconName,
                    colorHex: categoryData.colorHex,
                    transactionType: categoryData.transactionType
                )
                context.insert(category)
            }
            
            // Create income categories
            for categoryData in incomeCategories {
                let category = Category(
                    name: categoryData.name,
                    iconName: categoryData.iconName,
                    colorHex: categoryData.colorHex,
                    transactionType: categoryData.transactionType
                )
                context.insert(category)
            }
            
            // Save the context
            try? context.save()
        }
    }
}

struct CategoryData {
    let name: String
    let iconName: String
    let colorHex: String
    let transactionType: TransactionType
} 