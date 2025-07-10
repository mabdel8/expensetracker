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
    @State private var budgetAmounts: [String: Double] = [:]
    @State private var incomeItems: [IncomeItem] = []
    @State private var customBudgetItems: [CategoryGroup: [BudgetItem]] = [:]
    @State private var showingAddItemForGroup: CategoryGroup? = nil
    @State private var newItemName: String = ""
    @State private var newItemAmount: String = ""
    
    private var expenseCategories: [Category] {
        allCategories.filter { $0.transactionType == .expense }
    }
    
    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var currentMonthIncomeTransactions: [Transaction] {
        currentMonthTransactions.filter { $0.type == .income }
    }
    
    private var totalSpent: Double {
        currentMonthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalBudgeted: Double {
        let categoryBudgets = budgetAmounts.values.reduce(0, +)
        let customBudgets = customBudgetItems.values.flatMap { $0 }.reduce(0) { $0 + $1.amount }
        let expenseTransactionsBudgets = currentMonthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return categoryBudgets + customBudgets + expenseTransactionsBudgets
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
        }
        .onAppear {
            loadBudgetData()
        }
        .onChange(of: transactions) { _, _ in
            // Recalculate total income when transactions change
            let manualIncomeTotal = incomeItems.reduce(0) { $0 + $1.amount }
            let transactionIncomeTotal = currentMonthIncomeTransactions.reduce(0) { $0 + $1.amount }
            totalIncome = manualIncomeTotal + transactionIncomeTotal
            
            // Note: totalBudgeted is a computed property that will automatically update
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
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                
                                                 // Display income transactions from the blue plus button
                ForEach(currentMonthIncomeTransactions, id: \.id) { transaction in
                    HStack {
                        Text(transaction.name)
                            .font(.body)
                        Spacer()
                        Text(formatCurrency(transaction.amount))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
                
                // Display manual income items
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
                 
                                 if !incomeItems.isEmpty || !currentMonthIncomeTransactions.isEmpty {
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
                

            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
    
    private var spendingCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Group categories by type
            let groupedCategories = Dictionary(grouping: expenseCategories) { category in
                getCategoryGroup(category.name)
            }
            
            ForEach(CategoryGroup.allCases, id: \.self) { group in
                if let categories = groupedCategories[group], !categories.isEmpty {
                    let filteredCategories = categories.filter { $0.name != group.rawValue }
                    
                    CategoryGroupView(
                        group: group,
                        categories: filteredCategories,
                        budgetAmounts: $budgetAmounts,
                        customBudgetItems: customBudgetItems[group] ?? [],
                        currentTransactions: currentMonthTransactions,
                        expenseTransactionsForGroup: getExpenseTransactionsForGroup(group),
                        showingAddItemForGroup: $showingAddItemForGroup,
                        newItemName: $newItemName,
                        newItemAmount: $newItemAmount,
                        onSaveItem: { saveItemForGroup(group) },
                        onCancelItem: { cancelAddItemForGroup() }
                    )
                }
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
    
    private func getExpenseTransactionsForGroup(_ group: CategoryGroup) -> [Transaction] {
        return currentMonthTransactions.filter { transaction in
            if transaction.type == .expense, let category = transaction.category {
                return getCategoryGroup(category.name) == group
            }
            return false
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
        
        // Calculate total income from both manual items and transactions
        let manualIncomeTotal = incomeItems.reduce(0) { $0 + $1.amount }
        let transactionIncomeTotal = currentMonthIncomeTransactions.reduce(0) { $0 + $1.amount }
        totalIncome = manualIncomeTotal + transactionIncomeTotal
    }
    

    
    private func deleteIncomeItem(at offsets: IndexSet) {
        incomeItems.remove(atOffsets: offsets)
        
        // Update total income (includes both manual items and transactions)
        let manualIncomeTotal = incomeItems.reduce(0) { $0 + $1.amount }
        let transactionIncomeTotal = currentMonthIncomeTransactions.reduce(0) { $0 + $1.amount }
        totalIncome = manualIncomeTotal + transactionIncomeTotal
    }
    

    
    private func saveItemForGroup(_ group: CategoryGroup) {
        guard let amount = Double(newItemAmount), amount > 0 else { return }
        
        // Create a new budget item
        let budgetItem = BudgetItem(name: newItemName, amount: amount)
        
        // Add to custom budget items for this group
        if customBudgetItems[group] == nil {
            customBudgetItems[group] = []
        }
        customBudgetItems[group]?.append(budgetItem)
        
        // Reset the form
        newItemName = ""
        newItemAmount = ""
        showingAddItemForGroup = nil
    }
    
    private func cancelAddItemForGroup() {
        newItemName = ""
        newItemAmount = ""
        showingAddItemForGroup = nil
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
    let customBudgetItems: [BudgetItem]
    let currentTransactions: [Transaction]
    let expenseTransactionsForGroup: [Transaction]
    @Binding var showingAddItemForGroup: CategoryGroup?
    @Binding var newItemName: String
    @Binding var newItemAmount: String
    let onSaveItem: () -> Void
    let onCancelItem: () -> Void
    
    private var groupTotal: Double {
        let categoryTotal = categories.filter { $0.name != group.rawValue }.reduce(0) { total, category in
            total + (budgetAmounts[category.name] ?? 0)
        }
        let customItemsTotal = customBudgetItems.reduce(0) { $0 + $1.amount }
        let expenseTransactionsTotal = expenseTransactionsForGroup.reduce(0) { $0 + $1.amount }
        return categoryTotal + customItemsTotal + expenseTransactionsTotal
    }
    
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
            
            ForEach(categories.filter { $0.name != group.rawValue }, id: \.name) { category in
                BudgetCategoryRow(
                    category: category,
                    budgetAmount: budgetAmounts[category.name] ?? 0,
                    spentAmount: getSpentAmount(for: category),
                    onBudgetChange: { amount in
                        budgetAmounts[category.name] = amount
                    }
                )
            }
            
            // Display expense transactions from the blue plus button
            ForEach(expenseTransactionsForGroup, id: \.id) { transaction in
                HStack {
                    Text(transaction.name)
                        .font(.body)
                    
                    Spacer()
                    
                    Text(formatCurrency(transaction.amount))
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
            
            // Display custom budget items
            ForEach(customBudgetItems, id: \.id) { item in
                CustomBudgetItemRow(item: item)
            }
            
            // Show total for this group if there are budgeted items
            if groupTotal > 0 {
                Divider()
                
                HStack {
                    Text("Total \(group.title)")
                        .font(.body)
                        .fontWeight(.bold)
                    Spacer()
                    Text(formatCurrency(groupTotal))
                        .font(.body)
                        .fontWeight(.bold)
                }
            }
            
            // Inline input row when adding item
            if showingAddItemForGroup == group {
                HStack {
                    TextField("Item Name", text: $newItemName)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    Spacer()
                    
                    TextField("$0.00", text: $newItemAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(PlainTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                .padding(.vertical, 8)
            }
            
            // Add Item button row
            HStack {
                Button(action: { 
                    if showingAddItemForGroup == group {
                        onCancelItem()
                    } else {
                        showingAddItemForGroup = group
                    }
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Item")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                if showingAddItemForGroup == group {
                    Button("Done") {
                        onSaveItem()
                    }
                    .disabled(newItemName.isEmpty || newItemAmount.isEmpty)
                    .foregroundColor(.blue)
                }
            }
        }
                    .padding()
            .background(Color.white)
            .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
            .padding(.bottom, 8)
    }
    
    private func getSpentAmount(for category: Category) -> Double {
        return currentTransactions
            .filter { $0.category?.name == category.name && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
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

struct CustomBudgetItemRow: View {
    let item: BudgetItem
    
    var body: some View {
        HStack {
            Text(item.name)
                .font(.body)
            
            Spacer()
            
            Text(formatCurrency(item.amount))
                .font(.body)
                .fontWeight(.medium)
        }
        .contentShape(Rectangle())
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

struct BudgetItem: Identifiable {
    let id = UUID()
    var name: String
    var amount: Double
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