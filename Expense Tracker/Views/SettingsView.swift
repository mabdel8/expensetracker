//
//  SettingsView.swift
//  Expense Tracker
//
//  Created by Abdalla Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData
import StoreKit
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
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        requestAppReview()
                    }) {
                        HStack {
                            Text("Rate the App")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
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
    
    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
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
    @Query private var allCategories: [Category]
    @Query private var transactions: [Transaction]
    
    @State private var isSelectionMode = false
    @State private var selectedCategories: Set<Category> = []
    @State private var showingAddCategory = false
    @State private var categoryToEdit: Category?
    @State private var showingDeleteAlert = false
    @State private var showingResetAlert = false
    
    var categories: [Category] {
        categoryManager.categories
    }
    
    var expenseCategories: [Category] {
        categories.filter { $0.transactionType == .expense }
    }
    
    var incomeCategories: [Category] {
        categories.filter { $0.transactionType == .income }
    }
    
    var totalUsageCount: Int {
        transactions.count
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
        // Delete all existing categories
        for category in categories {
            modelContext.delete(category)
        }
        
        // Reset the flag and create defaults
        UserDefaults.standard.removeObject(forKey: "HasAttemptedCategoryCreation")
        DefaultCategories.createDefaultCategories(in: modelContext)
        
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
    @EnvironmentObject private var categoryManager: CategoryManager
    @Query private var monthlyBudgets: [MonthlyBudget]
    @Query private var categoryBudgets: [CategoryBudget]
    
    @State private var isSelectionMode = false
    @State private var selectedBudgets: Set<MonthlyBudget> = []
    @State private var showingEditBudget = false
    @State private var showingDeleteAlert = false
    @State private var selectedMonth = Date()
    
    var expenseCategories: [Category] {
        categoryManager.categories.filter { $0.transactionType == .expense }
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
                ForEach(monthlyBudgets, id: \.month) { budget in
                    MonthlyBudgetRow(
                        budget: budget,
                        isSelectionMode: isSelectionMode,
                        isSelected: selectedBudgets.contains(budget),
                        onToggleSelection: {
                            toggleSelection(for: budget)
                        },
                        onEdit: {
                            selectedMonth = budget.month
                            showingEditBudget = true
                        }
                    )
                }
            }
        }
        .navigationTitle("Budgets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isSelectionMode {
                    Button("Cancel") {
                        isSelectionMode = false
                        selectedBudgets.removeAll()
                    }
                } else {
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
    
    private func toggleSelection(for budget: MonthlyBudget) {
        if selectedBudgets.contains(budget) {
            selectedBudgets.remove(budget)
        } else {
            selectedBudgets.insert(budget)
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
    let budget: MonthlyBudget
    let isSelectionMode: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onEdit: () -> Void

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
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(budget.monthYear)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(budget.formattedTotalBudget)
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