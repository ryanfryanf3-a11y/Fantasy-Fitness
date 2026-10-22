//
//  RecipeSheets.swift
//  Fantasy Fitness
//

import SwiftUI

/// Rate on separate axes. Macro profile is computed, so it isn't rated here.
struct RateRecipeSheet: View {
    let recipe: Recipe

    @Environment(GameStore.self) private var store
    @State private var taste = 4
    @State private var ease = 4
    @State private var cost = 4
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetScaffold(title: "Rate recipe", closeLabel: "Cancel") {
            Text(recipe.name)
                .font(.alegreya(20, weight: .heavy))
                .foregroundStyle(Theme.ink)

            VStack(alignment: .leading, spacing: 14) {
                axis("Taste", $taste)
                axis("Ease", $ease)
                axis("Cost", $cost)
            }
            .padding(.top, 16)

            Text("Macro profile (\(recipe.macros.profileLabel.lowercased())) is calculated from the ingredients.")
                .font(.alegreyaSans(14))
                .foregroundStyle(Theme.inkSecondary)
                .padding(.top, 16)

            Button("Submit rating") {
                Task {
                    isSaving = true
                    if await store.rate(recipe, taste: taste, ease: ease, cost: cost) { dismiss() }
                    isSaving = false
                }
            }
            .disabled(isSaving)
                .buttonStyle(.chunky(.wax))
                .padding(.top, 22)
        }
        .presentationDetents([.medium, .large])
    }

    private func axis(_ name: String, _ value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.alegreyaSans(17, weight: .bold))
                .foregroundStyle(Theme.ink)
            StarRatingPicker(value: value)
                .accessibilityLabel(name)
        }
    }
}

/// New recipe with ingredients; macros are filled in automatically once food data is connected.
struct CreateRecipeSheet: View {
    @Environment(GameStore.self) private var store
    @State private var isSaving = false
    @State private var name = ""
    @State private var mealType: MealType = .dinner
    @State private var ingredients: [Ingredient] = []
    @State private var ingredientName = ""
    @State private var ingredientAmount = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetScaffold(title: "New recipe", closeLabel: "Cancel") {
            ParchmentField(title: "Name", text: $name, prompt: "Hearty stew")

            Text("Meal")
                .font(.alegreyaSans(15, weight: .bold))
                .foregroundStyle(Theme.inkSecondary)
                .padding(.top, 16)
            WoodSegmentedPicker(options: MealType.allCases, selection: $mealType, title: \.name)
                .padding(.top, 6)

            Text("Ingredients")
                .font(.alegreya(18))
                .foregroundStyle(Theme.ink)
                .padding(.top, 20)
            VStack(spacing: 0) {
                ForEach(ingredients, id: \.self) { ingredient in
                    HStack {
                        Text(ingredient.name)
                            .font(.alegreyaSans(17, weight: .medium))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(ingredient.amount)
                            .font(.alegreyaSans(16))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .padding(.vertical, 10)
                    DashedDivider()
                }
            }

            HStack(alignment: .bottom, spacing: 10) {
                ParchmentField(title: "Ingredient", text: $ingredientName, prompt: "Chicken thigh")
                ParchmentField(title: "Amount", text: $ingredientAmount, prompt: "300 g")
                    .frame(width: 100)
            }
            .padding(.top, 10)

            Button {
                ingredients.append(Ingredient(name: ingredientName, amount: ingredientAmount))
                ingredientName = ""
                ingredientAmount = ""
            } label: {
                Label("Add ingredient", systemImage: "plus")
            }
            .buttonStyle(.chunky(.wood, minHeight: 48, fontSize: 17))
            .disabled(ingredientName.isEmpty)
            .padding(.top, 12)

            Text("Macros will be calculated from your ingredients once food data is connected.")
                .font(.alegreyaSans(14))
                .foregroundStyle(Theme.inkSecondary)
                .padding(.top, 16)

            Button("Save recipe") {
                Task {
                    isSaving = true
                    if await store.createRecipe(name: name, mealType: mealType, ingredients: ingredients) {
                        dismiss()
                    }
                    isSaving = false
                }
            }
                .buttonStyle(.chunky(.emerald))
                .disabled(name.isEmpty || ingredients.isEmpty || isSaving)
                .padding(.top, 18)
        }
    }
}

#Preview("Rate") {
    Text("Tavern").sheet(isPresented: .constant(true)) { RateRecipeSheet(recipe: Recipe.samples[0]).environment(GameStore.preview) }
}

#Preview("Create") {
    Text("Tavern").sheet(isPresented: .constant(true)) { CreateRecipeSheet().environment(GameStore.preview) }
}
