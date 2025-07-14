//
//  SettingsView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @Query private var budgets: [Budget]
    @Query private var transactions: [Transaction]
    @Query private var recurringSubscriptions: [RecurringSubscription]
    
    @State private var showingClearDataAlert = false
    
    var expenseCategories: [Category] {
        categories.filter { $0.transactionType == .expense }
    }
    
    var incomeCategories: [Category] {
        categories.filter { $0.transactionType == .income }
    }
    
    private var totalTransactions: Int {
        transactions.count
    }
    
    private var totalSpent: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Management") {
                    NavigationLink(destination: CategoriesManagementView()) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            Text("Manage Categories")
                        }
                    }
                    
                    NavigationLink(destination: BudgetsManagementView()) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Manage Budgets")
                        }
                    }
                    
                    NavigationLink(destination: RecurringSubscriptionsView()) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(.purple)
                                .frame(width: 20)
                            Text("Recurring Subscriptions")
                        }
                    }
                }
                
                Section("Data & Reports") {
                    NavigationLink(destination: AllTransactionsView()) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            Text("Transaction History")
                        }
                    }
                    
                    Button(action: {
                        // TODO: Implement data export
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.indigo)
                                .frame(width: 20)
                            Text("Export Data")
                            Spacer()
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        showingClearDataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .frame(width: 20)
                            Text("Clear All Data")
                            Spacer()
                        }
                    }
                    .foregroundColor(.red)
                }
                
                Section("Statistics") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Transactions")
                                .font(.body)
                            Text("\(totalTransactions)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Categories")
                                .font(.body)
                            Text("\(categories.count)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Income")
                                .font(.body)
                            Text(formatCurrency(totalIncome))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Total Expenses")
                                .font(.body)
                            Text(formatCurrency(totalSpent))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Net Balance")
                                .font(.body)
                            Text(formatCurrency(totalIncome - totalSpent))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(totalIncome - totalSpent >= 0 ? .green : .red)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Subscriptions")
                                .font(.body)
                            Text("\(recurringSubscriptions.count)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        // TODO: Add privacy policy
                    }) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        // TODO: Add support/feedback
                    }) {
                        HStack {
                            Text("Support & Feedback")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Settings")
            .alert("Clear All Data", isPresented: $showingClearDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllData()
                }
            } message: {
                Text("This will permanently delete all your transactions, budgets, and categories. This action cannot be undone.")
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func clearAllData() {
        // Delete all transactions
        for transaction in transactions {
            modelContext.delete(transaction)
        }
        
        // Delete all recurring subscriptions
        for subscription in recurringSubscriptions {
            modelContext.delete(subscription)
        }
        
        // Delete all budgets
        for budget in budgets {
            modelContext.delete(budget)
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}

struct CategoriesManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    
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
        categories.filter { $0.transactionType == .expense }
    }
    
    private var incomeCategories: [Category] {
        categories.filter { $0.transactionType == .income }
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
    @Query private var budgets: [Budget]
    
    var body: some View {
        List {
            if budgets.isEmpty {
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
                ForEach(budgets, id: \.amount) { budget in
                    BudgetRow(budget: budget)
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

struct BudgetRow: View {
    let budget: Budget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.category?.name ?? "Unknown Category")
                    .font(.headline)
                
                Spacer()
                
                Text(budget.formattedAmount)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(budget.progressPercentage * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: budget.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Transaction.self, Category.self, Budget.self, RecurringSubscription.self, MonthlyBudget.self, CategoryBudget.self], inMemory: true)
} 