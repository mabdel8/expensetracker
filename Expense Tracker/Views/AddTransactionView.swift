//
//  AddTransactionView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var amount = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var date = Date()
    @State private var notes = ""
    
    @Query private var categories: [Category]
    
    var availableCategories: [Category] {
        categories.filter { $0.transactionType == selectedType }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Type Selector
                    typeSelector
                    
                    // Amount Section
                    amountSection
                    
                    // Category Section
                    categorySection
                    
                    // Date and Time Section
                    dateTimeSection
                    
                    // Notes Section
                    notesSection
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationBarHidden(true)
            .overlay(
                // Save and Cancel buttons
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                        
                        Button("Save") {
                            saveTransaction()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .disabled(name.isEmpty || amount.isEmpty || selectedCategory == nil)
                        .opacity((name.isEmpty || amount.isEmpty || selectedCategory == nil) ? 0.5 : 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            )
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Add transactions")
                .font(.headline)
                .fontWeight(.medium)
            
            Spacer()
            
            // Placeholder for right side (matching image layout)
            Color.clear
                .frame(width: 30, height: 30)
        }
    }
    
    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose")
                .font(.headline)
                .fontWeight(.medium)
            
            HStack(spacing: 0) {
                Button(action: { selectedType = .income }) {
                    HStack {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16))
                        Text("Income")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(selectedType == .income ? Color.blue : Color.clear)
                    .foregroundColor(selectedType == .income ? .white : .primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(25)
                }
                
                Button(action: { selectedType = .expense }) {
                    HStack {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16))
                        Text("Expense")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(selectedType == .expense ? Color.blue : Color.clear)
                    .foregroundColor(selectedType == .expense ? .white : .primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(25)
                }
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(25)
        }
    }
    
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Amount")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Description")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("Enter description", text: $name)
                        .font(.body)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.headline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 5), spacing: 16) {
                ForEach(availableCategories, id: \.name) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory?.name == category.name,
                        action: { selectedCategory = category }
                    )
                }
                
                // Custom category button
                Button(action: {
                    // Handle custom category - for now just show placeholder
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Custom")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var dateTimeSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Date")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(CompactDatePickerStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Time")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(CompactDatePickerStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .fontWeight(.medium)
            
            TextField("Add details", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let transaction = Transaction(
            name: name.isEmpty ? selectedCategory?.name ?? "Transaction" : name,
            date: date,
            amount: amountValue,
            notes: notes.isEmpty ? nil : notes,
            type: selectedType,
            category: selectedCategory
        )
        
        modelContext.insert(transaction)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving transaction: \(error)")
        }
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(category.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [Transaction.self, Category.self, Budget.self], inMemory: true)
} 