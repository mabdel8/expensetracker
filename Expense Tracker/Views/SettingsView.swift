//
//  SettingsView.swift
//  Expense Tracker
//
//  Created by Abdalla Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @Query private var monthlyBudgets: [MonthlyBudget]
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
        
        // Delete all monthly budgets
        for budget in monthlyBudgets {
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
    @Query private var monthlyBudgets: [MonthlyBudget]
    @Query private var categoryBudgets: [CategoryBudget]
    @Query private var categories: [Category]
    
    @State private var showingEditBudget = false
    @State private var selectedMonth = Date()
    @State private var showingDeleteAlert = false
    @State private var isSelectionMode = false
    @State private var selectedBudgets: Set<MonthlyBudget> = []
    
    private var expenseCategories: [Category] {
        let filtered = categories.filter { $0.transactionType == .expense }
        let desiredOrder = [
            "Bills & Utilities",
            "Food & Dining",
            "Healthcare",
            "Personal Care",
            "Shopping",
            "Entertainment",
            "Transportation",
            "Education",
            "Travel"
        ]
        
        return filtered.sorted { category1, category2 in
            let index1 = desiredOrder.firstIndex(of: category1.name) ?? Int.max
            let index2 = desiredOrder.firstIndex(of: category2.name) ?? Int.max
            return index1 < index2
        }
    }
    
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
                ForEach(monthlyBudgets.sorted(by: { $0.month > $1.month }), id: \.month) { monthlyBudget in
                    HStack {
                        if isSelectionMode {
                            Button(action: {
                                if selectedBudgets.contains(monthlyBudget) {
                                    selectedBudgets.remove(monthlyBudget)
                                } else {
                                    selectedBudgets.insert(monthlyBudget)
                                }
                            }) {
                                Image(systemName: selectedBudgets.contains(monthlyBudget) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedBudgets.contains(monthlyBudget) ? .blue : .gray)
                                    .font(.title2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        MonthlyBudgetRow(
                            monthlyBudget: monthlyBudget,
                            isSelectionMode: isSelectionMode
                        )
                        .onTapGesture {
                            if isSelectionMode {
                                if selectedBudgets.contains(monthlyBudget) {
                                    selectedBudgets.remove(monthlyBudget)
                                } else {
                                    selectedBudgets.insert(monthlyBudget)
                                }
                            } else {
                                selectedMonth = monthlyBudget.month
                                showingEditBudget = true
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if !isSelectionMode {
                            Button(role: .destructive) {
                                selectedBudgets = [monthlyBudget]
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Budgets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isSelectionMode {
                    Button("Select") {
                        isSelectionMode = true
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelectionMode {
                VStack {
                    Divider()
                    HStack {
                        Button(action: {
                            isSelectionMode = false
                            selectedBudgets.removeAll()
                        }) {
                            Text("Cancel")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Text("Delete (\(selectedBudgets.count))")
                                .font(.body)
                                .foregroundColor(selectedBudgets.isEmpty ? .gray : .red)
                        }
                        .disabled(selectedBudgets.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
            }
        }
        .sheet(isPresented: $showingEditBudget) {
            EditBudgetView(month: selectedMonth, expenseCategories: expenseCategories)
        }
        .alert("Delete Budget\(selectedBudgets.count > 1 ? "s" : "")", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                if !isSelectionMode {
                    selectedBudgets.removeAll()
                }
            }
            Button("Delete", role: .destructive) {
                deleteBudgets()
            }
        } message: {
            if selectedBudgets.count == 1 {
                if let budget = selectedBudgets.first {
                    Text("Are you sure you want to delete the budget for \(budget.monthYear)? This action cannot be undone.")
                }
            } else {
                Text("Are you sure you want to delete \(selectedBudgets.count) budgets? This action cannot be undone.")
            }
        }
    }
    
    private func deleteBudgets() {
        let calendar = Calendar.current
        
        // Delete associated category budgets for all selected budgets
        for budget in selectedBudgets {
            let associatedCategoryBudgets = categoryBudgets.filter { categoryBudget in
                calendar.isDate(categoryBudget.month, equalTo: budget.month, toGranularity: .month)
            }
            
            for categoryBudget in associatedCategoryBudgets {
                modelContext.delete(categoryBudget)
            }
            
            // Delete the monthly budget
            modelContext.delete(budget)
        }
        
        // Save changes
        do {
            try modelContext.save()
            
            // Exit selection mode after successful deletion
            selectedBudgets.removeAll()
            isSelectionMode = false
            
        } catch {
            print("Failed to delete budgets: \(error)")
        }
    }
}

struct MonthlyBudgetRow: View {
    let monthlyBudget: MonthlyBudget
    let isSelectionMode: Bool
    @Query private var transactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(monthlyBudget.monthYear)
                    .font(.headline)
                
                Spacer()
                
                Text(monthlyBudget.formattedTotalBudget)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !isSelectionMode {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("Allocated")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatCurrency(monthlyBudget.allocatedBudget))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Spent")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                let spentAmount = monthlyBudget.getSpentAmount(from: transactions)
                Text(formatCurrency(spentAmount))
                    .font(.caption)
                    .foregroundColor(spentAmount > monthlyBudget.totalBudget ? .red : .secondary)
            }
            
            let progressPercentage = monthlyBudget.totalBudget > 0 ? monthlyBudget.getSpentAmount(from: transactions) / monthlyBudget.totalBudget : 0
            ProgressView(value: progressPercentage)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(progressPercentage > 1.0 ? .red : .blue)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // Makes entire row tappable
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
        .modelContainer(for: [Transaction.self, Category.self, RecurringSubscription.self, MonthlyBudget.self, CategoryBudget.self], inMemory: true)
} 