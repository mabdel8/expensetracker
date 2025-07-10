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
    @Query private var transactions: [Transaction]
    
    @State private var selectedMonth = Date()
    @State private var totalIncome: Double = 0
    @State private var showingAddIncome = false
    @State private var showingAddCategory = false
    @State private var budgetAmounts: [String: Double] = [:]
    @State private var incomeItems: [IncomeItem] = []
    
    private var expenseCategories: [Category] {
        allCategories.filter { $0.transactionType == .expense }
    }
    
    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var totalSpent: Double {
        currentMonthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalBudgeted: Double {
        budgetAmounts.values.reduce(0, +)
    }
    
    private var remainingToBudget: Double {
        totalIncome - totalBudgeted
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Month Navigation
                    monthNavigationSection
                    
                    // Budget Summary
                    budgetSummarySection
                    
                    // Income Section
                    incomeSection
                    
                    // Spending Categories
                    spendingCategoriesSection
                    
                    Spacer(minLength: 100)
                }
            }
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudgets()
                    }
                }
            }
        }
        .onAppear {
            loadBudgetData()
        }
        .sheet(isPresented: $showingAddIncome) {
            AddIncomeView(incomeItems: $incomeItems, totalIncome: $totalIncome)
        }
    }
    
    private var monthNavigationSection: some View {
        HStack {
            Button(action: { changeMonth(-1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: { changeMonth(1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
    }
    
    private var budgetSummarySection: some View {
        VStack(spacing: 12) {
            Text(formatCurrency(remainingToBudget))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(remainingToBudget >= 0 ? .green : .red)
            
            Text("left to budget")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
    }
    
    private var incomeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Income")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Text("Planned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                                 // Display individual income items
                 ForEach(incomeItems, id: \.id) { item in
                     HStack {
                         Text(item.name)
                             .font(.body)
                         Spacer()
                         Text(formatCurrency(item.amount))
                             .font(.body)
                             .fontWeight(.medium)
                     }
                 }
                 .onDelete(perform: deleteIncomeItem)
                 
                 if !incomeItems.isEmpty {
                     Divider()
                     
                     HStack {
                         Text("Total Income")
                             .font(.body)
                             .fontWeight(.bold)
                         Spacer()
                         Text(formatCurrency(totalIncome))
                             .font(.body)
                             .fontWeight(.bold)
                     }
                 }
                
                Button(action: { showingAddIncome = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Income")
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    private var spendingCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Group categories by type
            let groupedCategories = Dictionary(grouping: expenseCategories) { category in
                getCategoryGroup(category.name)
            }
            
            ForEach(CategoryGroup.allCases, id: \.self) { group in
                if let categories = groupedCategories[group], !categories.isEmpty {
                    CategoryGroupView(
                        group: group,
                        categories: categories,
                        budgetAmounts: $budgetAmounts,
                        currentTransactions: currentMonthTransactions
                    )
                }
            }
            
            // Add Category Button
            Button(action: { showingAddCategory = true }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Category")
                }
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal)
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
            loadBudgetData()
        }
    }
    
    private func getCategoryGroup(_ categoryName: String) -> CategoryGroup {
        switch categoryName.lowercased() {
        case let name where name.contains("food") || name.contains("dining"):
            return .food
        case let name where name.contains("transport") || name.contains("car") || name.contains("gas"):
            return .transportation
        case let name where name.contains("bill") || name.contains("utilit"):
            return .bills
        case let name where name.contains("entertain") || name.contains("fun"):
            return .entertainment
        case let name where name.contains("health") || name.contains("medical"):
            return .health
        case let name where name.contains("shop"):
            return .shopping
        case let name where name.contains("giving") || name.contains("charity") || name.contains("church"):
            return .giving
        default:
            return .other
        }
    }
    
    private func loadBudgetData() {
        // Load existing budgets for the current month
        let calendar = Calendar.current
        let activeBudgets = budgets.filter { budget in
            calendar.isDate(budget.startDate, equalTo: selectedMonth, toGranularity: .month)
        }
        
        budgetAmounts = [:]
        for budget in activeBudgets {
            if let categoryName = budget.category?.name {
                budgetAmounts[categoryName] = budget.amount
            }
        }
        
        // Load income items (in a real app, this would be from persistent storage)
        // For now, we'll keep the existing income items
        totalIncome = incomeItems.reduce(0) { $0 + $1.amount }
    }
    
    private func saveBudgets() {
        // Implementation for saving budgets
        // This would create/update Budget objects in the model context
        print("Saving budgets...")
    }
    
    private func deleteIncomeItem(at offsets: IndexSet) {
        incomeItems.remove(atOffsets: offsets)
        totalIncome = incomeItems.reduce(0) { $0 + $1.amount }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}



struct CategoryGroupView: View {
    let group: CategoryGroup
    let categories: [Category]
    @Binding var budgetAmounts: [String: Double]
    let currentTransactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(group.title)
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("Planned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ForEach(categories, id: \.name) { category in
                BudgetCategoryRow(
                    category: category,
                    budgetAmount: budgetAmounts[category.name] ?? 0,
                    spentAmount: getSpentAmount(for: category),
                    onBudgetChange: { amount in
                        budgetAmounts[category.name] = amount
                    }
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func getSpentAmount(for category: Category) -> Double {
        return currentTransactions
            .filter { $0.category?.name == category.name && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
}

struct BudgetCategoryRow: View {
    let category: Category
    let budgetAmount: Double
    let spentAmount: Double
    let onBudgetChange: (Double) -> Void
    
    @State private var budgetText: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: category.iconName)
                .foregroundColor(category.color)
                .frame(width: 24, height: 24)
            
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            if isEditing {
                TextField("$0", text: $budgetText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .onSubmit {
                        if let amount = Double(budgetText) {
                            onBudgetChange(amount)
                        }
                        isEditing = false
                    }
            } else {
                Text(formatCurrency(budgetAmount))
                    .font(.body)
                    .fontWeight(.medium)
                    .onTapGesture {
                        budgetText = budgetAmount > 0 ? String(format: "%.0f", budgetAmount) : ""
                        isEditing = true
                    }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                budgetText = budgetAmount > 0 ? String(format: "%.0f", budgetAmount) : ""
                isEditing = true
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

struct IncomeItem: Identifiable {
    let id = UUID()
    var name: String
    var amount: Double
}

struct AddIncomeView: View {
    @Binding var incomeItems: [IncomeItem]
    @Binding var totalIncome: Double
    @Environment(\.dismiss) private var dismiss
    
    @State private var incomeName: String = ""
    @State private var incomeAmount: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Income Details")) {
                    TextField("Income name (e.g., Salary, Freelance)", text: $incomeName)
                    
                    TextField("Amount", text: $incomeAmount)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveIncome()
                    }
                    .disabled(incomeName.isEmpty || incomeAmount.isEmpty)
                }
            }
        }
    }
    
    private func saveIncome() {
        guard let amount = Double(incomeAmount), amount > 0 else { return }
        
        let newItem = IncomeItem(name: incomeName, amount: amount)
        incomeItems.append(newItem)
        
        // Update total income
        totalIncome = incomeItems.reduce(0) { $0 + $1.amount }
        
        dismiss()
    }
}

enum CategoryGroup: String, CaseIterable {
    case food = "Food & Dining"
    case transportation = "Transportation"
    case bills = "Bills & Utilities"
    case entertainment = "Entertainment"
    case health = "Health & Medical"
    case shopping = "Shopping"
    case giving = "Giving"
    case other = "Other"
    
    var title: String {
        return self.rawValue
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: [Transaction.self, Category.self, Budget.self], inMemory: true)
}

#Preview("Add Income") {
    AddIncomeView(incomeItems: .constant([]), totalIncome: .constant(0))
} 