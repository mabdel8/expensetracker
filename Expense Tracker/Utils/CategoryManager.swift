//
//  CategoryManager.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class CategoryManager: ObservableObject {
    @Published var categories: [Category] = []
    @Published var isUsingSwiftData: Bool = false
    
    private var modelContext: ModelContext?
    private var hasInitialized = false
    
    // Immediate hardcoded categories for instant UI
    private let immediateCategories: [Category] = {
        var categories: [Category] = []
        
        // Create hardcoded expense categories
        for categoryData in DefaultCategories.expenseCategories {
            let category = Category(
                name: categoryData.name,
                iconName: categoryData.iconName,
                colorHex: categoryData.colorHex,
                transactionType: categoryData.transactionType
            )
            categories.append(category)
        }
        
        // Create hardcoded income categories
        for categoryData in DefaultCategories.incomeCategories {
            let category = Category(
                name: categoryData.name,
                iconName: categoryData.iconName,
                colorHex: categoryData.colorHex,
                transactionType: categoryData.transactionType
            )
            categories.append(category)
        }
        
        return categories
    }()
    
    init() {
        // Show immediate categories for instant UI
        self.categories = immediateCategories
        print("CategoryManager: Initialized with \(immediateCategories.count) immediate categories")
    }
    
    func initialize(with context: ModelContext) {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        self.modelContext = context
        
        // Start background sync process
        Task {
            await setupCategoriesWithCloudKitAwareness()
        }
    }
    
    private func setupCategoriesWithCloudKitAwareness() async {
        guard let context = modelContext else { return }
        
        // Check if we've already attempted category creation
        if UserDefaults.standard.bool(forKey: "HasAttemptedCategoryCreation") {
            print("CategoryManager: Categories setup already attempted, checking SwiftData only")
            do {
                let descriptor = FetchDescriptor<Category>()
                let swiftDataCategories = try context.fetch(descriptor)
                if !swiftDataCategories.isEmpty {
                    await MainActor.run {
                        self.categories = swiftDataCategories
                        self.isUsingSwiftData = true
                    }
                }
            } catch {
                print("CategoryManager: Error checking existing categories: \(error)")
            }
            return
        }
        
        // Give CloudKit time to sync
        for attempt in 1...3 {
            let delay = Double(attempt) * 1.0 // 1s, 2s, 3s
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            print("CategoryManager: Checking for SwiftData categories (attempt \(attempt))")
            
            do {
                let descriptor = FetchDescriptor<Category>()
                let swiftDataCategories = try context.fetch(descriptor)
                
                if !swiftDataCategories.isEmpty {
                    print("CategoryManager: Found \(swiftDataCategories.count) SwiftData categories, switching to SwiftData")
                    await MainActor.run {
                        self.categories = swiftDataCategories
                        self.isUsingSwiftData = true
                    }
                    return
                }
                
                if attempt == 3 {
                    // Final attempt - create default categories
                    print("CategoryManager: No SwiftData categories found, creating defaults")
                    DefaultCategories.createDefaultCategories(in: context)
                    UserDefaults.standard.set(true, forKey: "HasAttemptedCategoryCreation")
                    
                    // Fetch the newly created categories
                    let newCategories = try context.fetch(descriptor)
                    await MainActor.run {
                        self.categories = newCategories.isEmpty ? self.immediateCategories : newCategories
                        self.isUsingSwiftData = !newCategories.isEmpty
                    }
                }
            } catch {
                print("CategoryManager: Error in attempt \(attempt): \(error)")
            }
        }
    }
    
    // Convenience computed properties
    var expenseCategories: [Category] {
        categories.filter { $0.transactionType == .expense }
    }
    
    var incomeCategories: [Category] {
        categories.filter { $0.transactionType == .income }
    }
    
    func refreshFromSwiftData() {
        guard let context = modelContext, isUsingSwiftData else { return }
        
        Task {
            do {
                let descriptor = FetchDescriptor<Category>()
                let swiftDataCategories = try context.fetch(descriptor)
                await MainActor.run {
                    self.categories = swiftDataCategories
                }
            } catch {
                print("CategoryManager: Error refreshing: \(error)")
            }
        }
    }
} 