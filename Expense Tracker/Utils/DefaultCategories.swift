//
//  DefaultCategories.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData

struct SubcategoryData {
    let name: String
    let parentCategory: String
}

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
    
    static let defaultSubcategories: [String: [String]] = [
        "Bills & Utilities": ["Rent/Mortgage", "Electricity", "Water", "Gas", "Internet", "Phone", "Insurance", "Trash"],
        "Food & Dining": ["Groceries", "Restaurants", "Coffee/Tea", "Takeout", "Snacks"],
        "Healthcare": ["Doctor visits", "Medications", "Dental", "Vision", "Health Insurance"],
        "Personal Care": ["Haircuts", "Skincare", "Gym", "Clothing", "Cosmetics"],
        "Shopping": ["Clothes", "Electronics", "Home goods", "Gifts", "Books"],
        "Entertainment": ["Movies", "Concerts", "Games", "Streaming", "Sports"],
        "Transportation": ["Gas", "Public transit", "Parking", "Car maintenance", "Uber/Lyft"],
        "Education": ["Tuition", "Books", "Courses", "Supplies", "Certifications"],
        "Travel": ["Flights", "Hotels", "Food", "Activities", "Transportation"]
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
        do {
            // Get all existing categories first
            let allCategoriesDescriptor = FetchDescriptor<Category>()
            let existingCategories = try context.fetch(allCategoriesDescriptor)
            let existingCategoryNames = Set(existingCategories.map { $0.name })
            
            print("Found \(existingCategories.count) existing categories: \(existingCategoryNames)")
            
            // Check if any default categories already exist
            let allDefaultCategories = expenseCategories + incomeCategories
            let defaultCategoryNames = Set(allDefaultCategories.map { $0.name })
            
            // Check for any overlap between existing and default categories
            let overlappingCategories = existingCategoryNames.intersection(defaultCategoryNames)
            
            if !overlappingCategories.isEmpty {
                print("Default categories already exist (\(overlappingCategories.count) found): \(overlappingCategories)")
                print("Skipping default category creation to prevent duplicates")
                return
            }
            
            // If we have any categories at all, be extra cautious
            if !existingCategories.isEmpty {
                print("Found \(existingCategories.count) existing categories, checking if they might be defaults with different names...")
                
                // Check if we have categories that look like defaults (same count as our defaults)
                if existingCategories.count >= (expenseCategories.count + incomeCategories.count) / 2 {
                    print("Sufficient categories already exist, skipping default creation")
                    return
                }
            }
            
            print("No conflicting categories found. Creating default categories...")
            
            // Create expense categories
            for categoryData in expenseCategories {
                // Double-check this specific category doesn't exist
                if !existingCategoryNames.contains(categoryData.name) {
                    let category = Category(
                        name: categoryData.name,
                        iconName: categoryData.iconName,
                        colorHex: categoryData.colorHex,
                        transactionType: categoryData.transactionType
                    )
                    context.insert(category)
                    print("Created expense category: \(categoryData.name)")
                }
            }
            
            // Create income categories
            for categoryData in incomeCategories {
                // Double-check this specific category doesn't exist
                if !existingCategoryNames.contains(categoryData.name) {
                    let category = Category(
                        name: categoryData.name,
                        iconName: categoryData.iconName,
                        colorHex: categoryData.colorHex,
                        transactionType: categoryData.transactionType
                    )
                    context.insert(category)
                    print("Created income category: \(categoryData.name)")
                }
            }
            
            // Save the context
            try context.save()
            print("Default categories created successfully")
            
        } catch {
            print("Error setting up default categories: \(error)")
        }
    }
}

struct CategoryData {
    let name: String
    let iconName: String
    let colorHex: String
    let transactionType: TransactionType
} 