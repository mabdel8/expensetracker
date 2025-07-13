//
//  EditBudgetView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct EditBudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let month: Date
    let expenseCategories: [Category]
    
    @State private var totalBudget: String = ""
    @State private var categoryAllocations: [String: String] = [:]
    @State private var existingMonthlyBudget: MonthlyBudget?
    
    @Query private var monthlyBudgets: [MonthlyBudget]
    @Query private var categoryBudgets: [CategoryBudget]
    
    private var totalBudgetValue: Double {
        Double(totalBudget) ?? 0
    }
    
    private var totalAllocated: Double {
        categoryAllocations.values.compactMap { Double($0) }.reduce(0, +)
    }
    
    private var remainingBudget: Double {
        totalBudgetValue - totalAllocated
    }
    
    private var canSave: Bool {
        totalBudgetValue > 0 && remainingBudget >= 0
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Edit Budget")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "023047") ?? .blue)
                    
                    Text(monthYearString)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Total Budget Section
                        totalBudgetSection
                        
                        // Budget Allocation Section
                        budgetAllocationSection
                        
                        // Save and Cancel Buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Cancel")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                saveBudget()
                            }) {
                                Text("Save Budget")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(canSave ? Color(hex: "023047") ?? .blue : Color.gray)
                                    .cornerRadius(8)
                            }
                            .disabled(!canSave)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadExistingBudget()
            }
        }
    }
    
    private var totalBudgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total Monthly Budget")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("$")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", text: $totalBudget)
                        .font(.title2)
                        .fontWeight(.medium)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Budget Summary
                if totalBudgetValue > 0 {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Total Budget:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(totalBudgetValue))
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Allocated:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(totalAllocated))
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        
                        HStack {
                            Text("Remaining:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(remainingBudget))
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(remainingBudget < 0 ? .red : .green)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    private var budgetAllocationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Allocation")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(expenseCategories, id: \.name) { category in
                    CategoryAllocationRow(
                        category: category,
                        allocation: Binding(
                            get: { categoryAllocations[category.name] ?? "" },
                            set: { categoryAllocations[category.name] = $0 }
                        )
                    )
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
    
    private func loadExistingBudget() {
        let calendar = Calendar.current
        
        // Find existing monthly budget
        existingMonthlyBudget = monthlyBudgets.first { budget in
            calendar.isDate(budget.month, equalTo: month, toGranularity: .month)
        }
        
        if let budget = existingMonthlyBudget {
            totalBudget = String(format: "%.0f", budget.totalBudget)
            
            // Load existing category allocations
            for category in expenseCategories {
                let allocation = categoryBudgets.first { categoryBudget in
                    calendar.isDate(categoryBudget.month, equalTo: month, toGranularity: .month) &&
                    categoryBudget.category?.name == category.name
                }
                
                if let allocation = allocation {
                    categoryAllocations[category.name] = String(format: "%.0f", allocation.allocatedAmount)
                }
            }
        }
    }
    
    private func saveBudget() {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: month)?.start ?? month
        
        // Create or update monthly budget
        let monthlyBudget: MonthlyBudget
        if let existing = existingMonthlyBudget {
            existing.totalBudget = totalBudgetValue
            monthlyBudget = existing
        } else {
            monthlyBudget = MonthlyBudget(totalBudget: totalBudgetValue, month: monthStart)
            modelContext.insert(monthlyBudget)
        }
        
        // Delete existing category budgets for this month
        let existingCategoryBudgets = categoryBudgets.filter { categoryBudget in
            calendar.isDate(categoryBudget.month, equalTo: month, toGranularity: .month)
        }
        
        for budget in existingCategoryBudgets {
            modelContext.delete(budget)
        }
        
        // Create new category budgets
        for category in expenseCategories {
            if let allocationString = categoryAllocations[category.name],
               let allocation = Double(allocationString),
               allocation > 0 {
                let categoryBudget = CategoryBudget(
                    allocatedAmount: allocation,
                    month: monthStart,
                    category: category
                )
                categoryBudget.monthlyBudget = monthlyBudget
                modelContext.insert(categoryBudget)
            }
        }
        
        // Save context
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save budget: \(error)")
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct CategoryAllocationRow: View {
    let category: Category
    @Binding var allocation: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon and name
            HStack(spacing: 8) {
                CategoryIconView(category: category, size: 20)
                
                Text(category.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Allocation input
            HStack {
                Text("$")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                TextField("0", text: $allocation)
                    .font(.body)
                    .fontWeight(.medium)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct EditBudgetView_Previews: PreviewProvider {
    static var previews: some View {
        EditBudgetView(month: Date(), expenseCategories: [])
    }
} 