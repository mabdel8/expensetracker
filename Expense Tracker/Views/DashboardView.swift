//
//  DashboardView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @EnvironmentObject private var categoryManager: CategoryManager
    
    @State private var currentDate = Date()
    @State private var selectedMonth = Date()
    @State private var showCalendar = false
    @State private var showRecurringSubscriptions = false
    @State private var showAllTransactions = false
    
    private var recurringSubscriptionService: RecurringSubscriptionService {
        RecurringSubscriptionService(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                // Top navigation header
                HStack {
                    Button(action: {
                        showRecurringSubscriptions.toggle()
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "023047") ?? .blue)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showCalendar.toggle()
                    }) {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(Color(hex: "023047") ?? .blue)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Month navigation on main page
                HStack(spacing: 16) {
                    Button(action: {
                        changeMonth(-1)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.body)
                            .foregroundColor(Color(hex: "023047") ?? .blue)
                    }
                    
                    Text(monthYearString(for: selectedMonth))
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
                .padding(.top, 10)
                
                
                // Monthly Summary Card
                MonthlySummaryCard(
                    selectedMonth: selectedMonth,
                    transactions: transactions
                )
                .padding(.horizontal)
                
                // Recent Transactions
                RecentTransactionsView(
                    transactions: transactions,
                    showAllTransactions: $showAllTransactions
                )
                .padding(.horizontal)
                
                Spacer()
                }
                .padding(.bottom, 100) // Extra padding for tab bar
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showCalendar) {
            CalendarPageView(selectedMonth: selectedMonth, transactions: transactions)
        }
        .sheet(isPresented: $showRecurringSubscriptions) {
            RecurringSubscriptionsView()
        }
        .sheet(isPresented: $showAllTransactions) {
            AllTransactionsView()
        }
        .onAppear {
            processDueSubscriptions()
        }
    }
    
    private func changeMonth(_ direction: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let newDate = Calendar.current.date(byAdding: .month, value: direction, to: selectedMonth) {
                selectedMonth = newDate
            }
        }
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func processDueSubscriptions() {
        recurringSubscriptionService.processDueSubscriptions()
    }
}

struct CalendarView: View {
    let selectedMonth: Date
    let transactions: [Transaction]
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
                 VStack(spacing: 0) {
             // Day headers
             HStack {
                 ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                     Text(day)
                         .font(.caption)
                         .fontWeight(.medium)
                         .foregroundColor(.secondary)
                         .frame(maxWidth: .infinity)
                 }
             }
             .padding(.vertical, 12)
             
             Divider()
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 2) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            income: dailyIncome(for: date),
                            expense: dailyExpense(for: date)
                        )
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            
            // Monthly Net Balance
            Divider()
                .padding(.horizontal, 8)
            
            HStack {
                Text("Net Balance")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(monthlyNetBalance >= 0 ? "+" : "")$\(monthlyNetBalance, specifier: "%.0f")")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(monthlyNetBalance >= 0 ? .green : .red)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .padding(.top, 8)
    }
    
    private var daysInMonth: [Date?] {
        var days: [Date?] = []
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else {
            return days
        }
        
        let firstOfMonth = monthInterval.start
        let lastOfMonth = calendar.date(byAdding: DateComponents(day: -1), to: monthInterval.end)!
        
        // Get the first day of the week for the first day of the month
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        
        // Add empty days for the beginning of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days of the month
        var currentDate = firstOfMonth
        while currentDate <= lastOfMonth {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    private func dailyIncome(for date: Date) -> Double {
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, inSameDayAs: date) && transaction.type == .income
        }.reduce(0) { $0 + $1.amount }
    }
    
    private func dailyExpense(for date: Date) -> Double {
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, inSameDayAs: date) && transaction.type == .expense
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var monthlyNetBalance: Double {
        let monthlyIncome = transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month) && transaction.type == .income
        }.reduce(0) { $0 + $1.amount }
        
        let monthlyExpenses = transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month) && transaction.type == .expense
        }.reduce(0) { $0 + $1.amount }
        
        return monthlyIncome - monthlyExpenses
    }
}

