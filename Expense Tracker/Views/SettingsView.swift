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
    @Query private var transactions: [Transaction]
    
    @State private var showingAddCategory = false
    @State private var categoryToEdit: Category?
    @State private var isSelectionMode = false
    @State private var selectedCategories: Set<Category> = []
    @State private var showingDeleteAlert = false
    @State private var showingResetAlert = false
    
    private var expenseCategories: [Category] {
        categories.filter { $0.transactionType == .expense }
            .sorted { $0.name < $1.name }
    }
    
    private var incomeCategories: [Category] {
        categories.filter { $0.transactionType == .income }
            .sorted { $0.name < $1.name }
    }
    
    private var totalUsageCount: Int {
        categories.reduce(0) { total, category in
            total + (category.transactions?.count ?? 0)
        }
    }
    
    var body: some View {
        List {
            // Statistics Section
            if !categories.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Categories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(categories.count)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Used in Transactions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(totalUsageCount)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Button(action: {
                            showingResetAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                Text("Reset to Defaults")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Overview")
                }
            }
            
            // Expense Categories
            Section {
                if expenseCategories.isEmpty {
                    Text("No expense categories")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(expenseCategories, id: \.name) { category in
                        CategoryRow(
                            category: category,
                            isSelectionMode: isSelectionMode,
                            isSelected: selectedCategories.contains(category),
                            onEdit: {
                                categoryToEdit = category
                            },
                            onToggleSelection: {
                                toggleSelection(for: category)
                            }
                        )
                    }
                }
            } header: {
                HStack {
                    Text("Expense Categories (\(expenseCategories.count))")
                    Spacer()
                    if !expenseCategories.isEmpty && !isSelectionMode {
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Income Categories
            Section {
                if incomeCategories.isEmpty {
                    Text("No income categories")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(incomeCategories, id: \.name) { category in
                        CategoryRow(
                            category: category,
                            isSelectionMode: isSelectionMode,
                            isSelected: selectedCategories.contains(category),
                            onEdit: {
                                categoryToEdit = category
                            },
                            onToggleSelection: {
                                toggleSelection(for: category)
                            }
                        )
                    }
                }
            } header: {
                HStack {
                    Text("Income Categories (\(incomeCategories.count))")
                    Spacer()
                    if !incomeCategories.isEmpty && !isSelectionMode {
                        Button(action: {
                            showingAddCategory = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isSelectionMode {
                    Button("Delete (\(selectedCategories.count))") {
                        showingDeleteAlert = true
                    }
                    .disabled(selectedCategories.isEmpty)
                    .foregroundColor(selectedCategories.isEmpty ? .gray : .red)
                } else {
                    if categories.isEmpty {
                        Button("Add") {
                            showingAddCategory = true
                        }
                    } else {
                        Button("Select") {
                            isSelectionMode = true
                        }
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
                            selectedCategories.removeAll()
                        }) {
                            Text("Cancel")
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Text("Delete (\(selectedCategories.count))")
                                .font(.body)
                                .foregroundColor(selectedCategories.isEmpty ? .gray : .red)
                        }
                        .disabled(selectedCategories.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddEditCategoryView()
        }
        .sheet(item: $categoryToEdit) { category in
            AddEditCategoryView(categoryToEdit: category)
        }
        .alert("Delete Categories", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                if !isSelectionMode {
                    selectedCategories.removeAll()
                }
            }
            Button("Delete", role: .destructive) {
                deleteSelectedCategories()
            }
        } message: {
            if selectedCategories.count == 1 {
                if let category = selectedCategories.first {
                    Text("Are you sure you want to delete '\(category.name)'? This will also delete all associated transactions and cannot be undone.")
                }
            } else {
                Text("Are you sure you want to delete \(selectedCategories.count) categories? This will also delete all associated transactions and cannot be undone.")
            }
        }
        .alert("Reset Categories", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("This will remove all custom categories and restore the default categories. Transactions using custom categories will be uncategorized and can be reassigned. This action cannot be undone.")
        }
    }
    
    private func toggleSelection(for category: Category) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
    
    private func deleteSelectedCategories() {
        for category in selectedCategories {
            // Delete associated transactions
            if let transactions = category.transactions {
                for transaction in transactions {
                    modelContext.delete(transaction)
                }
            }
            
            // Delete the category
            modelContext.delete(category)
        }
        
        do {
            try modelContext.save()
            selectedCategories.removeAll()
            isSelectionMode = false
        } catch {
            print("Failed to delete categories: \(error)")
        }
    }
    
    private func resetToDefaults() {
        // Get all default category data
        let defaultExpenseCategories = DefaultCategories.expenseCategories
        let defaultIncomeCategories = DefaultCategories.incomeCategories
        let allDefaultCategories = defaultExpenseCategories + defaultIncomeCategories
        
        // Create a set of default category names for quick lookup
        let defaultCategoryNames = Set(allDefaultCategories.map { $0.name.lowercased() })
        
        // Find transactions that use custom categories (not in defaults)
        var transactionsToUpdate: [Transaction] = []
        
        // Identify custom categories to delete
        var categoriesToDelete: [Category] = []
        
        for category in categories {
            if !defaultCategoryNames.contains(category.name.lowercased()) {
                // This is a custom category, mark for deletion
                categoriesToDelete.append(category)
                
                // Collect transactions that use this custom category
                if let categoryTransactions = category.transactions {
                    transactionsToUpdate.append(contentsOf: categoryTransactions)
                }
            }
        }
        
        // Update transactions from custom categories to have no category
        // Users can manually reassign them later
        for transaction in transactionsToUpdate {
            transaction.category = nil
        }
        
        // Delete only custom categories
        for category in categoriesToDelete {
            modelContext.delete(category)
        }
        
        // Create any missing default categories
        for defaultCategoryData in allDefaultCategories {
            let categoryExists = categories.contains { category in
                category.name.lowercased() == defaultCategoryData.name.lowercased() &&
                category.transactionType == defaultCategoryData.transactionType
            }
            
            if !categoryExists {
                let newCategory = Category(
                    name: defaultCategoryData.name,
                    iconName: defaultCategoryData.iconName,
                    colorHex: defaultCategoryData.colorHex,
                    transactionType: defaultCategoryData.transactionType
                )
                modelContext.insert(newCategory)
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to reset categories: \(error)")
        }
    }
}

struct CategoryRow: View {
    let category: Category
    let isSelectionMode: Bool
    let isSelected: Bool
    let onEdit: () -> Void
    let onToggleSelection: () -> Void
    
    private var transactionCount: Int {
        category.transactions?.count ?? 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if isSelectionMode {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            CategoryIconView(category: category, size: 28)
            
            Text(category.name)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            if !isSelectionMode {
                Text("\(transactionCount) transaction\(transactionCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, isSelectionMode ? 8 : 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelectionMode {
                onToggleSelection()
            } else {
                onEdit()
            }
        }
        .swipeActions(edge: .trailing) {
            if !isSelectionMode {
                Button(role: .destructive) {
                    // Single delete via swipe
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
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