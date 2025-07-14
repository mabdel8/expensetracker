//
//  AllTransactionsView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct AllTransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var transactions: [Transaction]
    @EnvironmentObject private var categoryManager: CategoryManager
    
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedSortOrder: SortOrder = .dateDescending
    @State private var searchText = ""
    
    // Color scheme
    private let lightBlue = Color(red: 0.56, green: 0.79, blue: 0.90) // #8ECAE6
    private let teal = Color(red: 0.13, green: 0.62, blue: 0.74) // #219EBC
    private let darkTeal = Color(red: 0.01, green: 0.19, blue: 0.28) // #023047
    private let orange = Color(red: 0.98, green: 0.52, blue: 0.0) // #FB8500
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter and Sort Controls
                filterSortControls
                
                // Transactions List
                if filteredAndSortedTransactions.isEmpty {
                    emptyState
                } else {
                    transactionsList
                }
            }
            .background(Color.white)
            .navigationTitle("All Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search transactions...")
        }
    }
    
    private var filterSortControls: some View {
        VStack(spacing: 8) {
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(TransactionFilter.allCases, id: \.self) { filter in
                    Text(filter.displayName).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Sort Order Picker
            HStack {
                Text("Sort by:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Sort", selection: $selectedSortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.displayName).tag(order)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 4)
        .background(Color.white)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Transactions Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Try adjusting your search or filter criteria.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    private var transactionsList: some View {
        List {
            ForEach(groupedTransactions.keys.sorted(by: >), id: \.self) { date in
                Section {
                    ForEach(groupedTransactions[date] ?? [], id: \.name) { transaction in
                        AllTransactionRow(transaction: transaction)
                    }
                } header: {
                    HStack {
                        Text(formatSectionDate(date))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(darkTeal)
                        
                        Spacer()
                        
                        let dayTransactions = groupedTransactions[date] ?? []
                        let dayTotal = dayTransactions.reduce(0) { total, transaction in
                            total + (transaction.type == .income ? transaction.amount : -transaction.amount)
                        }
                        
                        Text(formatCurrency(dayTotal))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(dayTotal >= 0 ? .green : .red)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredAndSortedTransactions: [Transaction] {
        var filtered = transactions
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .income:
            filtered = filtered.filter { $0.type == .income }
        case .expense:
            filtered = filtered.filter { $0.type == .expense }
        case .recurring:
            filtered = filtered.filter { $0.isRecurring }
        }
        
        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.name.localizedCaseInsensitiveContains(searchText) ||
                transaction.category?.name.localizedCaseInsensitiveContains(searchText) == true ||
                transaction.notes?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply sort
        switch selectedSortOrder {
        case .dateDescending:
            filtered = filtered.sorted { $0.date > $1.date }
        case .dateAscending:
            filtered = filtered.sorted { $0.date < $1.date }
        case .amountDescending:
            filtered = filtered.sorted { $0.amount > $1.amount }
        case .amountAscending:
            filtered = filtered.sorted { $0.amount < $1.amount }
        case .nameAscending:
            filtered = filtered.sorted { $0.name < $1.name }
        }
        
        return filtered
    }
    
    private var groupedTransactions: [String: [Transaction]] {
        Dictionary(grouping: filteredAndSortedTransactions) { transaction in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: transaction.date)
        }
    }
    
    private func formatSectionDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        let prefix = amount >= 0 ? "+" : "-"
        return "\(prefix)\(formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00")"
    }
}

struct AllTransactionRow: View {
    let transaction: Transaction
    
    // Color scheme
    private let darkTeal = Color(red: 0.01, green: 0.19, blue: 0.28) // #023047
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            CategoryIconView(category: transaction.category, size: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(transaction.category?.name ?? "No Category")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let notes = transaction.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .italic()
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                                 HStack(spacing: 6) {
                     // Show recurring tag for recurring transactions
                     if transaction.isRecurring {
                         HStack(spacing: 3) {
                             Text("recurring")
                                 .font(.caption2)
                                 .fontWeight(.medium)
                                 .foregroundColor(.white)
                             
                             Image(systemName: "arrow.clockwise")
                                 .font(.caption2)
                                 .foregroundColor(.white)
                         }
                         .padding(.horizontal, 5)
                         .padding(.vertical, 2)
                         .background(darkTeal)
                         .clipShape(Capsule())
                     }
                     
                     Text(transaction.displayAmount)
                         .font(.body)
                         .fontWeight(.light)
                         .foregroundColor(transaction.type == .expense ? .red : .green)
                 }
                
                Text(formatTime(transaction.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

enum TransactionFilter: CaseIterable {
    case all, income, expense, recurring
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .income: return "Income"
        case .expense: return "Expenses"
        case .recurring: return "Recurring"
        }
    }
}

enum SortOrder: CaseIterable {
    case dateDescending, dateAscending, amountDescending, amountAscending, nameAscending
    
    var displayName: String {
        switch self {
        case .dateDescending: return "Date (Newest)"
        case .dateAscending: return "Date (Oldest)"
        case .amountDescending: return "Amount (High)"
        case .amountAscending: return "Amount (Low)"
        case .nameAscending: return "Name (A-Z)"
        }
    }
}

#Preview {
    AllTransactionsView()
        .modelContainer(for: [Transaction.self, Category.self, MonthlyBudget.self, CategoryBudget.self, RecurringSubscription.self], inMemory: true)
} 