struct CalendarDayView: View {
    let date: Date
    let income: Double
    let expense: Double
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 2) {
            Text(dateFormatter.string(from: date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
            
            VStack(spacing: 1) {
                if income > 0 {
                    Text("+$\(income, specifier: "%.0f")")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                if expense > 0 {
                    Text("-$\(expense, specifier: "%.0f")")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
        )
    }
}

struct MonthlySummaryCard: View {
    let selectedMonth: Date
    let transactions: [Transaction]
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with month savings
            VStack(alignment: .leading, spacing: 8) {
                Text("\(monthName) Savings")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Spending Donut Chart
            VStack(spacing: 20) {
                // Chart
                Chart(spendingData, id: \.category) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 2.0
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartBackground { _ in
                    VStack(spacing: 4) {
                        Text("$\(monthlyIncome, specifier: "%.0f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Text("Total Income")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // Legend
                HStack(spacing: 20) {
                    ForEach(spendingData, id: \.category) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.category)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.black)
                                Text("$\(item.amount, specifier: "%.0f")")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: selectedMonth)
    }
    
    private var transactionCount: Int {
        return monthlyTransactions.count
    }
    
    private var incomeTransactionCount: Int {
        return monthlyTransactions.filter { $0.type == .income }.count
    }
    
    private var expenseTransactionCount: Int {
        return monthlyTransactions.filter { $0.type == .expense }.count
    }
    
    private var monthlyIncome: Double {
        return monthlyTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var monthlyExpenses: Double {
        return monthlyTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var balance: Double {
        return monthlyIncome - monthlyExpenses
    }
    
    private var monthlyTransactions: [Transaction] {
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var spendingData: [SpendingDataItem] {
        let spent = monthlyExpenses
        let remaining = max(0, monthlyIncome - monthlyExpenses)
        
        return [
            SpendingDataItem(category: "Spent", amount: spent, color: Color(hex: "FB8500") ?? .red),
            SpendingDataItem(category: "Remaining", amount: remaining, color: Color(hex: "219EBC") ?? .blue)
        ]
    }
}

struct SpendingDataItem {
    let category: String
    let amount: Double
    let color: Color
}

struct RecentTransactionsView: View {
    let transactions: [Transaction]
    @Binding var showAllTransactions: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Recent Transactions")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                // See More Button
                if transactions.count > 5 {
                    Button(action: {
                        showAllTransactions = true
                    }) {
                        Text("See More")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "20B2AA") ?? .blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            // Transactions List
            VStack(spacing: 0) {
                if recentTransactions.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("No recent transactions")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(Array(recentTransactions.enumerated()), id: \.offset) { index, transaction in
                        RecentTransactionRow(
                            transaction: transaction,
                            isLast: index == recentTransactions.count - 1
                        )
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }
    
    private var recentTransactions: [Transaction] {
        return transactions
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { $0 }
    }
}

struct RecentTransactionRow: View {
    let transaction: Transaction
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Category icon
                CategoryIconView(category: transaction.category, size: 40)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.name)
                            .font(.body)
                            .fontWeight(.regular)
                            .lineLimit(1)
                        Text(transaction.category?.name ?? "Uncategorized")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            // Show recurring tag for recurring transactions
                            if transaction.isRecurring {
                                HStack(spacing: 4) {
                                    Text("recurring")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: "023047"))
                                .clipShape(Capsule())
                            }
                            
                            Text(transaction.displayAmount)
                                .font(.body)
                                .fontWeight(.light)
                                .foregroundColor(transaction.type == .expense ? .red : .green)
                        }
                        Text(formatDateFull(transaction.date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let notes = transaction.notes, !notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            if !isLast {
                Divider()// Align with text content
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    

}

struct CalendarPageView: View {
    let selectedMonth: Date
    let transactions: [Transaction]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                CalendarView(
                    selectedMonth: selectedMonth,
                    transactions: transactions
                )
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .background(Color.white)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Transaction.self, Category.self, MonthlyBudget.self, CategoryBudget.self, RecurringSubscription.self], inMemory: true)
} 
