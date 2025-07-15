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
    

    
    private var expenseCategoriesData: [CategoryExpenseData] {
        let expenseTransactions = filteredTransactions.filter { $0.type == .expense }
        var categoryTotals: [String: Double] = [:]
        
        for transaction in expenseTransactions {
            let categoryName = transaction.category?.name ?? "Uncategorized"
            categoryTotals[categoryName, default: 0] += transaction.amount
        }
        
        return categoryTotals.map { CategoryExpenseData(name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
            .prefix(6)
            .map { $0 }
    }
    
    private var trendLineData: [TrendLineData] {
        let calendar = Calendar.current
        
        switch selectedTimeRange {
        case .month:
            // Generate weekly spending data for the selected month
            var weeklyData: [TrendLineData] = []
            
            let monthTransactions = transactions.filter { transaction in
                calendar.isDate(transaction.date, equalTo: selectedMonth, toGranularity: .month)
            }
            
            guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth) else {
                return []
            }
            
            let startOfMonth = monthInterval.start
            let endOfMonth = monthInterval.end
            
            var weekNumber = 1
            var currentWeekStart = startOfMonth
            
            while currentWeekStart < endOfMonth && weekNumber <= 6 {
                let theoreticalWeekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart) ?? endOfMonth
                let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: endOfMonth) ?? endOfMonth
                let currentWeekEnd = min(theoreticalWeekEnd, lastDayOfMonth)
                
                let weekTransactions = monthTransactions.filter { transaction in
                    let transactionDate = calendar.startOfDay(for: transaction.date)
                    let weekStartDay = calendar.startOfDay(for: currentWeekStart)
                    let weekEndDay = calendar.startOfDay(for: currentWeekEnd)
                    return transactionDate >= weekStartDay && transactionDate <= weekEndDay
                }
                
                let expenses = weekTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
                
                weeklyData.append(TrendLineData(period: "Week \(weekNumber)", value: expenses))
                
                guard let nextWeekStart = calendar.date(byAdding: .day, value: 7, to: currentWeekStart) else {
                    break
                }
                currentWeekStart = nextWeekStart
                weekNumber += 1
            }
            
            return weeklyData
            
        case .year:
            // Generate monthly savings data for the selected year
            var monthlyData: [TrendLineData] = []
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
                let savings = income - expenses
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                let monthName = formatter.string(from: monthDate)
                
                monthlyData.append(TrendLineData(period: monthName, value: savings))
            }
            
            return monthlyData
        }
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
                    
                    // Expense Categories Donut Chart
                    expenseCategoriesDonutChart
                    
                    // Trend Line Chart
                    trendLineChart
                    
                    // Quick Stats
                    quickStats
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
                .padding(.top, 40)
            }
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
                    ForEach(incomeVsExpensesData, id: \.period) { data in
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
    
    private var expenseCategoriesDonutChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Breakdown")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            if expenseCategoriesData.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.donut")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No spending data")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 20) {
                    // Pie Chart
                    Chart(expenseCategoriesData.enumerated().map { IndexedCategoryData(index: $0.offset, category: $0.element) }, id: \.category.name) { indexedCategory in
                        SectorMark(
                            angle: .value("Amount", indexedCategory.category.amount),
                            angularInset: 1.0
                        )
                        .foregroundStyle(categoryColor(for: indexedCategory.index))
                        .cornerRadius(4)
                    }
                    .frame(width: 160, height: 160)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(expenseCategoriesData.prefix(6).enumerated().map { IndexedCategoryData(index: $0.offset, category: $0.element) }, id: \.category.name) { indexedCategory in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(categoryColor(for: indexedCategory.index))
                                    .frame(width: 12, height: 12)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(indexedCategory.category.name)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                    Text(formatCurrency(indexedCategory.category.amount))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(Int((indexedCategory.category.amount / expenseCategoriesData.reduce(0) { $0 + $1.amount }) * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .padding(.bottom, 20)
    }
    
    private var trendLineChart: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedTimeRange == .month ? "Weekly Spending Trend" : "Monthly Savings Trend")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "023047") ?? .blue)
                
                if !trendLineData.isEmpty && !trendLineData.allSatisfy({ $0.value == 0 }) {
                    let totalValue = selectedTimeRange == .month ? 
                        trendLineData.reduce(0) { $0 + $1.value } :
                        trendLineData.reduce(0) { $0 + $1.value }
                    
                    Text(formatCurrency(totalValue))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(selectedTimeRange == .month ? "Total spending" : "Total savings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if trendLineData.isEmpty {
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
            } else if trendLineData.allSatisfy({ $0.value == 0 }) {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(selectedTimeRange == .month ? "No spending recorded" : "No savings recorded")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    let maxValue = trendLineData.map { abs($0.value) }.max() ?? 1
                    
                    ForEach(trendLineData, id: \.period) { data in
                        let intensity = min(1.0, abs(data.value) / maxValue)
                        let baseOpacity = 0.6 + (intensity * 0.4) // Range from 0.6 to 1.0
                        
                        LineMark(
                            x: .value("Period", data.period),
                            y: .value("Value", data.value)
                        )
                        .foregroundStyle((Color(hex: "219EBC") ?? .blue).opacity(baseOpacity))
                        .lineStyle(StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Period", data.period),
                            y: .value("Value", data.value)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [(Color(hex: "219EBC") ?? .blue).opacity(baseOpacity * 0.8), (Color(hex: "219EBC") ?? .blue).opacity(baseOpacity * 0.3), Color.clear], startPoint: .top, endPoint: .bottom)
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.gray.opacity(0.3))
                        
                        if let doubleValue = value.as(Double.self) {
                            AxisValueLabel {
                                Text(formatCurrency(doubleValue))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    if selectedTimeRange == .year {
                        AxisMarks(position: .bottom) { value in
                            if let stringValue = value.as(String.self) {
                                let shouldShowLabel = stringValue.hasPrefix("Jan") || 
                                                    stringValue.hasPrefix("Apr") || 
                                                    stringValue.hasPrefix("Jul") || 
                                                    stringValue.hasPrefix("Oct") || 
                                                    stringValue.hasPrefix("Dec")
                                if shouldShowLabel {
                                    AxisValueLabel()
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } else {
                        AxisMarks(position: .bottom) { _ in
                            AxisValueLabel()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(Color.gray.opacity(0.02))
                        .cornerRadius(12)
                }
                .padding(.leading, 8)
                .padding(.trailing, 8)
                .padding(.top, 8)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
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

struct CategoryExpenseData: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
}

struct IndexedCategoryData: Identifiable {
    let id = UUID()
    let index: Int
    let category: CategoryExpenseData
}

struct TrendLineData: Identifiable {
    let id = UUID()
    let period: String
    let value: Double
}

extension AnalyticsView {
    private func categoryColor(for index: Int) -> Color {
        // Carefully selected colors with maximum visual distinction
        let colors: [Color] = [
            Color(hex: "219EBC") ?? .blue,   // Light blue
            .orange,                         // Orange
            Color(hex: "023047") ?? .blue,   // Dark blue
            .green,                          // Green
            .purple,                         // Purple
            .red,                            // Red
            .yellow,                         // Yellow
            .pink,                           // Pink
            .mint,                           // Mint
            .cyan,                           // Cyan
            .brown,                          // Brown
            Color(hex: "FF6B6B") ?? .red     // Coral red
        ]
        
        return colors[index % colors.count]
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Transaction.self, Category.self, MonthlyBudget.self, CategoryBudget.self, RecurringSubscription.self], inMemory: true)
} 