//
//  AnalyticsView.swift
//  Expense Tracker
//
//  Created by Abdalla Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @Query private var transactions: [Transaction]
    @Query private var recurringSubscriptions: [RecurringSubscription]
    @Query private var monthlyBudgets: [MonthlyBudget]
    
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedMonth = Date()
    @State private var selectedYear = Date()
    
    enum TimeRange: String, CaseIterable {
        case month = "Month"
        case year = "Year"
    }
    
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        
        let filtered: [Transaction]
        switch selectedTimeRange {
        case .month:
            filtered = transactions.filter { transaction in
                calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month)
            }
        case .year:
            let yearComponents = calendar.dateComponents([.year], from: selectedYear)
            filtered = transactions.filter { transaction in
                let transactionYear = calendar.component(.year, from: transaction.date)
                return transactionYear == yearComponents.year
            }
        }
        
        return filtered
    }
    
    private var totalIncome: Double {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalExpenses: Double {
        filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var netBalance: Double {
        totalIncome - totalExpenses
    }
    
    private var incomeVsExpensesData: [IncomeExpenseData] {
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .month:
            // Generate weekly data for the selected month
            var weeklyData: [IncomeExpenseData] = []
            
            // Get all transactions for the selected month (same approach as other views)
            let monthTransactions = transactions.filter { transaction in
                calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month)
            }
            
            // Debug: Basic validation
            // print("Monthly data: \(monthTransactions.count) total transactions")
            
            guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else {
                return []
            }
            
            let startOfMonth = monthInterval.start
            let endOfMonth = monthInterval.end
            
            // Calculate weeks more reliably
            var weekNumber = 1
            var currentWeekStart = startOfMonth
            
            while currentWeekStart < endOfMonth && weekNumber <= 6 {
                // Calculate the end of current week (6 days later or last day of month)
                let theoreticalWeekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart) ?? endOfMonth
                let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: endOfMonth) ?? endOfMonth
                let currentWeekEnd = min(theoreticalWeekEnd, lastDayOfMonth)
                
                // Filter transactions for this week (using date components to ignore time)
                let weekTransactions = monthTransactions.filter { transaction in
                    let transactionDate = calendar.startOfDay(for: transaction.date)
                    let weekStartDay = calendar.startOfDay(for: currentWeekStart)
                    let weekEndDay = calendar.startOfDay(for: currentWeekEnd)
                    return transactionDate >= weekStartDay && transactionDate <= weekEndDay
                }
                
                let income = weekTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                                let expenses = weekTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                
                weeklyData.append(IncomeExpenseData(period: "Week \(weekNumber)", income: income, expenses: expenses))
                
                // Move to next week (7 days)
                guard let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: currentWeekStart) else {
                    break
                }
                currentWeekStart = nextWeekStart
                weekNumber += 1
            }
            
            return weeklyData
            
        case .year:
            // Generate monthly data for the selected year (this works fine)
            var monthlyData: [IncomeExpenseData] = []
            let yearComponents = calendar.dateComponents([.year], from: selectedYear)
            
            guard let year = yearComponents.year else { return [] }
            
            for month in 1...12 {
                guard let monthDate = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
                    continue
                }
                
                let monthTransactions = transactions.filter { transaction in
                    calendar.isDate(transaction.date, equalTo: monthDate, toGranularity: .month)
                }
                
                let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
                let expenses = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                let monthName = formatter.string(from: monthDate)
                
                monthlyData.append(IncomeExpenseData(period: monthName, income: income, expenses: expenses))
            }
            
            return monthlyData
        }
    }
    
    private var monthlyTrends: [MonthlyTrend] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .month, value: -11, to: endDate) else {
            return []
        }
        
        var trends: [MonthlyTrend] = []
        var currentDate = startDate
        var monthCount = 0
        
        while currentDate <= endDate && monthCount < 12 {
            let monthTransactions = transactions.filter { transaction in
                calendar.isDate(transaction.date, equalTo: currentDate, toGranularity: .month)
            }
            
            let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expenses = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let monthName = formatter.string(from: currentDate)
            
            trends.append(MonthlyTrend(month: monthName, income: income, expenses: expenses))
            
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextMonth
            monthCount += 1
        }
        
        return trends
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Time Range Picker
                    timeRangePicker
                    
                    // Overview Cards
                    overviewCards
                    
                    // Income vs Expenses Chart
                    incomeVsExpensesChart
                    
                    // Monthly Trends Chart
                    monthlyTrendsChart
                    
                    // Quick Stats
                    quickStats
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var timeRangePicker: some View {
        VStack(spacing: 16) {
            if selectedTimeRange == .month {
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
            } else if selectedTimeRange == .year {
                HStack(spacing: 16) {
                    Button(action: {
                        changeYear(-1)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.body)
                            .foregroundColor(Color(hex: "023047") ?? .blue)
                    }
                    
                    Text(yearString)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "023047") ?? .blue)
                    
                    Button(action: {
                        changeYear(1)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.body)
                            .foregroundColor(Color(hex: "023047") ?? .blue)
                    }
                }
            }
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .background(Color.white)
            .cornerRadius(8)
        }
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    private var overviewCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            OverviewCard(title: "Income", amount: totalIncome, color: .green, icon: "arrow.up.circle.fill")
            OverviewCard(title: "Expenses", amount: totalExpenses, color: .red, icon: "arrow.down.circle.fill")
            OverviewCard(title: "Net Balance", amount: netBalance, color: netBalance >= 0 ? .green : .red, icon: "equal.circle.fill")
            OverviewCard(title: "Transactions", amount: Double(filteredTransactions.count), color: Color(hex: "219EBC") ?? .blue, icon: "list.bullet.circle.fill", isCount: true)
        }
        .padding(.bottom, 20)
    }
    
    private var incomeVsExpensesChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedTimeRange == .month ? "Weekly Income vs Expenses" : "Monthly Income vs Expenses")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            if incomeVsExpensesData.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No data available - Empty dataset")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else if incomeVsExpensesData.allSatisfy({ $0.income == 0 && $0.expenses == 0 }) {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No transactions found for this period")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Data points: \(incomeVsExpensesData.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(incomeVsExpensesData) { data in
                        BarMark(
                            x: .value("Period", data.period),
                            y: .value("Amount", data.income),
                            width: .ratio(0.4)
                        )
                        .foregroundStyle(Color(hex: "219EBC") ?? .blue)
                        .position(by: .value("Type", "Income"))
                        .cornerRadius(4)
                        
                        BarMark(
                            x: .value("Period", data.period),
                            y: .value("Amount", data.expenses),
                            width: .ratio(0.4)
                        )
                        .foregroundStyle(.orange)
                        .position(by: .value("Type", "Expenses"))
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    if selectedTimeRange == .year {
                        AxisMarks { value in
                            AxisGridLine()
                            if let stringValue = value.as(String.self) {
                                let shouldShowLabel = stringValue.hasPrefix("Jan") || 
                                                    stringValue.hasPrefix("Apr") || 
                                                    stringValue.hasPrefix("Jul") || 
                                                    stringValue.hasPrefix("Oct") || 
                                                    stringValue.hasPrefix("Dec")
                                if shouldShowLabel {
                                    AxisValueLabel()
                                }
                            }
                        }
                    } else {
                        AxisMarks(position: .bottom) { _ in
                            AxisValueLabel()
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Income": Color(hex: "219EBC") ?? .blue,
                    "Expenses": .orange
                ])
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.bottom, 20)
    }
    
    private var monthlyTrendsChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Trends")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            if monthlyTrends.allSatisfy({ $0.income == 0 && $0.expenses == 0 }) {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No data available")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(monthlyTrends) { trend in
                        LineMark(
                            x: .value("Month", trend.month),
                            y: .value("Income", trend.income)
                        )
                        .foregroundStyle(Color(hex: "219EBC") ?? .blue)
                        .symbol(Circle())
                        
                        LineMark(
                            x: .value("Month", trend.month),
                            y: .value("Expenses", trend.expenses)
                        )
                        .foregroundStyle(.orange)
                        .symbol(Circle())
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisValueLabel()
                    }
                }
                .chartForegroundStyleScale([
                    "Income": Color(hex: "219EBC") ?? .blue,
                    "Expenses": .orange
                ])
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.bottom, 20)
    }
    
    private var quickStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                QuickStatItem(title: "Categories", value: "\(categories.count)", icon: "folder.fill")
                QuickStatItem(title: "Budgets", value: "\(monthlyBudgets.count)", icon: "chart.pie.fill")
                QuickStatItem(title: "Subscriptions", value: "\(recurringSubscriptions.count)", icon: "arrow.clockwise.circle.fill")
                QuickStatItem(title: "Avg/Day", value: formatCurrency(calculateAveragePerDay()), icon: "calendar.circle.fill")
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.bottom, 20)
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }
    
    private var yearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: selectedYear)
    }
    
    private func changeMonth(_ direction: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: direction, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    private func changeYear(_ direction: Int) {
        if let newDate = Calendar.current.date(byAdding: .year, value: direction, to: selectedYear) {
            selectedYear = newDate
        }
    }
    
    private func calculateAveragePerDay() -> Double {
        let calendar = Calendar.current
        let days: Double
        
        switch selectedTimeRange {
        case .month:
            days = Double(calendar.dateInterval(of: .month, for: selectedMonth)?.duration ?? 1) / 86400
        case .year:
            days = Double(calendar.dateInterval(of: .year, for: selectedYear)?.duration ?? 1) / 86400
        }
        
        return totalExpenses / max(1, days)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct OverviewCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String
    let isCount: Bool
    
    init(title: String, amount: Double, color: Color, icon: String, isCount: Bool = false) {
        self.title = title
        self.amount = amount
        self.color = color
        self.icon = icon
        self.isCount = isCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isCount {
                Text("\(Int(amount))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            } else {
                Text(formatCurrency(amount))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct QuickStatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "219EBC") ?? .blue)
                    .font(.title3)
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct IncomeExpenseData: Identifiable {
    let id = UUID()
    let period: String
    let income: Double
    let expenses: Double
}

struct MonthlyTrend: Identifiable {
    let id = UUID()
    let month: String
    let income: Double
    let expenses: Double
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Transaction.self, Category.self, MonthlyBudget.self, CategoryBudget.self, RecurringSubscription.self], inMemory: true)
} 