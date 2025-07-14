//
//  SettingsView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData
import CloudKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var categoryManager: CategoryManager
    @Query private var monthlyBudgets: [MonthlyBudget]
    @Query private var transactions: [Transaction]
    @Query private var categoryBudgets: [CategoryBudget]
    @Query private var recurringSubscriptions: [RecurringSubscription]
    @Query private var plannedIncomes: [PlannedIncome]
    @Query private var plannedExpenses: [PlannedExpense]
    @StateObject private var cloudKitManager = CloudKitManager()
    @State private var showingBackupAlert = false
    @State private var backupAlertMessage = ""
    @State private var showingClearDataAlert = false
    
    var expenseCategories: [Category] {
        categoryManager.categories.filter { $0.transactionType == .expense }
    }
    
    var incomeCategories: [Category] {
        categoryManager.categories.filter { $0.transactionType == .income }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Categories") {
                    NavigationLink(destination: CategoriesManagementView()) {
                        Label("Manage Categories", systemImage: "folder.fill")
                        Text("Customize your expense and income categories")
                    }
                }
                
                Section("Budgets") {
                    NavigationLink(destination: BudgetsManagementView()) {
                        Label("Manage Budgets", systemImage: "chart.bar.fill")
                        Text("Set and track your spending budgets")
                    }
                }
                
                Section("iCloud Backup") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: cloudKitManager.canBackup ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .foregroundColor(cloudKitManager.canBackup ? .green : .orange)
                            
                            Text(cloudKitManager.iCloudStatusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let lastBackupDate = cloudKitManager.lastBackupDate {
                            Text("Last backup: \(lastBackupDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let error = cloudKitManager.backupError {
                            Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: {
                        performBackup()
                    }) {
                        HStack {
                            if cloudKitManager.isBackupInProgress {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Backing up...")
                            } else {
                                Label("Backup to iCloud", systemImage: "icloud.and.arrow.up")
                            }
                        }
                    }
                    .disabled(!cloudKitManager.canBackup || cloudKitManager.isBackupInProgress)
                    
                    Button(action: {
                        // TODO: Implement data export
                    }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("App Info") {
                    HStack {
                        Text("Categories")
                        Spacer()
                        Text("\(categoryManager.categories.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Budgets")
                        Spacer()
                        Text("\(monthlyBudgets.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Development Tools") {
                    Button(action: {
                        showingClearDataAlert = true
                    }) {
                        Label("Clear All Data", systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        forceCreateDefaultCategories()
                    }) {
                        Label("Force Create Default Categories", systemImage: "folder.badge.plus")
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                cloudKitManager.loadLastBackupDate()
            }
            .alert("Backup Status", isPresented: $showingBackupAlert) {
                Button("OK") { }
            } message: {
                Text(backupAlertMessage)
            }
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all your data including transactions, categories, budgets, and subscriptions. This action cannot be undone.")
            }
        }
    }
    
    private func performBackup() {
        Task {
            await cloudKitManager.performBackup(modelContext: modelContext)
            
            await MainActor.run {
                if cloudKitManager.backupError == nil {
                    backupAlertMessage = "Backup completed successfully!"
                } else {
                    backupAlertMessage = cloudKitManager.backupError ?? "Unknown error occurred"
                }
                showingBackupAlert = true
            }
        }
    }
    
    private func clearAllData() {
        do {
            // Delete all transactions
            for transaction in transactions {
                modelContext.delete(transaction)
            }
            
            // Delete all category budgets
            for categoryBudget in categoryBudgets {
                modelContext.delete(categoryBudget)
            }
            
            // Delete all monthly budgets
            for monthlyBudget in monthlyBudgets {
                modelContext.delete(monthlyBudget)
            }
            
            // Delete all recurring subscriptions
            for subscription in recurringSubscriptions {
                modelContext.delete(subscription)
            }
            
            // Delete all planned incomes
            for plannedIncome in plannedIncomes {
                modelContext.delete(plannedIncome)
            }
            
            // Delete all planned expenses
            for plannedExpense in plannedExpenses {
                modelContext.delete(plannedExpense)
            }
            
            // Delete all categories
            for category in categoryManager.categories {
                modelContext.delete(category)
            }
            
            // Save the context
            try modelContext.save()
            
            // Reset the category creation flag so defaults can be created again
            UserDefaults.standard.removeObject(forKey: "HasAttemptedCategoryCreation")
            
            print("All data cleared successfully")
        } catch {
            print("Error clearing data: \(error)")
        }
    }
    
    private func forceCreateDefaultCategories() {
        // Reset the flag and force create categories
        UserDefaults.standard.removeObject(forKey: "HasAttemptedCategoryCreation")
        DefaultCategories.createDefaultCategories(in: modelContext)
        print("Forced default category creation completed")
    }
}

struct CategoriesManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var categoryManager: CategoryManager
    
    var body: some View {
        List {
            Section("Expense Categories") {
                ForEach(expenseCategories, id: \.name) { category in
                    CategoryRow(category: category)
                }
            }
            
            Section("Income Categories") {
                ForEach(incomeCategories, id: \.name) { category in
                    CategoryRow(category: category)
                }
            }
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    // TODO: Add new category
                }
            }
        }
    }
    
    private var expenseCategories: [Category] {
        categoryManager.categories.filter { $0.transactionType == .expense }
    }
    
    private var incomeCategories: [Category] {
        categoryManager.categories.filter { $0.transactionType == .income }
    }
}

struct CategoryRow: View {
    let category: Category
    
    var body: some View {
        HStack {
            CategoryIconView(category: category, size: 24)
            
            Text(category.name)
            
            Spacer()
            
            Text("\(category.transactions?.count ?? 0) transactions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct BudgetsManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var monthlyBudgets: [MonthlyBudget]
    
    var body: some View {
        List {
            if monthlyBudgets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Budgets Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Create budgets to track your spending limits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ForEach(monthlyBudgets, id: \.totalBudget) { budget in
                    MonthlyBudgetRow(budget: budget)
                }
            }
        }
        .navigationTitle("Budgets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    // TODO: Add new budget
                }
            }
        }
    }
}

struct MonthlyBudgetRow: View {
    let budget: MonthlyBudget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.monthYear)
                    .font(.headline)
                
                Spacer()
                
                Text(budget.formattedTotalBudget)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Allocated")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatCurrency(budget.allocatedBudget))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatCurrency(budget.remainingBudget))
                    .font(.caption)
                    .foregroundColor(budget.remainingBudget >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Transaction.self, Category.self, MonthlyBudget.self, CategoryBudget.self, RecurringSubscription.self], inMemory: true)
} 