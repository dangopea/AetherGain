//
//  FoodDatabase.swift
//  AetherGain
//
//  Local food macro reference (all values per 100 g). USDA-derived where
//  possible. Aliases power Vision-framework label mapping and fuzzy search.
//

import Foundation

struct FoodMacros {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let defaultServingG: Double
    let aliases: [String]
}

enum FoodDatabase {

    static let all: [FoodMacros] = [
        // MARK: - Indian
        FoodMacros(name: "Idli",     calories: 133, protein: 4.0,  carbs: 25.0, fat: 1.5,  defaultServingG: 60,
                   aliases: ["idli", "steamed cake", "rice cake"]),
        FoodMacros(name: "Dosa",     calories: 168, protein: 4.5,  carbs: 26.0, fat: 5.5,  defaultServingG: 80,
                   aliases: ["dosa", "crepe", "pancake"]),
        FoodMacros(name: "Vada",     calories: 335, protein: 12.0, carbs: 30.0, fat: 20.0, defaultServingG: 40,
                   aliases: ["vada", "medu vada", "fritter", "doughnut", "donut", "savory doughnut"]),
        FoodMacros(name: "Chapati",  calories: 297, protein: 9.5,  carbs: 55.0, fat: 4.5,  defaultServingG: 40,
                   aliases: ["chapati", "roti", "flatbread", "tortilla", "naan"]),
        FoodMacros(name: "Rice",     calories: 130, protein: 2.7,  carbs: 28.0, fat: 0.3,  defaultServingG: 150,
                   aliases: ["rice", "white rice", "steamed rice", "brown rice"]),
        FoodMacros(name: "Fried rice", calories: 174, protein: 4.5, carbs: 22.0, fat: 7.5, defaultServingG: 200,
                   aliases: ["fried rice", "pilaf"]),
        FoodMacros(name: "Biryani",  calories: 200, protein: 8.0,  carbs: 27.0, fat: 7.5,  defaultServingG: 250,
                   aliases: ["biryani", "pulao"]),
        FoodMacros(name: "Dal",      calories: 116, protein: 9.0,  carbs: 20.0, fat: 0.4,  defaultServingG: 200,
                   aliases: ["dal", "daal", "lentil", "lentils", "soup"]),
        FoodMacros(name: "Paneer",   calories: 265, protein: 18.0, carbs: 1.2,  fat: 20.8, defaultServingG: 80,
                   aliases: ["paneer", "cottage cheese"]),
        FoodMacros(name: "Samosa",   calories: 262, protein: 5.0,  carbs: 24.0, fat: 17.0, defaultServingG: 60,
                   aliases: ["samosa", "pastry"]),
        FoodMacros(name: "Poha",     calories: 180, protein: 4.0,  carbs: 32.0, fat: 4.0,  defaultServingG: 150,
                   aliases: ["poha", "flattened rice"]),
        FoodMacros(name: "Upma",     calories: 192, protein: 5.0,  carbs: 32.0, fat: 5.0,  defaultServingG: 150,
                   aliases: ["upma"]),
        FoodMacros(name: "Paratha",  calories: 297, protein: 7.5,  carbs: 40.0, fat: 12.0, defaultServingG: 80,
                   aliases: ["paratha", "aloo paratha"]),
        FoodMacros(name: "Chole",    calories: 164, protein: 8.9,  carbs: 27.0, fat: 2.6,  defaultServingG: 200,
                   aliases: ["chole", "chickpea curry", "chana masala"]),
        FoodMacros(name: "Rajma",    calories: 140, protein: 8.7,  carbs: 22.8, fat: 0.5,  defaultServingG: 200,
                   aliases: ["rajma", "kidney bean curry"]),

        // MARK: - Western mains
        FoodMacros(name: "Pizza",    calories: 266, protein: 11.0, carbs: 33.0, fat: 10.0, defaultServingG: 100,
                   aliases: ["pizza", "margherita"]),
        FoodMacros(name: "Burger",   calories: 295, protein: 17.0, carbs: 30.0, fat: 12.0, defaultServingG: 220,
                   aliases: ["burger", "hamburger", "cheeseburger"]),
        FoodMacros(name: "Sandwich", calories: 250, protein: 12.0, carbs: 33.0, fat: 8.0,  defaultServingG: 180,
                   aliases: ["sandwich", "sub"]),
        FoodMacros(name: "Pasta",    calories: 158, protein: 6.0,  carbs: 31.0, fat: 1.3,  defaultServingG: 200,
                   aliases: ["pasta", "spaghetti", "macaroni", "penne", "lasagna"]),
        FoodMacros(name: "Bread",    calories: 265, protein: 9.0,  carbs: 49.0, fat: 3.0,  defaultServingG: 30,
                   aliases: ["bread", "toast", "bun", "loaf", "white bread", "wheat bread"]),
        FoodMacros(name: "Noodles",  calories: 138, protein: 4.5,  carbs: 25.0, fat: 2.0,  defaultServingG: 200,
                   aliases: ["noodles", "ramen", "udon", "chow mein"]),
        FoodMacros(name: "Salad",    calories: 100, protein: 3.0,  carbs: 8.0,  fat: 5.0,  defaultServingG: 150,
                   aliases: ["salad", "lettuce", "greens", "caesar salad"]),
        FoodMacros(name: "Sushi",    calories: 143, protein: 5.8,  carbs: 30.0, fat: 0.7,  defaultServingG: 200,
                   aliases: ["sushi", "roll", "maki", "nigiri"]),
        FoodMacros(name: "Taco",     calories: 226, protein: 9.0,  carbs: 20.0, fat: 12.0, defaultServingG: 80,
                   aliases: ["taco", "burrito", "quesadilla"]),

        // MARK: - Protein
        FoodMacros(name: "Chicken",  calories: 165, protein: 31.0, carbs: 0.0,  fat: 3.6,  defaultServingG: 100,
                   aliases: ["chicken", "poultry", "grilled chicken", "chicken breast"]),
        FoodMacros(name: "Fish",     calories: 206, protein: 22.0, carbs: 0.0,  fat: 12.0, defaultServingG: 100,
                   aliases: ["fish", "seafood", "salmon", "tuna", "cod", "tilapia"]),
        FoodMacros(name: "Egg",      calories: 155, protein: 13.0, carbs: 1.1,  fat: 11.0, defaultServingG: 50,
                   aliases: ["egg", "omelette", "omelet", "boiled egg", "scrambled eggs"]),
        FoodMacros(name: "Beef",     calories: 250, protein: 26.0, carbs: 0.0,  fat: 15.0, defaultServingG: 100,
                   aliases: ["beef", "steak", "ground beef"]),
        FoodMacros(name: "Pork",     calories: 242, protein: 27.0, carbs: 0.0,  fat: 14.0, defaultServingG: 100,
                   aliases: ["pork", "bacon", "ham"]),
        FoodMacros(name: "Tofu",     calories: 76,  protein: 8.0,  carbs: 1.9,  fat: 4.8,  defaultServingG: 100,
                   aliases: ["tofu", "bean curd"]),
        FoodMacros(name: "Shrimp",   calories: 99,  protein: 24.0, carbs: 0.2,  fat: 0.3,  defaultServingG: 100,
                   aliases: ["shrimp", "prawn"]),

        // MARK: - Carbs & grains
        FoodMacros(name: "Oats",     calories: 389, protein: 16.9, carbs: 66.3, fat: 6.9,  defaultServingG: 40,
                   aliases: ["oats", "oatmeal", "porridge"]),
        FoodMacros(name: "Quinoa",   calories: 120, protein: 4.4,  carbs: 21.3, fat: 1.9,  defaultServingG: 150,
                   aliases: ["quinoa"]),
        FoodMacros(name: "Potato",   calories: 77,  protein: 2.0,  carbs: 17.0, fat: 0.1,  defaultServingG: 150,
                   aliases: ["potato", "aloo", "mashed potato"]),
        FoodMacros(name: "Sweet potato", calories: 86, protein: 1.6, carbs: 20.1, fat: 0.1, defaultServingG: 150,
                   aliases: ["sweet potato", "yam"]),
        FoodMacros(name: "French fries", calories: 312, protein: 3.4, carbs: 41.0, fat: 15.0, defaultServingG: 100,
                   aliases: ["fries", "french fries", "chips"]),

        // MARK: - Dairy & snacks
        FoodMacros(name: "Milk",     calories: 61,  protein: 3.2,  carbs: 4.8,  fat: 3.3,  defaultServingG: 250,
                   aliases: ["milk", "whole milk", "skimmed milk"]),
        FoodMacros(name: "Yogurt",   calories: 61,  protein: 3.5,  carbs: 4.7,  fat: 3.3,  defaultServingG: 150,
                   aliases: ["yogurt", "yoghurt", "curd", "greek yogurt"]),
        FoodMacros(name: "Cheese",   calories: 402, protein: 25.0, carbs: 1.3,  fat: 33.0, defaultServingG: 30,
                   aliases: ["cheese", "cheddar", "mozzarella", "parmesan"]),
        FoodMacros(name: "Butter",   calories: 717, protein: 0.9,  carbs: 0.1,  fat: 81.0, defaultServingG: 10,
                   aliases: ["butter", "ghee"]),
        FoodMacros(name: "Nuts",     calories: 607, protein: 20.0, carbs: 21.0, fat: 54.0, defaultServingG: 30,
                   aliases: ["nuts", "almond", "cashew", "peanut", "walnut", "pistachio"]),
        FoodMacros(name: "Peanut butter", calories: 588, protein: 25.0, carbs: 20.0, fat: 50.0, defaultServingG: 32,
                   aliases: ["peanut butter", "pb"]),
        FoodMacros(name: "Chocolate", calories: 546, protein: 4.9, carbs: 60.0, fat: 31.0, defaultServingG: 30,
                   aliases: ["chocolate", "dark chocolate", "milk chocolate"]),
        FoodMacros(name: "Ice cream", calories: 207, protein: 3.5, carbs: 24.0, fat: 11.0, defaultServingG: 100,
                   aliases: ["ice cream", "gelato"]),
        FoodMacros(name: "Cookie",   calories: 502, protein: 5.7, carbs: 64.0,  fat: 25.0, defaultServingG: 25,
                   aliases: ["cookie", "biscuit"]),
        FoodMacros(name: "Cake",     calories: 350, protein: 4.9, carbs: 50.0,  fat: 15.0, defaultServingG: 90,
                   aliases: ["cake", "cupcake"]),
        FoodMacros(name: "Croissant", calories: 406, protein: 8.2, carbs: 45.8, fat: 21.0, defaultServingG: 60,
                   aliases: ["croissant"]),
        FoodMacros(name: "Donut",    calories: 452, protein: 4.9, carbs: 51.0, fat: 25.0,  defaultServingG: 60,
                   aliases: ["glazed donut", "krispy kreme"]),

        // MARK: - Fruit & veg
        FoodMacros(name: "Banana",   calories: 89,  protein: 1.1,  carbs: 22.8, fat: 0.3,  defaultServingG: 120,
                   aliases: ["banana"]),
        FoodMacros(name: "Apple",    calories: 52,  protein: 0.3,  carbs: 14.0, fat: 0.2,  defaultServingG: 180,
                   aliases: ["apple"]),
        FoodMacros(name: "Orange",   calories: 47,  protein: 0.9,  carbs: 12.0, fat: 0.1,  defaultServingG: 150,
                   aliases: ["orange", "tangerine"]),
        FoodMacros(name: "Grapes",   calories: 69,  protein: 0.7,  carbs: 18.0, fat: 0.2,  defaultServingG: 100,
                   aliases: ["grapes"]),
        FoodMacros(name: "Mango",    calories: 60,  protein: 0.8,  carbs: 15.0, fat: 0.4,  defaultServingG: 150,
                   aliases: ["mango"]),
        FoodMacros(name: "Strawberry", calories: 33, protein: 0.7, carbs: 7.7, fat: 0.3,   defaultServingG: 100,
                   aliases: ["strawberry", "berries", "berry"]),
        FoodMacros(name: "Watermelon", calories: 30, protein: 0.6, carbs: 7.6, fat: 0.2,   defaultServingG: 150,
                   aliases: ["watermelon"]),
        FoodMacros(name: "Avocado",  calories: 160, protein: 2.0,  carbs: 8.5,  fat: 15.0, defaultServingG: 100,
                   aliases: ["avocado", "guacamole"]),
        FoodMacros(name: "Broccoli", calories: 34,  protein: 2.8,  carbs: 6.6,  fat: 0.4,  defaultServingG: 100,
                   aliases: ["broccoli"]),
        FoodMacros(name: "Spinach",  calories: 23,  protein: 2.9,  carbs: 3.6,  fat: 0.4,  defaultServingG: 80,
                   aliases: ["spinach", "palak"]),
        FoodMacros(name: "Carrot",   calories: 41,  protein: 0.9,  carbs: 10.0, fat: 0.2,  defaultServingG: 80,
                   aliases: ["carrot"]),
        FoodMacros(name: "Tomato",   calories: 18,  protein: 0.9,  carbs: 3.9,  fat: 0.2,  defaultServingG: 100,
                   aliases: ["tomato"]),

        // MARK: - Drinks
        FoodMacros(name: "Coke",     calories: 42,  protein: 0.0,  carbs: 10.6, fat: 0.0,  defaultServingG: 330,
                   aliases: ["coke", "cola", "pepsi", "soda", "soft drink"]),
        FoodMacros(name: "Orange juice", calories: 45, protein: 0.7, carbs: 10.4, fat: 0.2, defaultServingG: 250,
                   aliases: ["orange juice", "oj"]),
        FoodMacros(name: "Coffee",   calories: 2,   protein: 0.3,  carbs: 0.0,  fat: 0.0,  defaultServingG: 240,
                   aliases: ["coffee", "black coffee", "espresso"]),
        FoodMacros(name: "Latte",    calories: 42,  protein: 2.2,  carbs: 3.4,  fat: 2.3,  defaultServingG: 350,
                   aliases: ["latte", "cappuccino", "flat white"]),
        FoodMacros(name: "Beer",     calories: 43,  protein: 0.5,  carbs: 3.6,  fat: 0.0,  defaultServingG: 350,
                   aliases: ["beer", "lager"]),
        FoodMacros(name: "Wine",     calories: 83,  protein: 0.1,  carbs: 2.7,  fat: 0.0,  defaultServingG: 150,
                   aliases: ["wine", "red wine", "white wine"]),
        FoodMacros(name: "Protein shake", calories: 100, protein: 20.0, carbs: 5.0, fat: 1.0, defaultServingG: 300,
                   aliases: ["protein shake", "whey", "protein powder"]),
        FoodMacros(name: "Tea",      calories: 1,   protein: 0.0,  carbs: 0.3,  fat: 0.0,  defaultServingG: 240,
                   aliases: ["tea", "chai", "green tea", "black tea"]),
        FoodMacros(name: "Smoothie", calories: 60,  protein: 1.0,  carbs: 14.0, fat: 0.3,  defaultServingG: 300,
                   aliases: ["smoothie", "fruit smoothie"]),

        // MARK: - More proteins
        FoodMacros(name: "Turkey",   calories: 189, protein: 29.0, carbs: 0.0,  fat: 7.4,  defaultServingG: 100,
                   aliases: ["turkey", "turkey breast"]),
        FoodMacros(name: "Lamb",     calories: 294, protein: 25.0, carbs: 0.0,  fat: 21.0, defaultServingG: 100,
                   aliases: ["lamb", "mutton"]),
        FoodMacros(name: "Duck",     calories: 337, protein: 19.0, carbs: 0.0,  fat: 28.0, defaultServingG: 100,
                   aliases: ["duck"]),
        FoodMacros(name: "Sardines", calories: 208, protein: 25.0, carbs: 0.0,  fat: 11.0, defaultServingG: 60,
                   aliases: ["sardines", "sardine"]),
        FoodMacros(name: "Crab",     calories: 87,  protein: 18.0, carbs: 0.0,  fat: 1.1,  defaultServingG: 100,
                   aliases: ["crab", "crab meat"]),
        FoodMacros(name: "Lobster",  calories: 89,  protein: 19.0, carbs: 0.0,  fat: 0.9,  defaultServingG: 100,
                   aliases: ["lobster"]),
        FoodMacros(name: "Tempeh",   calories: 192, protein: 20.3, carbs: 7.6,  fat: 10.8, defaultServingG: 100,
                   aliases: ["tempeh"]),
        FoodMacros(name: "Seitan",   calories: 143, protein: 25.0, carbs: 14.0, fat: 2.0,  defaultServingG: 100,
                   aliases: ["seitan", "wheat meat"]),
        FoodMacros(name: "Chickpeas", calories: 164, protein: 8.9, carbs: 27.0, fat: 2.6,  defaultServingG: 100,
                   aliases: ["chickpeas", "garbanzo"]),
        FoodMacros(name: "Black beans", calories: 132, protein: 8.9, carbs: 24.0, fat: 0.5, defaultServingG: 100,
                   aliases: ["black beans", "beans"]),
        FoodMacros(name: "Cottage cheese", calories: 98, protein: 11.0, carbs: 3.4, fat: 4.3, defaultServingG: 100,
                   aliases: ["cottage cheese"]),

        // MARK: - Grains & starches
        FoodMacros(name: "Bagel",    calories: 257, protein: 10.0, carbs: 51.0, fat: 1.5,  defaultServingG: 100,
                   aliases: ["bagel"]),
        FoodMacros(name: "Muffin",   calories: 424, protein: 5.0,  carbs: 55.0, fat: 20.0, defaultServingG: 80,
                   aliases: ["muffin", "blueberry muffin"]),
        FoodMacros(name: "Pancake",  calories: 227, protein: 6.4,  carbs: 28.0, fat: 9.7,  defaultServingG: 80,
                   aliases: ["pancakes", "hotcake"]),
        FoodMacros(name: "Waffle",   calories: 291, protein: 8.0,  carbs: 33.0, fat: 14.1, defaultServingG: 75,
                   aliases: ["waffle", "waffles"]),
        FoodMacros(name: "Cereal",   calories: 379, protein: 7.5,  carbs: 84.0, fat: 0.9,  defaultServingG: 40,
                   aliases: ["cereal", "corn flakes"]),
        FoodMacros(name: "Granola",  calories: 471, protein: 10.0, carbs: 64.0, fat: 20.0, defaultServingG: 40,
                   aliases: ["granola", "muesli"]),
        FoodMacros(name: "Couscous", calories: 112, protein: 3.8,  carbs: 23.0, fat: 0.2,  defaultServingG: 150,
                   aliases: ["couscous"]),
        FoodMacros(name: "Barley",   calories: 123, protein: 2.3,  carbs: 28.0, fat: 0.4,  defaultServingG: 150,
                   aliases: ["barley", "pearl barley"]),
        FoodMacros(name: "Corn",     calories: 86,  protein: 3.3,  carbs: 19.0, fat: 1.4,  defaultServingG: 100,
                   aliases: ["corn", "sweetcorn", "maize"]),
        FoodMacros(name: "Popcorn",  calories: 387, protein: 13.0, carbs: 78.0, fat: 4.5,  defaultServingG: 30,
                   aliases: ["popcorn"]),

        // MARK: - Fruits
        FoodMacros(name: "Pineapple", calories: 50, protein: 0.5, carbs: 13.0, fat: 0.1,  defaultServingG: 150,
                   aliases: ["pineapple"]),
        FoodMacros(name: "Papaya",   calories: 43,  protein: 0.5,  carbs: 11.0, fat: 0.3,  defaultServingG: 150,
                   aliases: ["papaya"]),
        FoodMacros(name: "Pear",     calories: 57,  protein: 0.4,  carbs: 15.0, fat: 0.1,  defaultServingG: 150,
                   aliases: ["pear"]),
        FoodMacros(name: "Peach",    calories: 39,  protein: 0.9,  carbs: 9.5,  fat: 0.3,  defaultServingG: 150,
                   aliases: ["peach"]),
        FoodMacros(name: "Blueberry", calories: 57, protein: 0.7, carbs: 14.0, fat: 0.3,  defaultServingG: 100,
                   aliases: ["blueberry", "blueberries"]),
        FoodMacros(name: "Raspberry", calories: 52, protein: 1.2, carbs: 12.0, fat: 0.7,  defaultServingG: 100,
                   aliases: ["raspberry", "raspberries"]),
        FoodMacros(name: "Kiwi",     calories: 61,  protein: 1.1,  carbs: 15.0, fat: 0.5,  defaultServingG: 100,
                   aliases: ["kiwi", "kiwifruit"]),
        FoodMacros(name: "Cherry",   calories: 50,  protein: 1.0,  carbs: 12.0, fat: 0.3,  defaultServingG: 100,
                   aliases: ["cherry", "cherries"]),
        FoodMacros(name: "Pomegranate", calories: 83, protein: 1.7, carbs: 19.0, fat: 1.2, defaultServingG: 100,
                   aliases: ["pomegranate", "anaar"]),
        FoodMacros(name: "Coconut",  calories: 354, protein: 3.3,  carbs: 15.0, fat: 33.0, defaultServingG: 30,
                   aliases: ["coconut"]),
        FoodMacros(name: "Dates",    calories: 277, protein: 1.8,  carbs: 75.0, fat: 0.2,  defaultServingG: 30,
                   aliases: ["dates", "date"]),
        FoodMacros(name: "Raisins",  calories: 299, protein: 3.1,  carbs: 79.0, fat: 0.5,  defaultServingG: 30,
                   aliases: ["raisins"]),

        // MARK: - Vegetables
        FoodMacros(name: "Cucumber", calories: 16,  protein: 0.7,  carbs: 3.6,  fat: 0.1,  defaultServingG: 100,
                   aliases: ["cucumber"]),
        FoodMacros(name: "Onion",    calories: 40,  protein: 1.1,  carbs: 9.3,  fat: 0.1,  defaultServingG: 80,
                   aliases: ["onion"]),
        FoodMacros(name: "Bell pepper", calories: 31, protein: 1.0, carbs: 6.0, fat: 0.3,  defaultServingG: 100,
                   aliases: ["bell pepper", "capsicum"]),
        FoodMacros(name: "Cauliflower", calories: 25, protein: 1.9, carbs: 5.0, fat: 0.3,  defaultServingG: 100,
                   aliases: ["cauliflower", "gobi"]),
        FoodMacros(name: "Zucchini", calories: 17,  protein: 1.2,  carbs: 3.1,  fat: 0.3,  defaultServingG: 100,
                   aliases: ["zucchini", "courgette"]),
        FoodMacros(name: "Eggplant", calories: 25,  protein: 1.0,  carbs: 5.9,  fat: 0.2,  defaultServingG: 100,
                   aliases: ["eggplant", "brinjal", "aubergine"]),
        FoodMacros(name: "Mushroom", calories: 22,  protein: 3.1,  carbs: 3.3,  fat: 0.3,  defaultServingG: 80,
                   aliases: ["mushroom", "button mushroom"]),
        FoodMacros(name: "Cabbage",  calories: 25,  protein: 1.3,  carbs: 5.8,  fat: 0.1,  defaultServingG: 100,
                   aliases: ["cabbage"]),
        FoodMacros(name: "Peas",     calories: 81,  protein: 5.4,  carbs: 14.0, fat: 0.4,  defaultServingG: 80,
                   aliases: ["peas", "green peas"]),
        FoodMacros(name: "Beetroot", calories: 43,  protein: 1.6,  carbs: 9.6,  fat: 0.2,  defaultServingG: 100,
                   aliases: ["beetroot", "beet"]),

        // MARK: - Sauces & condiments
        FoodMacros(name: "Ketchup",  calories: 112, protein: 1.7,  carbs: 26.0, fat: 0.4,  defaultServingG: 17,
                   aliases: ["ketchup", "tomato sauce"]),
        FoodMacros(name: "Mayonnaise", calories: 680, protein: 1.0, carbs: 0.6, fat: 75.0, defaultServingG: 15,
                   aliases: ["mayonnaise", "mayo"]),
        FoodMacros(name: "Soy sauce", calories: 53, protein: 8.0, carbs: 4.9, fat: 0.6,   defaultServingG: 15,
                   aliases: ["soy sauce", "soya sauce"]),
        FoodMacros(name: "Hummus",   calories: 166, protein: 8.0,  carbs: 14.0, fat: 10.0, defaultServingG: 30,
                   aliases: ["hummus"]),
        FoodMacros(name: "Olive oil", calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, defaultServingG: 14,
                   aliases: ["olive oil"]),
        FoodMacros(name: "Honey",    calories: 304, protein: 0.3,  carbs: 82.0, fat: 0.0,  defaultServingG: 21,
                   aliases: ["honey"]),
        FoodMacros(name: "Sugar",    calories: 387, protein: 0.0,  carbs: 100.0, fat: 0.0, defaultServingG: 4,
                   aliases: ["sugar", "white sugar"]),
        FoodMacros(name: "Jam",      calories: 250, protein: 0.5,  carbs: 66.0, fat: 0.1,  defaultServingG: 20,
                   aliases: ["jam", "jelly", "preserve"]),

        // MARK: - Indian additions
        FoodMacros(name: "Naan",     calories: 310, protein: 9.0,  carbs: 55.0, fat: 6.0,  defaultServingG: 90,
                   aliases: ["naan"]),
        FoodMacros(name: "Pav",      calories: 274, protein: 8.5,  carbs: 51.0, fat: 3.6,  defaultServingG: 40,
                   aliases: ["pav", "pao"]),
        FoodMacros(name: "Pakora",   calories: 315, protein: 6.0,  carbs: 30.0, fat: 20.0, defaultServingG: 60,
                   aliases: ["pakora", "bhajiya", "bhaji"]),
        FoodMacros(name: "Butter chicken", calories: 155, protein: 12.0, carbs: 4.0, fat: 10.0, defaultServingG: 200,
                   aliases: ["butter chicken", "murgh makhani"]),
        FoodMacros(name: "Tikka masala", calories: 148, protein: 10.0, carbs: 6.0, fat: 9.0, defaultServingG: 200,
                   aliases: ["tikka masala", "chicken tikka"]),
        FoodMacros(name: "Palak paneer", calories: 180, protein: 8.0, carbs: 6.0, fat: 14.0, defaultServingG: 200,
                   aliases: ["palak paneer", "saag paneer"]),
        FoodMacros(name: "Gulab jamun", calories: 322, protein: 4.6, carbs: 50.0, fat: 12.0, defaultServingG: 40,
                   aliases: ["gulab jamun"]),
        FoodMacros(name: "Jalebi",   calories: 356, protein: 3.5,  carbs: 55.0, fat: 15.0, defaultServingG: 50,
                   aliases: ["jalebi"]),
        FoodMacros(name: "Kheer",    calories: 143, protein: 4.5,  carbs: 22.0, fat: 4.5,  defaultServingG: 150,
                   aliases: ["kheer", "rice pudding", "payasam"]),
        FoodMacros(name: "Lassi",    calories: 91,  protein: 3.4,  carbs: 12.0, fat: 3.0,  defaultServingG: 250,
                   aliases: ["lassi"]),

        // MARK: - Snacks & desserts
        FoodMacros(name: "Chips",    calories: 536, protein: 7.0,  carbs: 50.0, fat: 34.0, defaultServingG: 30,
                   aliases: ["chips", "crisps", "potato chips"]),
        FoodMacros(name: "Pretzels", calories: 380, protein: 10.0, carbs: 80.0, fat: 3.0,  defaultServingG: 30,
                   aliases: ["pretzels", "pretzel"]),
        FoodMacros(name: "Pop tart", calories: 400, protein: 4.0,  carbs: 74.0, fat: 10.0, defaultServingG: 52,
                   aliases: ["pop tart", "poptart"]),
        FoodMacros(name: "Brownie",  calories: 466, protein: 6.0,  carbs: 57.0, fat: 24.0, defaultServingG: 60,
                   aliases: ["brownie", "chocolate brownie"]),
        FoodMacros(name: "Cheesecake", calories: 321, protein: 5.5, carbs: 26.0, fat: 22.0, defaultServingG: 100,
                   aliases: ["cheesecake"]),
        FoodMacros(name: "Muesli bar", calories: 380, protein: 6.0, carbs: 65.0, fat: 12.0, defaultServingG: 30,
                   aliases: ["muesli bar", "granola bar", "protein bar"]),
        FoodMacros(name: "Milkshake", calories: 112, protein: 3.9, carbs: 18.0, fat: 3.0,  defaultServingG: 300,
                   aliases: ["milkshake", "shake"]),
        FoodMacros(name: "Gum",      calories: 360, protein: 0.0,  carbs: 90.0, fat: 0.0,  defaultServingG: 3,
                   aliases: ["gum", "chewing gum"]),

        // MARK: - Beverages (extra)
        FoodMacros(name: "Energy drink", calories: 45, protein: 0.0, carbs: 11.0, fat: 0.0, defaultServingG: 250,
                   aliases: ["energy drink", "red bull", "monster"]),
        FoodMacros(name: "Sports drink", calories: 24, protein: 0.0, carbs: 6.0, fat: 0.0, defaultServingG: 250,
                   aliases: ["sports drink", "gatorade", "powerade"]),
        FoodMacros(name: "Kombucha", calories: 30,  protein: 0.0,  carbs: 7.0,  fat: 0.0,  defaultServingG: 250,
                   aliases: ["kombucha"]),
        FoodMacros(name: "Almond milk", calories: 17, protein: 0.6, carbs: 0.3, fat: 1.5,  defaultServingG: 240,
                   aliases: ["almond milk"]),
        FoodMacros(name: "Oat milk", calories: 47,  protein: 1.0,  carbs: 7.0,  fat: 1.5,  defaultServingG: 240,
                   aliases: ["oat milk"]),
    ]

