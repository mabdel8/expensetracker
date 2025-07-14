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
    @State private var subcategoryAllocations: [String: [String: String]] = [:]
    @State private var customSubcategories: [String: [String]] = [:]
    @State private var isAutoCalculateEnabled = false
    @State private var existingMonthlyBudget: MonthlyBudget?
    
    @Query private var monthlyBudgets: [MonthlyBudget]
    @Query private var categoryBudgets: [CategoryBudget]
    
    private var totalBudgetValue: Double {
        Double(totalBudget) ?? 0
    }
    
    private var totalAllocated: Double {
        if isAutoCalculateEnabled {
            // Calculate from subcategories
            return expenseCategories.reduce(0) { total, category in
                total + calculateCategoryTotalFromSubcategories(category.name)
            }
        } else {
            // Use manual category allocations
            return categoryAllocations.values.compactMap { Double($0) }.reduce(0, +)
        }
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
                        .fontWeight(.light)
                        .foregroundColor(Color(hex: "023047") ?? .blue)
                    
                    Text(monthYearString)
                        .font(.headline)
                        .fontWeight(.light)
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
                    .padding(.top, 18)
                    .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
            .onAppear {
                loadExistingBudget()
                initializeSubcategories()
            }
        }
    }
    
    private var totalBudgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total Monthly Budget")
                .font(.title3)
                .fontWeight(.light)
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
                                .fontWeight(.light)
                        }
                        
                        HStack {
                            Text("Allocated:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(totalAllocated))
                                .font(.body)
                                .fontWeight(.light)
                                .foregroundColor(.orange)
                        }
                        
                        HStack {
                            Text("Remaining:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(remainingBudget))
                                .font(.body)
                                .fontWeight(.light)
                                .foregroundColor(remainingBudget < 0 ? .red : .green)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                
                // Auto-calculate toggle
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    Toggle(isOn: $isAutoCalculateEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto-Calculate from Subcategories")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(isAutoCalculateEnabled ? "Fill in subcategories and we'll calculate category totals for you" : "Manually set amounts for each category")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "023047") ?? .blue))
                }
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    private var budgetAllocationSection: some View {
        VStack(spacing: 16) {
            ForEach(expenseCategories, id: \.name) { category in
                CategoryAllocationCard(
                    category: category,
                    isAutoCalculateEnabled: isAutoCalculateEnabled,
                    categoryAllocation: Binding(
                        get: { categoryAllocations[category.name] ?? "" },
                        set: { categoryAllocations[category.name] = $0 }
                    ),
                    subcategoryAllocations: Binding(
                        get: { subcategoryAllocations[category.name] ?? [:] },
                        set: { subcategoryAllocations[category.name] = $0 }
                    ),
                    customSubcategories: Binding(
                        get: { customSubcategories[category.name] ?? [] },
                        set: { customSubcategories[category.name] = $0 }
                    ),
                    calculatedTotal: calculateCategoryTotalFromSubcategories(category.name)
                )
            }
        }
    }
    
    private func initializeSubcategories() {
        for category in expenseCategories {
            if subcategoryAllocations[category.name] == nil {
                subcategoryAllocations[category.name] = [:]
            }
            if customSubcategories[category.name] == nil {
                customSubcategories[category.name] = []
            }
        }
    }
    
    private func calculateCategoryTotalFromSubcategories(_ categoryName: String) -> Double {
        guard let subcategories = subcategoryAllocations[categoryName] else { return 0 }
        return subcategories.values.compactMap { Double($0) }.reduce(0, +)
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
            let allocation: Double
            
            if isAutoCalculateEnabled {
                allocation = calculateCategoryTotalFromSubcategories(category.name)
            } else {
                allocation = Double(categoryAllocations[category.name] ?? "") ?? 0
            }
            
            if allocation > 0 {
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
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct CategoryAllocationCard: View {
    let category: Category
    let isAutoCalculateEnabled: Bool
    @Binding var categoryAllocation: String
    @Binding var subcategoryAllocations: [String: String]
    @Binding var customSubcategories: [String]
    let calculatedTotal: Double
    
    @State private var isExpanded = true
    @State private var newSubcategoryName = ""
    @State private var showingAddSubcategory = false
    
    private var defaultSubcategories: [String] {
        DefaultCategories.defaultSubcategories[category.name] ?? []
    }
    
    private var allSubcategories: [String] {
        defaultSubcategories + customSubcategories
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category Header
            HStack(spacing: 12) {
                CategoryIconView(category: category, size: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if isAutoCalculateEnabled && calculatedTotal > 0 {
                        Text("Calculated: \(formatCurrency(calculatedTotal))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !isAutoCalculateEnabled {
                    // Manual allocation input
                    HStack {
                        Text("$")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        TextField("0", text: $categoryAllocation)
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
                } else {
                    // Show calculated total
                    Text(formatCurrency(calculatedTotal))
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                // Expand/Collapse button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Subcategories (expanded view)
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(allSubcategories.enumerated()), id: \.element) { index, subcategory in
                        VStack(spacing: 0) {
                            SubcategoryRow(
                                subcategoryName: subcategory,
                                allocation: Binding(
                                    get: { subcategoryAllocations[subcategory] ?? "" },
                                    set: { subcategoryAllocations[subcategory] = $0 }
                                ),
                                isCustom: customSubcategories.contains(subcategory),
                                onDelete: {
                                    if let index = customSubcategories.firstIndex(of: subcategory) {
                                        customSubcategories.remove(at: index)
                                        subcategoryAllocations.removeValue(forKey: subcategory)
                                    }
                                }
                            )
                            
                            // Add divider between subcategories (except for last one)
                            if index < allSubcategories.count - 1 {
                                Divider()
                                    .padding(.leading, 32)
                            }
                        }
                    }
                    
                    // Add custom subcategory button
                    if !allSubcategories.isEmpty {
                        Divider()
                            .padding(.leading, 32)
                    }
                    
                    Button(action: {
                        showingAddSubcategory = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(hex: "023047") ?? .blue)
                            Text("Add Custom Subcategory")
                                .font(.caption)
                                .foregroundColor(Color(hex: "023047") ?? .blue)
                        }
                        .padding(.vertical, 8)
                        .padding(.leading, 32)
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .alert("Add Subcategory", isPresented: $showingAddSubcategory) {
            TextField("Subcategory name", text: $newSubcategoryName)
            Button("Add") {
                if !newSubcategoryName.isEmpty && !allSubcategories.contains(newSubcategoryName) {
                    customSubcategories.append(newSubcategoryName)
                    newSubcategoryName = ""
                }
            }
            Button("Cancel", role: .cancel) {
                newSubcategoryName = ""
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SubcategoryRow: View {
    let subcategoryName: String
    @Binding var allocation: String
    let isCustom: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(subcategoryName)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack {
                Text("$")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0", text: $allocation)
                    .font(.caption)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
                    .frame(width: 40)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.white)
            .cornerRadius(6)
            
            if isCustom {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, 20)
        .padding(.trailing, 20)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct EditBudgetView_Previews: PreviewProvider {
    static var previews: some View {
        EditBudgetView(month: Date(), expenseCategories: [])
    }
} 
