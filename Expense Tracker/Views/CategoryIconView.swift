//
//  CategoryIconView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI

struct CategoryIconView: View {
    let category: Category?
    let size: CGFloat
    
    init(category: Category?, size: CGFloat = 40) {
        self.category = category
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(category?.color ?? Color.gray)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: category?.iconName ?? "questionmark")
                    .font(.system(size: size * 0.5, weight: .medium))
                    .foregroundColor(.white)
            )
    }
}

// Alternative initializer for when you have category name and need to look it up
struct CategoryIconViewByName: View {
    let categoryName: String
    let size: CGFloat
    let categories: [Category]
    
    init(categoryName: String, categories: [Category], size: CGFloat = 40) {
        self.categoryName = categoryName
        self.categories = categories
        self.size = size
    }
    
    private var category: Category? {
        categories.first { $0.name == categoryName }
    }
    
    var body: some View {
        CategoryIconView(category: category, size: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Example with sample category data
        CategoryIconView(category: nil, size: 40)
        CategoryIconView(category: nil, size: 60)
        CategoryIconView(category: nil, size: 80)
    }
    .padding()
} 