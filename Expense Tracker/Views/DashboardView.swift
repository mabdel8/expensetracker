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
                    transactions: transactions,
                    onMonthChange: { direction in
                        changeMonth(direction)
                    }
                )
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width > threshold {
                            changeMonth(-1)
                        } else if value.translation.width < -threshold {
                            changeMonth(1)
                        }
                    }
            )
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
    let onMonthChange: (Int) -> Void
    
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
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width > threshold {
                        onMonthChange(-1)
                    } else if value.translation.width < -threshold {
                        onMonthChange(1)
                    }
                }
        )
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

#Preview {
    DashboardView()
        .modelContainer(for: [Transaction.self, Category.self, Budget.self], inMemory: true)
} 
