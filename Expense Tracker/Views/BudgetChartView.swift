//
//  BudgetChartView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import Charts

struct BudgetChartView: View {
    let totalBudget: Double
    let spentAmount: Double
    
    @State private var selectedSegment: String?
    
    private var remainingAmount: Double {
        max(0, totalBudget - spentAmount)
    }
    
    private var usagePercentage: Double {
        guard totalBudget > 0 else { return 0 }
        return (spentAmount / totalBudget) * 100
    }
    
    private var chartData: [(type: String, amount: Double, color: Color)] {
        [
            (type: "Spent", amount: spentAmount, color: Color.orange),
            (type: "Remaining", amount: remainingAmount, color: Color(hex: "023047") ?? .blue)
        ]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Chart
            Chart(chartData, id: \.type) { dataItem in
                SectorMark(
                    angle: .value("Amount", dataItem.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .cornerRadius(4)
                .foregroundStyle(dataItem.color)
                .opacity(selectedSegment == nil || selectedSegment == dataItem.type ? 1.0 : 0.5)
            }
            .frame(height: 200)
            .chartAngleSelection(value: $selectedSegment)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let plotFrame = chartProxy.plotFrame {
                        let frame = geometry[plotFrame]
                        centerContentView
                            .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            
            // Legend
            HStack(spacing: 24) {
                ForEach(chartData, id: \.type) { dataItem in
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(dataItem.color)
                                .frame(width: 12, height: 12)
                            Text(dataItem.type)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(formatCurrency(dataItem.amount))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    private var centerContentView: some View {
        VStack(spacing: 4) {
            if let selectedSegment = selectedSegment {
                // Show selected segment details
                let selectedData = chartData.first { $0.type == selectedSegment }
                Text(selectedSegment)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(formatCurrency(selectedData?.amount ?? 0))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(selectedData?.color ?? .primary)
            } else {
                // Show total budget and usage
                Text("Total Budget")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(formatCurrency(totalBudget))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("\(Int(usagePercentage))% Used")
                    .font(.caption2)
                    .foregroundColor(.secondary)
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

struct BudgetChartView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetChartView(totalBudget: 5000, spentAmount: 3200)
            .padding()
    }
} 