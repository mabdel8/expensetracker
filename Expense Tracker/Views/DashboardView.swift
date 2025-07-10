//
//  DashboardView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    
    @State private var currentDate = Date()
    @State private var selectedMonth = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                // Month navigation header
                HStack {
                    Button(action: {
                        changeMonth(-1)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(monthYearString(for: selectedMonth))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {
                        changeMonth(1)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                // Calendar view
                CalendarView(
                    selectedMonth: selectedMonth,
                    transactions: transactions
                )
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                
                // Monthly Summary Card
                MonthlySummaryCard(
                    selectedMonth: selectedMonth,
                    transactions: transactions
                )
                .padding(.horizontal)
                
                // Breakdown Cards (Swipeable)
                BreakdownCardsView(
                    selectedMonth: selectedMonth,
                    transactions: transactions
                )
                .padding(.horizontal)
                
                Spacer()
                }
                .padding(.bottom, 100) // Extra padding for tab bar
            }
            .navigationBarHidden(true)
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
                    Text("+\(income, specifier: "%.0f")")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                if expense > 0 {
                    Text("-\(expense, specifier: "%.0f")")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isToday ? Color.blue.opacity(0.1) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isToday ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
}

struct MonthlySummaryCard: View {
    let selectedMonth: Date
    let transactions: [Transaction]
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with month/year
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(monthYearString)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("\(transactionCount) transactions")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Net Balance")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("$\(balance, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
            
            // Financial breakdown
            HStack {
                // Income section
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("Total Income")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text("$\(monthlyIncome, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("\(incomeTransactionCount) payments")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // Expenses section
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        Text("Total Expenses")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text("$\(monthlyExpenses, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                    Text("\(expenseTransactionCount) purchases")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
            }
                         .padding(.horizontal, 20)
             .padding(.vertical, 16)
         }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
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
}

struct BreakdownCardsView: View {
    let selectedMonth: Date
    let transactions: [Transaction]
    
    @State private var currentCardId: Int? = 0
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with title and pagination
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text((currentCardId ?? 0) == 0 ? "Expense Breakdown" : "Income Breakdown")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Swipe to see \((currentCardId ?? 0) == 0 ? "income" : "expenses")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Pagination dots
                HStack(spacing: 6) {
                    ForEach(0..<2, id: \.self) { index in
                        Circle()
                            .fill((currentCardId ?? 0) == index ? Color.primary : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentCardId)
                    }
                }
                        }
            
            // Scrollable cards
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    // Expense Breakdown Card
                    CategoryBreakdownCard(
                        title: "Expense Breakdown",
                        categories: expenseCategories,
                        type: .expense
                    )
                    .containerRelativeFrame(.horizontal)
                    .scrollTransition(.animated(.easeInOut(duration: 0.4))) { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                            .opacity(phase.isIdentity ? 1.0 : 0.8)
                    }
                    .id(0)
                    
                    // Income Breakdown Card
                    CategoryBreakdownCard(
                        title: "Income Breakdown", 
                        categories: incomeCategories,
                        type: .income
                    )
                    .containerRelativeFrame(.horizontal)
                    .scrollTransition(.animated(.easeInOut(duration: 0.4))) { content, phase in
                        content
                            .scaleEffect(phase.isIdentity ? 1.0 : 0.95)
                            .opacity(phase.isIdentity ? 1.0 : 0.8)
                    }
                    .id(1)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
            .scrollIndicators(.hidden)
            .scrollPosition(id: $currentCardId)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .frame(height: 280)
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
    }
    
    private var monthlyTransactions: [Transaction] {
        return transactions.filter { transaction in
            calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var expenseCategories: [CategoryBreakdown] {
        let expenseTransactions = monthlyTransactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenseTransactions) { $0.category?.name ?? "Uncategorized" }
        
        return grouped.map { categoryName, transactions in
            let total = transactions.reduce(0) { $0 + $1.amount }
            let iconName = transactions.first?.category?.iconName ?? "questionmark.circle"
            return CategoryBreakdown(name: categoryName, amount: total, iconName: iconName)
        }.sorted { $0.amount > $1.amount }
    }
    
    private var incomeCategories: [CategoryBreakdown] {
        let incomeTransactions = monthlyTransactions.filter { $0.type == .income }
        let grouped = Dictionary(grouping: incomeTransactions) { $0.category?.name ?? "Uncategorized" }
        
        return grouped.map { categoryName, transactions in
            let total = transactions.reduce(0) { $0 + $1.amount }
            let iconName = transactions.first?.category?.iconName ?? "questionmark.circle"
            return CategoryBreakdown(name: categoryName, amount: total, iconName: iconName)
        }.sorted { $0.amount > $1.amount }
    }
}

struct CategoryBreakdown {
    let name: String
    let amount: Double
    let iconName: String
}

struct CategoryBreakdownCard: View {
    let title: String
    let categories: [CategoryBreakdown]
    let type: TransactionType
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("$\(totalAmount, specifier: "%.2f")")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(type == .expense ? .red : .green)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            Divider()
            
            // Categories List
            ScrollView {
                LazyVStack(spacing: 0) {
                    if categories.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("No \(type == .expense ? "expenses" : "income") this month")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                            BreakdownCategoryRow(
                                category: category,
                                type: type,
                                isLast: index == categories.count - 1
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var totalAmount: Double {
        return categories.reduce(0) { $0 + $1.amount }
    }
}

struct BreakdownCategoryRow: View {
    let category: CategoryBreakdown
    let type: TransactionType
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: category.iconName)
                    .font(.title3)
                    .foregroundColor(type == .expense ? .red : .green)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text(category.amount == 0 ? "No transactions" : "")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("\(type == .expense ? "-" : "+")$\(category.amount, specifier: "%.2f")")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(type == .expense ? .red : .green)
            }
            .padding(.vertical, 12)
            
            if !isLast {
                Divider()
            }
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Transaction.self, Category.self, Budget.self], inMemory: true)
} 
