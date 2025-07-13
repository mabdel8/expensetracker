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
    
    var expenseCategories: [Category] {
        categories.filter { $0.transactionType == .expense }
    }
    
    var incomeCategories: [Category] {
        categories.filter { $0.transactionType == .income }
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
                
                Section("Data") {
                    NavigationLink(destination: AllTransactionsView()) {
                        Label("Transaction History", systemImage: "list.bullet.rectangle")
                    }
                    
                    Button(action: {
                        // TODO: Implement data export
                    }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        // TODO: Implement data backup
                    }) {
                        Label("Backup Data", systemImage: "icloud.and.arrow.up")
                    }
                }
                
                Section("App Info") {
                    HStack {
                        Text("Categories")
                        Spacer()
                        Text("\(categories.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Budgets")
                        Spacer()
                        Text("\(budgets.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
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
        .modelContainer(for: [Transaction.self, Category.self, Budget.self, RecurringSubscription.self], inMemory: true)
} 