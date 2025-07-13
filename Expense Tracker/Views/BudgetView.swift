//
//  BudgetView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData
import Foundation

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
    
    private var canAddIncomeItem: Bool {
        // Allow adding the first item, or if all existing items are properly filled out
        incomeItems.isEmpty || incomeItems.allSatisfy { 
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.amount > 0 
        }
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
            .navigationBarHidden(true)
        }
        .onAppear {
            loadBudgetData()
        }
        .onChange(of: transactions) { _, _ in
            // Recalculate total income when transactions change
            updateTotalIncome()
            
            // Note: totalBudgeted is a computed property that will automatically update
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
    
    private var budgetSummarySection: some View {
        VStack(spacing: 20) {
            HStack {
                Text(monthYearString)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Main budget overview
            VStack(spacing: 16) {
                Text(formatCurrency(totalIncome))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Total Income")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Income vs Spent breakdown
            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 12, height: 12)
                        Text("Spent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(formatCurrency(totalSpent))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.teal)
                            .frame(width: 12, height: 12)
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(formatCurrency(remainingToBudget))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.teal)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
    
    private var incomeSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "banknote")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.green)
                    Text("Income")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Spacer()
                Button(action: {
                    addIncomeItem()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Income")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(canAddIncomeItem ? Color.green : Color.gray)
                    .cornerRadius(20)
                }
                .disabled(!canAddIncomeItem)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            VStack(spacing: 0) {
                // Display income from transactions (blue plus button)
                ForEach(currentMonthIncomeTransactions, id: \.id) { transaction in
                    HStack(spacing: 16) {
                        Text(transaction.name)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("+\(formatCurrency(transaction.amount))")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    
                    if transaction.id != currentMonthIncomeTransactions.last?.id || !incomeItems.isEmpty {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
                
                // Display manual income items (budget planning)
                ForEach(incomeItems.indices, id: \.self) { index in
                    IncomeItemRow(
                        item: incomeItems[index],
                        onNameChange: { newName in
                            incomeItems[index].name = newName
                        },
                        onAmountChange: { newAmount in
                            incomeItems[index].amount = newAmount
                            updateTotalIncome()
                        }
                    )
                    
                    if index != incomeItems.count - 1 {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
                .onDelete(perform: deleteIncomeItem)
                
                // Empty state when no income
                if incomeItems.isEmpty && currentMonthIncomeTransactions.isEmpty {
                    VStack(spacing: 12) {
                        Text("No Income Added")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Tap 'Add Income' to start planning your budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }
    
    private var spendingCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Group categories by type
            let groupedCategories = Dictionary(grouping: expenseCategories) { category in
                getCategoryGroup(category.name)
            }
            
            ForEach(CategoryGroup.allCases, id: \.self) { group in
                let categories = groupedCategories[group] ?? []
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
                    onCancelItem: { cancelAddItemForGroup() },
                    onCustomItemAmountChange: { itemId, newAmount in
                        updateCustomItemAmount(group: group, itemId: itemId, newAmount: newAmount)
                    }
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
            loadBudgetData()
        }
    }
    
    private func getCategoryGroup(_ categoryName: String) -> CategoryGroup {
        switch categoryName.lowercased() {
        case let name where name.contains("health") || name.contains("medical") || name.contains("doctor") || name.contains("hospital") || name.contains("pharmacy") || name.contains("medicine") || name.contains("dental") || name.contains("gym") || name.contains("fitness"):
            return .health
        case let name where name.contains("personal") || name.contains("care") || name.contains("beauty") || name.contains("haircut") || name.contains("salon"):
            return .other
        case let name where name.contains("food") || name.contains("dining") || name.contains("restaurant") || name.contains("grocery"):
            return .food
        case let name where name.contains("transport") || name.contains("car") || name.contains("vehicle") || name.contains("fuel") || name.contains("parking") || name.contains("uber") || name.contains("taxi"):
            return .transportation
        case let name where name.contains("bill") || name.contains("utilit") || name.contains("electric") || name.contains("water") || name.contains("rent") || name.contains("mortgage"):
            return .bills
        case let name where name.contains("entertain") || name.contains("fun") || name.contains("movie") || name.contains("game") || name.contains("streaming"):
            return .entertainment
        case let name where name.contains("shop") || name.contains("clothing") || name.contains("electronics"):
            return .shopping
        case let name where name.contains("giving") || name.contains("charity") || name.contains("church") || name.contains("donation"):
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
        
        // Load default budget items if customBudgetItems is empty
        if customBudgetItems.isEmpty {
            loadDefaultBudgetItems()
        }
        
        // Calculate total income from both manual items and transactions
        updateTotalIncome()
    }
    
    private func loadDefaultBudgetItems() {
        customBudgetItems = [
            .bills: [
                BudgetItem(name: "Mortgage/Rent", amount: 0),
                BudgetItem(name: "Water", amount: 0),
                BudgetItem(name: "Electricity", amount: 0),
                BudgetItem(name: "Gas", amount: 0),
                BudgetItem(name: "Cable", amount: 0),
                BudgetItem(name: "Trash", amount: 0)
            ],
            .food: [
                BudgetItem(name: "Groceries", amount: 0),
                BudgetItem(name: "Restaurants", amount: 0)
            ],
            .transportation: [
                BudgetItem(name: "Gas", amount: 0),
                BudgetItem(name: "Car Insurance", amount: 0),
                BudgetItem(name: "Car Payment", amount: 0),
                BudgetItem(name: "Parking", amount: 0)
            ],
            .entertainment: [
                BudgetItem(name: "Streaming Services", amount: 0),
                BudgetItem(name: "Movies", amount: 0),
                BudgetItem(name: "Concerts/Events", amount: 0),
                BudgetItem(name: "Gaming", amount: 0)
            ],
            .health: [
                BudgetItem(name: "Gym", amount: 0),
                BudgetItem(name: "Medicine/Vitamins", amount: 0),
                BudgetItem(name: "Doctor Visits", amount: 0)
            ],
            .shopping: [
                BudgetItem(name: "Clothing", amount: 0),
                BudgetItem(name: "Electronics", amount: 0),
                BudgetItem(name: "Home Goods", amount: 0)
            ],
            .giving: [
                BudgetItem(name: "Charity", amount: 0),
                BudgetItem(name: "Gifts", amount: 0),
                BudgetItem(name: "Church/Religious", amount: 0)
            ],
            .other: [
                BudgetItem(name: "Personal Care", amount: 0),
                BudgetItem(name: "Miscellaneous", amount: 0),
                BudgetItem(name: "Emergency Fund", amount: 0)
            ]
        ]
    }
    

    
    private func addIncomeItem() {
        let newItem = IncomeItem(name: "", amount: 0)
        incomeItems.append(newItem)
        updateTotalIncome()
    }
    
    private func updateTotalIncome() {
        let manualIncomeTotal = incomeItems.reduce(0) { $0 + $1.amount }
        let transactionIncomeTotal = currentMonthIncomeTransactions.reduce(0) { $0 + $1.amount }
        totalIncome = manualIncomeTotal + transactionIncomeTotal
    }
    
    private func deleteIncomeItem(at offsets: IndexSet) {
        incomeItems.remove(atOffsets: offsets)
        updateTotalIncome()
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
    
    private func updateCustomItemAmount(group: CategoryGroup, itemId: UUID, newAmount: Double) {
        if var items = customBudgetItems[group] {
            if let index = items.firstIndex(where: { $0.id == itemId }) {
                items[index].amount = newAmount
                customBudgetItems[group] = items
            }
        }
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
    let onCustomItemAmountChange: (UUID, Double) -> Void
    
    @FocusState private var isAmountFocused: Bool
    
    private var groupTotal: Double {
        let categoryTotal = categories.filter { $0.name != group.rawValue }.reduce(0) { total, category in
            total + (budgetAmounts[category.name] ?? 0)
        }
        let customItemsTotal = customBudgetItems.reduce(0) { $0 + $1.amount }
        let expenseTransactionsTotal = expenseTransactionsForGroup.reduce(0) { $0 + $1.amount }
        return categoryTotal + customItemsTotal + expenseTransactionsTotal
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(group.title)
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                if groupTotal > 0 {
                    Text(formatCurrency(groupTotal))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
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
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.name)
                            .font(.body)
                            .fontWeight(.medium)
                        Text(transaction.category?.name ?? "")
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
            
            // Display custom budget items
            ForEach(customBudgetItems, id: \.id) { item in
                CustomBudgetItemRow(item: item) { newAmount in
                    onCustomItemAmountChange(item.id, newAmount)
                }
            }
            

            
            // Add Item button row or inline input row
            if showingAddItemForGroup == group {
                // Inline input row when adding item (replaces the Add Item button)
                HStack {
                    TextField("Item Name", text: $newItemName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .submitLabel(.done)
                        .onSubmit {
                            // Move focus away from the text field when done is pressed
                        }
                    
                    Spacer()
                    
                    TextField("$0.00", text: $newItemAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(PlainTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .focused($isAmountFocused)
                }
                .padding(.vertical, 8)
                
                // Cancel and Done buttons
                HStack {
                    Button("Cancel") {
                        onCancelItem()
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Done") {
                        onSaveItem()
                    }
                    .disabled(newItemName.isEmpty || newItemAmount.isEmpty)
                    .foregroundColor(.blue)
                }
            } else {
                // Add Item button
                HStack {
                    Button(action: { 
                        showingAddItemForGroup = group
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Item")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
        }
                    .padding(20)
            .background(Color.white)
            .cornerRadius(16)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            .padding(.horizontal)
            .padding(.bottom, 16)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if isAmountFocused {
                        Spacer()
                        Button("Done") {
                            isAmountFocused = false
                        }
                    }
                }
            }
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
                    CategoryIconView(category: category, size: 20)
                    
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
    let onAmountChange: (Double) -> Void
    
    @State private var amountText: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        HStack {
            Text(item.name)
                .font(.body)
            
            Spacer()
            
            if isEditing {
                TextField("$0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .onSubmit {
                        if let amount = Double(amountText) {
                            onAmountChange(amount)
                        }
                        isEditing = false
                    }
            } else {
                Text(formatCurrency(item.amount))
                    .font(.body)
                    .fontWeight(.medium)
                    .onTapGesture {
                        amountText = item.amount > 0 ? String(format: "%.0f", item.amount) : ""
                        isEditing = true
                    }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                amountText = item.amount > 0 ? String(format: "%.0f", item.amount) : ""
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

struct IncomeItemRow: View {
    let item: IncomeItem
    let onNameChange: (String) -> Void
    let onAmountChange: (Double) -> Void
    
    @State private var nameText: String = ""
    @State private var amountText: String = ""
    @State private var isEditingName: Bool = false
    @State private var isEditingAmount: Bool = false
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            if isEditingName {
                TextField("Name", text: $nameText)
                    .submitLabel(.done)
                    .onSubmit {
                        onNameChange(nameText)
                        isEditingName = false
                    }
            } else {
                Text(item.name.isEmpty ? "Name" : item.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(item.name.isEmpty ? .secondary : .primary)
                    .onTapGesture {
                        nameText = item.name
                        isEditingName = true
                    }
            }
            
            Spacer()
            
            if isEditingAmount {
                TextField("0", text: $amountText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
                    .focused($isAmountFocused)
                    .onSubmit {
                        if let amount = Double(amountText) {
                            onAmountChange(amount)
                        }
                        isEditingAmount = false
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            if isAmountFocused {
                                Spacer()
                                Button("Done") {
                                    if let amount = Double(amountText) {
                                        onAmountChange(amount)
                                    }
                                    isEditingAmount = false
                                    isAmountFocused = false
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
            } else {
                Text(formatCurrency(item.amount))
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .onTapGesture {
                        amountText = item.amount > 0 ? String(format: "%.0f", item.amount) : ""
                        isEditingAmount = true
                        isAmountFocused = true
                    }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .onAppear {
            if item.name.isEmpty && !isEditingName {
                nameText = item.name
                isEditingName = true
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

struct BudgetItem: Identifiable {
    let id: UUID
    let name: String
    var amount: Double
    
    init(name: String, amount: Double) {
        self.id = UUID()
        self.name = name
        self.amount = amount
    }
}



enum CategoryGroup: String, CaseIterable {
    case bills = "Bills & Utilities"
    case food = "Food & Dining"
    case transportation = "Transportation"
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