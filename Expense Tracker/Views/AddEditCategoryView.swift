//
//  AddEditCategoryView.swift
//  Expense Tracker
//
//  Created by Abdalla Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct AddEditCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let categoryToEdit: Category?
    
    @Query private var existingCategories: [Category]
    
    @State private var categoryName = ""
    @State private var selectedIcon = "questionmark.circle.fill"
    @State private var selectedColor = "#45B7D1"
    @State private var selectedType: TransactionType = .expense
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Available icons organized by type
    private let availableIcons = [
        // General/Business
        "banknote.fill", "creditcard.fill", "bag.fill", "cart.fill", "building.2.fill", 
        "house.fill", "car.fill", "airplane", "train.side.front.car", "bicycle",
        
        // Food & Lifestyle
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "birthday.cake.fill",
        "gamecontroller.fill", "tv.fill", "music.note", "camera.fill", "book.fill",
        
        // Health & Personal
        "heart.fill", "cross.case.fill", "dumbbell.fill", "figure.walk", "bed.double.fill",
        "person.fill", "scissors", "eyeglasses", "stethoscope", "pills.fill",
        
        // Utilities & Services
        "doc.text.fill", "phone.fill", "wifi", "bolt.fill", "drop.fill", "flame.fill",
        "trash.fill", "wrench.and.screwdriver.fill", "gear", "shield.fill",
        
        // Income & Investment
        "chart.line.uptrend.xyaxis", "chart.bar.fill", "percent", "gift.fill", 
        "laptopcomputer", "briefcase.fill", "graduationcap.fill", "star.fill"
    ]
    
    // Available colors
    private let availableColors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#F7DC6F", "#BB8FCE",
        "#58D68D", "#F1948A", "#85C1E9", "#82E0AA", "#F8C471",
        "#AF7AC5", "#5DADE2", "#FF9F43", "#54A0FF", "#26de81",
        "#fd79a8", "#e17055", "#00b894", "#0984e3", "#6c5ce7"
    ]
    
    private var isEditing: Bool {
        categoryToEdit != nil
    }
    
    private var canSave: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isDuplicateName
    }
    
    private var isDuplicateName: Bool {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        return existingCategories.contains { category in
            category.name.lowercased() == trimmedName.lowercased() &&
            category.transactionType == selectedType &&
            category != categoryToEdit // Exclude current category when editing
        }
    }
    
    init(categoryToEdit: Category? = nil) {
        self.categoryToEdit = categoryToEdit
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Category Preview
                    categoryPreview
                    
                    // Name Input
                    nameInputSection
                    
                    // Type Selection
                    typeSelectionSection
                    
                    // Icon Selection
                    iconSelectionSection
                    
                    // Color Selection
                    colorSelectionSection
                    
                    // Save/Cancel Buttons
                    actionButtons
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCategoryData()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var categoryPreview: some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: selectedIcon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: selectedColor) ?? .blue)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(categoryName.isEmpty ? "Category Name" : categoryName)
                        .font(.headline)
                        .foregroundColor(categoryName.isEmpty ? .secondary : .primary)
                    
                    Text(selectedType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Name")
                .font(.headline)
            
            TextField("Enter category name", text: $categoryName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
            
            if isDuplicateName {
                Text("A category with this name already exists for \(selectedType.displayName.lowercased()) transactions")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var typeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transaction Type")
                .font(.headline)
            
            Picker("Type", selection: $selectedType) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private var iconSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(availableIcons, id: \.self) { icon in
                    Button(action: {
                        selectedIcon = icon
                    }) {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(selectedIcon == icon ? .white : .secondary)
                            .frame(width: 44, height: 44)
                            .background(selectedIcon == icon ? Color.blue : Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 10), spacing: 8) {
                ForEach(availableColors, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                    }) {
                        Circle()
                            .fill(Color(hex: color) ?? .blue)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                            )
                    }
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Button(action: {
                saveCategory()
            }) {
                Text(isEditing ? "Save Changes" : "Create Category")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(canSave ? Color.blue : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(!canSave)
        }
    }
    
    private func loadCategoryData() {
        if let category = categoryToEdit {
            categoryName = category.name
            selectedIcon = category.iconName
            selectedColor = category.colorHex
            selectedType = category.transactionType
        }
    }
    
    private func saveCategory() {
        let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard canSave else {
            errorMessage = "Please enter a valid category name"
            showingError = true
            return
        }
        
        do {
            if let category = categoryToEdit {
                // Update existing category
                category.name = trimmedName
                category.iconName = selectedIcon
                category.colorHex = selectedColor
                category.transactionType = selectedType
            } else {
                // Create new category
                let newCategory = Category(
                    name: trimmedName,
                    iconName: selectedIcon,
                    colorHex: selectedColor,
                    transactionType: selectedType
                )
                modelContext.insert(newCategory)
            }
            
            try modelContext.save()
            dismiss()
            
        } catch {
            errorMessage = "Failed to save category: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    AddEditCategoryView()
        .modelContainer(for: [Category.self, Transaction.self], inMemory: true)
} 