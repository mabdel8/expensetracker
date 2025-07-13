//
//  BudgetView.swift
//  Expense Tracker
//
//  Created by Abdalla Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData
import Foundation

struct BudgetView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var allCategories: [Category]
    @Query private var transactions: [Transaction]
    @Query private var plannedIncomes: [PlannedIncome]
    @Query private var plannedExpenses: [PlannedExpense]
    
    @State private var selectedMonth = Date()
    @State private var totalIncome: Double = 0
    @State private var budgetAmounts: [String: Double] = [:]
    @State private var showingAddItemForGroup: String? = nil
    @State private var newItemName: String = ""
    @State private var newItemAmount: String = ""
    @State private var showingAddIncome: Bool = false
    @State private var newIncomeName: String = ""
    @State private var newIncomeAmount: String = ""
    @FocusState private var isIncomeAmountFocused: Bool
    @FocusState private var isIncomeNameFocused: Bool

    
    private var expenseCategories: [Category] {
        let filtered = allCategories.filter { $0.transactionType == .expense }
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
    
    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var currentMonthIncomeTransactions: [Transaction] {
        currentMonthTransactions.filter { $0.type == .income }
    }
    
    private var currentMonthPlannedIncomes: [PlannedIncome] {
        let calendar = Calendar.current
        return plannedIncomes.filter { plannedIncome in
            calendar.isDate(plannedIncome.month, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var currentMonthPlannedExpenses: [PlannedExpense] {
        let calendar = Calendar.current
        return plannedExpenses.filter { plannedExpense in
            calendar.isDate(plannedExpense.month, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var totalSpent: Double {
        currentMonthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalBudgeted: Double {
        let categoryBudgets = budgetAmounts.values.reduce(0, +)
        let plannedBudgets = currentMonthPlannedExpenses.reduce(0) { $0 + $1.amount }
        return categoryBudgets + plannedBudgets
    }
    
    private var remainingToBudget: Double {
        totalIncome - totalBudgeted
    }
    
    private var canAddIncomeItem: Bool {
        // Allow adding income when not currently showing the add form
        !showingAddIncome
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
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon, title, and total
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "banknote.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        )
                    Text("Income")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                if totalIncome > 0 {
                    Text(formatCurrency(totalIncome))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
                        // Display income from transactions (blue plus button)
            ForEach(currentMonthIncomeTransactions, id: \.id) { transaction in
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
                    
                    Text("+\(formatCurrency(transaction.amount))")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 4)
            }
            
            // Display manual income items (budget planning)
            ForEach(currentMonthPlannedIncomes, id: \.id) { plannedIncome in
                PlannedIncomeRow(
                    plannedIncome: plannedIncome,
                    onNameChange: { newName in
                        plannedIncome.name = newName
                        saveContext()
                    },
                    onAmountChange: { newAmount in
                        plannedIncome.amount = newAmount
                        saveContext()
                        updateTotalIncome()
                    }
                )
            }
            .onDelete(perform: deleteIncomeItem)

            // Add Income button or inline input
            if showingAddIncome {
                // Inline input row when adding income
                HStack {
                    TextField("Income Name", text: $newIncomeName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .submitLabel(.done)
                        .focused($isIncomeNameFocused)
                    
                    Spacer()
                    
                    TextField("$0.00", text: $newIncomeAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(PlainTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .focused($isIncomeAmountFocused)
                        .onSubmit {
                            isIncomeAmountFocused = false
                        }
                }
                .padding(.vertical, 8)
                
                // Cancel and Done buttons
                HStack {
                    Button("Cancel") {
                        cancelAddIncome()
                    }
                    .foregroundColor(.red)
                    
                    Spacer()
                    
                    Button("Done") {
                        saveIncomeItem()
                    }
                    .disabled(newIncomeName.isEmpty || newIncomeAmount.isEmpty)
                    .foregroundColor(Color(hex: "023047") ?? .blue)
                }
            } else {
                // Add Income button
                HStack {
                    Button(action: {
                        showingAddIncome = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isIncomeNameFocused = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Income")
                        }
                        .foregroundColor(Color(hex: "023047") ?? .blue)
                    }
                    .disabled(!canAddIncomeItem)
                    
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
                if isIncomeAmountFocused {
                    Spacer()
                    Button("Done") {
                        isIncomeAmountFocused = false
                    }
                    .foregroundColor(Color(hex: "023047") ?? .blue)
                }
            }
        }
    }
    
    private var spendingCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(expenseCategories, id: \.name) { category in
                CategorySectionView(
                    category: category,
                    budgetAmounts: $budgetAmounts,
                    currentTransactions: currentMonthTransactions,
                    plannedExpenses: currentMonthPlannedExpenses.filter { $0.category?.name == category.name },
                    showingAddItemForCategory: $showingAddItemForGroup,
                    newItemName: $newItemName,
                    newItemAmount: $newItemAmount,
                    onSaveItem: { saveItemForCategory(category) },
                    onCancelItem: { cancelAddItemForGroup() }
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
    
    private func getExpenseTransactionsForCategory(_ category: Category) -> [Transaction] {
        return currentMonthTransactions.filter { transaction in
            transaction.type == .expense && transaction.category?.name == category.name
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
        
        // Calculate total income from both planned and transaction items
        updateTotalIncome()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    

    

    
        private func updateTotalIncome() {
        let plannedIncomeTotal = currentMonthPlannedIncomes.reduce(0) { $0 + $1.amount }
        let transactionIncomeTotal = currentMonthIncomeTransactions.reduce(0) { $0 + $1.amount }
        totalIncome = plannedIncomeTotal + transactionIncomeTotal
    }
    
    private func deleteIncomeItem(at offsets: IndexSet) {
        for index in offsets {
            let plannedIncome = currentMonthPlannedIncomes[index]
            modelContext.delete(plannedIncome)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete planned income: \(error)")
        }
        
        updateTotalIncome()
    }

    private func saveIncomeItem() {
        guard let amount = Double(newIncomeAmount), amount > 0 else { return }
        
        let plannedIncome = PlannedIncome(
            name: newIncomeName,
            amount: amount,
            month: selectedMonth
        )
        modelContext.insert(plannedIncome)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save planned income: \(error)")
        }
        
        // Reset the form
        newIncomeName = ""
        newIncomeAmount = ""
        showingAddIncome = false
        
        updateTotalIncome()
    }
    
    private func cancelAddIncome() {
        newIncomeName = ""
        newIncomeAmount = ""
        showingAddIncome = false
    }
    

    
    private func saveItemForCategory(_ category: Category) {
        guard let amount = Double(newItemAmount), amount > 0 else { return }
        
        let plannedExpense = PlannedExpense(
            name: newItemName,
            amount: amount,
            month: selectedMonth,
            category: category
        )
        modelContext.insert(plannedExpense)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save planned expense: \(error)")
        }
        
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}



struct CategorySectionView: View {
    let category: Category
    @Binding var budgetAmounts: [String: Double]
    let currentTransactions: [Transaction]
    let plannedExpenses: [PlannedExpense]
    @Binding var showingAddItemForCategory: String?
    @Binding var newItemName: String
    @Binding var newItemAmount: String
    let onSaveItem: () -> Void
    let onCancelItem: () -> Void
    
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNameFocused: Bool
    
    private var categoryTransactions: [Transaction] {
        currentTransactions.filter { $0.category?.name == category.name && $0.type == .expense }
    }
    
    private var categoryTotal: Double {
        let budgetAmount = budgetAmounts[category.name] ?? 0
        let transactionAmount = categoryTransactions.reduce(0) { $0 + $1.amount }
        let plannedAmount = plannedExpenses.reduce(0) { $0 + $1.amount }
        return budgetAmount + transactionAmount + plannedAmount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                CategoryIconView(category: category, size: 24)
                
                Text(category.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if categoryTotal > 0 {
                    Text(formatCurrency(categoryTotal))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            // Budget amount row
            BudgetCategoryRow(
                category: category,
                budgetAmount: budgetAmounts[category.name] ?? 0,
                spentAmount: categoryTransactions.reduce(0) { $0 + $1.amount },
                onBudgetChange: { amount in
                    budgetAmounts[category.name] = amount
                }
            )
            
            // Display expense transactions (actual spending)
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
            
            // Display planned expenses (planned spending)
            ForEach(plannedExpenses, id: \.id) { plannedExpense in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plannedExpense.name)
                            .font(.body)
                            .fontWeight(.medium)
                        Text("Planned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("-\(formatCurrency(plannedExpense.amount))")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 4)
            }
            
            // Add Item button row or inline input row
            if showingAddItemForCategory == category.name {
                // Inline input row when adding item (replaces the Add Item button)
                HStack {
                    TextField("Item Name", text: $newItemName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .submitLabel(.done)
                        .focused($isNameFocused)
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
                        .onSubmit {
                            isAmountFocused = false
                        }
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
                    .foregroundColor(Color(hex: "023047") ?? .blue)
                }
            } else {
                // Add Item button
                HStack {
                    Button(action: { 
                        showingAddItemForCategory = category.name
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isNameFocused = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Item")
                        }
                        .foregroundColor(Color(hex: "023047") ?? .blue)
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

struct BudgetCategoryRow: View {
    let category: Category
    let budgetAmount: Double
    let spentAmount: Double
    let onBudgetChange: (Double) -> Void
    
    @State private var budgetText: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        // Empty view - budget amounts are now handled in the section header
        EmptyView()
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}











struct PlannedIncomeRow: View {
    let plannedIncome: PlannedIncome
    let onNameChange: (String) -> Void
    let onAmountChange: (Double) -> Void
    
    @State private var nameText: String = ""
    @State private var amountText: String = ""
    @State private var isEditingName: Bool = false
    @State private var isEditingAmount: Bool = false
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if isEditingName {
                TextField("Name", text: $nameText)
                    .submitLabel(.done)
                    .onSubmit {
                        onNameChange(nameText)
                        isEditingName = false
                    }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plannedIncome.name.isEmpty ? "Name" : plannedIncome.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(plannedIncome.name.isEmpty ? .secondary : .primary)
                        .onTapGesture {
                            nameText = plannedIncome.name
                            isEditingName = true
                        }
                    Text("Planned Income")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                                .foregroundColor(Color(hex: "023047") ?? .blue)
                            }
                        }
                    }
            } else {
                Text("+\(formatCurrency(plannedIncome.amount))")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .onTapGesture {
                        amountText = plannedIncome.amount > 0 ? String(format: "%.0f", plannedIncome.amount) : ""
                        isEditingAmount = true
                        isAmountFocused = true
                    }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            if plannedIncome.name.isEmpty && !isEditingName {
                nameText = plannedIncome.name
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

#Preview {
    BudgetView()
        .modelContainer(for: [Transaction.self, Category.self, Budget.self, RecurringSubscription.self, PlannedIncome.self, PlannedExpense.self], inMemory: true)
} 