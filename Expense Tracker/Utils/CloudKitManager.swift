//
//  CloudKitManager.swift
//  Expense Tracker
//
//  Created by Assistant on 7/9/25.
//

import SwiftUI
import CloudKit
import SwiftData

@MainActor
class CloudKitManager: ObservableObject {
    private let container = CKContainer.default()
    private let database: CKDatabase
    
    @Published var isBackupInProgress = false
    @Published var lastBackupDate: Date?
    @Published var backupError: String?
    @Published var iCloudAccountStatus: CKAccountStatus = .couldNotDetermine
    
    init() {
        self.database = container.publicCloudDatabase
        checkiCloudAccountStatus()
    }
    
    // MARK: - iCloud Account Status
    
    func checkiCloudAccountStatus() {
        Task {
            do {
                let status = try await container.accountStatus()
                await MainActor.run {
                    self.iCloudAccountStatus = status
                }
            } catch {
                await MainActor.run {
                    self.backupError = "Failed to check iCloud status: \(error.localizedDescription)"
                }
            }
        }
    }
    
    var iCloudStatusMessage: String {
        switch iCloudAccountStatus {
        case .available:
            return "iCloud is available"
        case .noAccount:
            return "No iCloud account found. Please sign in to iCloud in Settings."
        case .restricted:
            return "iCloud access is restricted"
        case .couldNotDetermine:
            return "Could not determine iCloud status"
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable"
        @unknown default:
            return "Unknown iCloud status"
        }
    }
    
    var canBackup: Bool {
        return iCloudAccountStatus == .available
    }
    
    // MARK: - Backup Operations
    
    func performBackup(modelContext: ModelContext) async {
        guard canBackup else {
            await MainActor.run {
                self.backupError = "iCloud is not available for backup"
            }
            return
        }
        
        await MainActor.run {
            self.isBackupInProgress = true
            self.backupError = nil
        }
        
        do {
            // Fetch all data from SwiftData
            let transactions = try modelContext.fetch(FetchDescriptor<Transaction>())
            let categories = try modelContext.fetch(FetchDescriptor<Category>())
            let monthlyBudgets = try modelContext.fetch(FetchDescriptor<MonthlyBudget>())
            let categoryBudgets = try modelContext.fetch(FetchDescriptor<CategoryBudget>())
            let recurringSubscriptions = try modelContext.fetch(FetchDescriptor<RecurringSubscription>())
            let plannedIncomes = try modelContext.fetch(FetchDescriptor<PlannedIncome>())
            let plannedExpenses = try modelContext.fetch(FetchDescriptor<PlannedExpense>())
            
            // Create backup record
            let backupRecord = CKRecord(recordType: "ExpenseTrackerBackup")
            backupRecord["timestamp"] = Date()
            backupRecord["transactionCount"] = transactions.count
            backupRecord["categoryCount"] = categories.count
            backupRecord["monthlyBudgetCount"] = monthlyBudgets.count
            backupRecord["categoryBudgetCount"] = categoryBudgets.count
            
            // Convert data to JSON for storage
            let backupData = ExpenseTrackerBackupData(
                transactions: transactions.map { TransactionBackup(from: $0) },
                categories: categories.map { CategoryBackup(from: $0) },
                monthlyBudgets: monthlyBudgets.map { MonthlyBudgetBackup(from: $0) },
                categoryBudgets: categoryBudgets.map { CategoryBudgetBackup(from: $0) },
                recurringSubscriptions: recurringSubscriptions.map { RecurringSubscriptionBackup(from: $0) },
                plannedIncomes: plannedIncomes.map { PlannedIncomeBackup(from: $0) },
                plannedExpenses: plannedExpenses.map { PlannedExpenseBackup(from: $0) }
            )
            
            let jsonData = try JSONEncoder().encode(backupData)
            backupRecord["backupData"] = jsonData
            
            // Save to CloudKit
            try await database.save(backupRecord)
            
            await MainActor.run {
                self.lastBackupDate = Date()
                self.isBackupInProgress = false
                // Store last backup date in UserDefaults
                UserDefaults.standard.set(Date(), forKey: "lastBackupDate")
            }
            
        } catch {
            await MainActor.run {
                self.backupError = "Backup failed: \(error.localizedDescription)"
                self.isBackupInProgress = false
            }
        }
    }
    
    func loadLastBackupDate() {
        lastBackupDate = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
    }
}

// MARK: - Backup Data Models

struct ExpenseTrackerBackupData: Codable {
    let transactions: [TransactionBackup]
    let categories: [CategoryBackup]
    let monthlyBudgets: [MonthlyBudgetBackup]
    let categoryBudgets: [CategoryBudgetBackup]
    let recurringSubscriptions: [RecurringSubscriptionBackup]
    let plannedIncomes: [PlannedIncomeBackup]
    let plannedExpenses: [PlannedExpenseBackup]
}

struct TransactionBackup: Codable {
    let name: String
    let date: Date
    let amount: Double
    let notes: String?
    let type: String
    let categoryName: String?
    
    init(from transaction: Transaction) {
        self.name = transaction.name
        self.date = transaction.date
        self.amount = transaction.amount
        self.notes = transaction.notes
        self.type = transaction.type.rawValue
        self.categoryName = transaction.category?.name
    }
}

struct CategoryBackup: Codable {
    let name: String
    let iconName: String
    let colorHex: String
    let transactionType: String
    
    init(from category: Category) {
        self.name = category.name
        self.iconName = category.iconName
        self.colorHex = category.colorHex
        self.transactionType = category.transactionType.rawValue
    }
}



struct MonthlyBudgetBackup: Codable {
    let totalBudget: Double
    let month: Date
    
    init(from budget: MonthlyBudget) {
        self.totalBudget = budget.totalBudget
        self.month = budget.month
    }
}

struct CategoryBudgetBackup: Codable {
    let allocatedAmount: Double
    let month: Date
    let categoryName: String?
    
    init(from budget: CategoryBudget) {
        self.allocatedAmount = budget.allocatedAmount
        self.month = budget.month
        self.categoryName = budget.category?.name
    }
}

struct RecurringSubscriptionBackup: Codable {
    let name: String
    let amount: Double
    let frequency: String
    let startDate: Date
    let nextDueDate: Date
    let isActive: Bool
    let notes: String?
    let type: String
    let categoryName: String?
    
    init(from subscription: RecurringSubscription) {
        self.name = subscription.name
        self.amount = subscription.amount
        self.frequency = subscription.frequency.rawValue
        self.startDate = subscription.startDate
        self.nextDueDate = subscription.nextDueDate
        self.isActive = subscription.isActive
        self.notes = subscription.notes
        self.type = subscription.type.rawValue
        self.categoryName = subscription.category?.name
    }
}

struct PlannedIncomeBackup: Codable {
    let name: String
    let amount: Double
    let month: Date
    
    init(from income: PlannedIncome) {
        self.name = income.name
        self.amount = income.amount
        self.month = income.month
    }
}

struct PlannedExpenseBackup: Codable {
    let name: String
    let amount: Double
    let month: Date
    let categoryName: String?
    
    init(from expense: PlannedExpense) {
        self.name = expense.name
        self.amount = expense.amount
        self.month = expense.month
        self.categoryName = expense.category?.name
    }
} 