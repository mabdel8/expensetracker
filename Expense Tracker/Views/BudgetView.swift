//
//  BudgetView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var allCategories: [Category]
    
    @State private var paycheckAmount: String = ""
    @State private var paymentFrequency: PaymentFrequency = .monthly
    @State private var showingAddBudget = false
    @State private var budgetAmounts: [String: String] = [:]
    
    private var expenseCategories: [Category] {
        allCategories.filter { $0.transactionType == .expense }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Budget Planning")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Manage your income and spending budgets")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Paycheck Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Income Information")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            // Paycheck Amount
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Paycheck Amount")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                TextField("Enter your paycheck amount", text: $paycheckAmount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Payment Frequency
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Payment Frequency")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Picker("Payment Frequency", selection: $paymentFrequency) {
                                    ForEach(PaymentFrequency.allCases, id: \.self) { frequency in
                                        Text(frequency.rawValue).tag(frequency)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Monthly Budget Summary
                    if let monthlyIncome = calculateMonthlyIncome() {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Monthly Budget Summary")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Monthly Income")
                                    Spacer()
                                    Text(formatCurrency(monthlyIncome))
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                
                                HStack {
                                    Text("Total Budget")
                                    Spacer()
                                    Text(formatCurrency(totalBudgetAmount))
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Remaining")
                                    Spacer()
                                    Text(formatCurrency(monthlyIncome - totalBudgetAmount))
                                        .fontWeight(.bold)
                                        .foregroundColor(monthlyIncome - totalBudgetAmount >= 0 ? .green : .red)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Spending Categories
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Spending Categories")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(expenseCategories, id: \.name) { category in
                                BudgetCategoryRow(
                                    category: category,
                                    budgetAmount: Binding(
                                        get: { budgetAmounts[category.name] ?? "" },
                                        set: { budgetAmounts[category.name] = $0 }
                                    )
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudgets()
                    }
                    .disabled(paycheckAmount.isEmpty)
                }
            }
        }
        .onAppear {
            loadExistingBudgets()
        }
    }
    
    private func calculateMonthlyIncome() -> Double? {
        guard let paycheck = Double(paycheckAmount), paycheck > 0 else { return nil }
        
        switch paymentFrequency {
        case .weekly:
            return paycheck * 4.33 // Average weeks per month
        case .biweekly:
            return paycheck * 2.17 // Average bi-weekly periods per month
        case .monthly:
            return paycheck
        case .yearly:
            return paycheck / 12
        }
    }
    
    private var totalBudgetAmount: Double {
        budgetAmounts.values.compactMap { Double($0) }.reduce(0, +)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func loadExistingBudgets() {
        // Load existing budget amounts
        for budget in budgets {
            if let category = budget.category {
                budgetAmounts[category.name] = String(budget.amount)
            }
        }
    }
    
    private func saveBudgets() {
        guard let monthlyIncome = calculateMonthlyIncome() else { return }
        
        // Clear existing budgets
        for budget in budgets {
            modelContext.delete(budget)
        }
        
        // Create new budgets for each category with an amount
        for (categoryName, amountString) in budgetAmounts {
            guard let amount = Double(amountString), amount > 0 else { continue }
            
            if let category = expenseCategories.first(where: { $0.name == categoryName }) {
                let startDate = Calendar.current.startOfMonth(for: Date())
                let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? Date()
                
                let budget = Budget(
                    amount: amount,
                    startDate: startDate,
                    endDate: endDate,
                    category: category
                )
                
                modelContext.insert(budget)
            }
        }
        
        // Save the context
        try? modelContext.save()
    }
}

struct BudgetCategoryRow: View {
    let category: Category
    @Binding var budgetAmount: String
    
    var body: some View {
        HStack {
            // Category icon and name
            HStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Monthly budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Budget amount input
            TextField("$0", text: $budgetAmount)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 100)
                .multilineTextAlignment(.trailing)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

enum PaymentFrequency: String, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

// Extension to help with calendar calculations
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: [Transaction.self, Category.self, Budget.self], inMemory: true)
} 