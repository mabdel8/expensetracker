//
//  ReportsView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct ReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reports & Analytics")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("View your spending patterns and trends")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Quick overview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Overview")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            OverviewCard(
                                title: "Total Expenses",
                                value: totalExpenses,
                                color: .red,
                                systemImage: "minus.circle.fill"
                            )
                            
                            OverviewCard(
                                title: "Total Income",
                                value: totalIncome,
                                color: .green,
                                systemImage: "plus.circle.fill"
                            )
                            
                            OverviewCard(
                                title: "Net Balance",
                                value: netBalance,
                                color: netBalance >= 0 ? .green : .red,
                                systemImage: "equal.circle.fill"
                            )
                            
                            OverviewCard(
                                title: "This Month",
                                value: currentMonthTotal,
                                color: .blue,
                                systemImage: "calendar"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Placeholder for future charts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Charts & Visualizations")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack {
                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("Charts Coming Soon")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Pie charts and trend lines will be available in future updates")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var totalExpenses: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    private var netBalance: Double {
        totalIncome - totalExpenses
    }
    
    private var currentMonthTotal: Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return transactions.filter { transaction in
            let transactionMonth = Calendar.current.component(.month, from: transaction.date)
            let transactionYear = Calendar.current.component(.year, from: transaction.date)
            return transactionMonth == currentMonth && transactionYear == currentYear
        }.reduce(0) { $0 + ($1.type == .income ? $1.amount : -$1.amount) }
    }
}

struct OverviewCard: View {
    let title: String
    let value: Double
    let color: Color
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(formattedValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

#Preview {
    ReportsView()
        .modelContainer(for: [Transaction.self, Category.self, Budget.self], inMemory: true)
} 