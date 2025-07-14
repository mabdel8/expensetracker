//
//  BudgetView.swift
//  Expense Tracker
//
//  Created by Abdalla Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData
import Charts

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var monthlyBudgets: [MonthlyBudget]
    @Query private var categoryBudgets: [CategoryBudget]
    @EnvironmentObject private var categoryManager: CategoryManager
    @Query private var transactions: [Transaction]
    
    @State private var selectedMonth = Date()
    @State private var showingEditBudget = false
    
    private var expenseCategories: [Category] {
        let filtered = categoryManager.categories.filter { $0.transactionType == .expense }
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
    
    private var currentMonthBudget: MonthlyBudget? {
        let calendar = Calendar.current
        return monthlyBudgets.first { budget in
            calendar.isDate(budget.month, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var totalBudget: Double {
        currentMonthBudget?.totalBudget ?? 0
    }
    
    private var totalSpent: Double {
        currentMonthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var remainingBudget: Double {
        totalBudget - totalSpent
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Month Navigation
                    monthNavigationSection
                    
                    // Budget Chart Section
                    budgetChartSection
                    
                    // Spending Categories
                    spendingCategoriesSection
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingEditBudget) {
                EditBudgetView(month: selectedMonth, expenseCategories: expenseCategories)
            }
        }
    }
    
    private var monthNavigationSection: some View {
        HStack(spacing: 16) {
            Button(action: {
                changeMonth(-1)
            }) {
                Image(systemName: "chevron.left")
                    .font(.body)
                    .foregroundColor(Color(hex: "023047") ?? .blue)
            }
            
            Text(monthYearString)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            Button(action: {
                changeMonth(1)
            }) {
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(Color(hex: "023047") ?? .blue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 50)
        .padding(.bottom, 20)
    }
    
    private var budgetChartSection: some View {
        VStack(spacing: 16) {
            // Edit Budget Button
            HStack {
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                
                Button(action: {
                    showingEditBudget = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                        Text("Edit Budget")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color(hex: "023047") ?? .blue)
                }
            }
            
            if totalBudget > 0 {
                BudgetChartView(totalBudget: totalBudget, spentAmount: totalSpent)
            } else {
                // No budget set placeholder
                VStack(spacing: 16) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No Budget Set")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text("Tap 'Edit Budget' to set your monthly budget")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
    
    private var spendingCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(expenseCategories, id: \.name) { category in
                CategoryBudgetSectionView(
                    category: category,
                    month: selectedMonth,
                    transactions: currentMonthTransactions
                )
            }
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private func changeMonth(_ direction: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: direction, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct CategoryBudgetSectionView: View {
    let category: Category
    let month: Date
    let transactions: [Transaction]
    
    @Query private var categoryBudgets: [CategoryBudget]
    
    private var categoryBudget: CategoryBudget? {
        let calendar = Calendar.current
        return categoryBudgets.first { budget in
            calendar.isDate(budget.month, equalTo: month, toGranularity: .month) &&
            budget.category?.name == category.name
        }
    }
    
    private var allocatedAmount: Double {
        categoryBudget?.allocatedAmount ?? 0
    }
    
    private var categoryTransactions: [Transaction] {
        transactions.filter { 
            $0.category?.name == category.name && $0.type == .expense 
        }
    }
    
    private var spentAmount: Double {
        categoryTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private var remainingAmount: Double {
        allocatedAmount - spentAmount
    }
    
    private var usagePercentage: Double {
        guard allocatedAmount > 0 else { return 0 }
        return min(100, (spentAmount / allocatedAmount) * 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category header
            HStack {
                CategoryIconView(category: category, size: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if allocatedAmount > 0 {
                        HStack(spacing: 4) {
                            Text("\(formatCurrency(spentAmount)) of \(formatCurrency(allocatedAmount))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• \(Int(usagePercentage))%")
                                .font(.caption)
                                .foregroundColor(usagePercentage > 100 ? .red : .secondary)
                        }
                    }
                }
                
                Spacer()
                
                if allocatedAmount > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatCurrency(remainingAmount))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(remainingAmount < 0 ? .red : .green)
                        
                        Text("remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Not budgeted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            // Progress bar
            if allocatedAmount > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(usagePercentage > 100 ? Color.red : Color.orange)
                                .frame(width: geometry.size.width * CGFloat(usagePercentage / 100), height: 6)
                                .cornerRadius(3)
                        }
                    }
                    .frame(height: 6)
                }
            }
            
            // Transactions list
            if !categoryTransactions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(categoryTransactions, id: \.id) { transaction in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(transaction.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(formatDate(transaction.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("-\(formatCurrency(transaction.amount))")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else if allocatedAmount > 0 {
                HStack {
                    Text("No spending yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: [Transaction.self, Category.self, MonthlyBudget.self, CategoryBudget.self, RecurringSubscription.self], inMemory: true)
} 