    static func byName(_ query: String) -> FoodMacros? {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return nil }
        if let exact = all.first(where: { $0.name.lowercased() == q }) { return exact }
        if let alias = all.first(where: { $0.aliases.contains(where: { $0 == q }) }) { return alias }
        if let sub = all.first(where: {
            $0.name.lowercased().contains(q) || q.contains($0.name.lowercased()) ||
            $0.aliases.contains(where: { q.contains($0) || $0.contains(q) })
        }) { return sub }
        return nil
    }

    /// Word-boundary scoring. Plain substring containment matched "steak"
    /// against the alias "tea" and "hamburger" against "ham".
    private static func containsPhrase(_ haystack: String, _ needle: String) -> Bool {
        guard !needle.isEmpty else { return false }
        return (" " + haystack + " ").contains(" " + needle + " ")
    }

    /// Minimum score a candidate must reach before it is accepted. Below this
    /// the caller receives `nil` and the user is asked to enter the food by
    /// hand, which is preferable to silently logging the wrong macros.
    static let minimumMatchScore: Float = 0.08

    static func bestMatch(fromLabels labels: [(label: String, confidence: Float)]) -> FoodMacros? {
        var scores: [String: Float] = [:]

        for (rawLabel, conf) in labels {
            let lower = rawLabel
                .lowercased()
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "-", with: " ")
                .trimmingCharacters(in: .whitespaces)
            if lower.isEmpty { continue }

            let tokens = Set(lower.split(separator: " ").map(String.init))

            for food in all {
                let foodNameLower = food.name.lowercased()

                // 1. The whole label is exactly the food name or an alias.
                if lower == foodNameLower || food.aliases.contains(lower) {
                    scores[food.name, default: 0] += conf * 3
                    continue
                }

                // 2. The food name appears as a whole word sequence.
                if containsPhrase(lower, foodNameLower) {
                    scores[food.name, default: 0] += conf * 2
                    continue
                }

                // 3. An alias as a whole word sequence, or a single token that is exactly
                //    an alias. This rescues multi-word labels such as "hot dog stand".
                var aliasHit: Float = 0
                for alias in food.aliases {
                    if containsPhrase(lower, alias) {
                        aliasHit = max(aliasHit, conf)
                    } else if tokens.contains(alias) {
                        aliasHit = max(aliasHit, conf * 0.8)
                    }
                }
                if aliasHit > 0 { scores[food.name, default: 0] += aliasHit }
            }
        }

        guard let best = scores.max(by: { $0.value < $1.value }),
              best.value >= minimumMatchScore else { return nil }
        return all.first { $0.name == best.key }
    }
}
