import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Models
class Recipe {
  final String id;
  final String title;
  final List<Ingredient> ingredients;

  Recipe({required this.id, required this.title, required this.ingredients});
}

class Ingredient {
  final String name;

  Ingredient({required this.name});
}

// Repository
class MemoryRepository {
  final List<Recipe> _recipes = [
    Recipe(
      id: '1',
      title: 'Spaghetti',
      ingredients: [Ingredient(name: 'Pasta'), Ingredient(name: 'Tomato Sauce')],
    ),
    Recipe(
      id: '2',
      title: 'Salad',
      ingredients: [Ingredient(name: 'Lettuce'), Ingredient(name: 'Dressing')],
    ),
  ];

  final _recipeStreamController = StreamController<List<Recipe>>();
  final _ingredientStreamController = StreamController<List<Ingredient>>();

  MemoryRepository() {
    // Emit initial data
    _recipeStreamController.sink.add(_recipes);
    _ingredientStreamController.sink
        .add(_recipes.expand((recipe) => recipe.ingredients).toList());
  }

  Stream<List<Recipe>> get recipeStream =>
      _recipeStreamController.stream.asBroadcastStream();

  Stream<List<Ingredient>> get ingredientStream =>
      _ingredientStreamController.stream.asBroadcastStream();

  Future<void> addRecipe(Recipe recipe) async {
    _recipes.add(recipe);
    _recipeStreamController.sink.add(_recipes);
    _ingredientStreamController.sink
        .add(_recipes.expand((recipe) => recipe.ingredients).toList());
  }

  void dispose() {
    _recipeStreamController.close();
    _ingredientStreamController.close();
  }
}

// Main App
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RecipeScreen(),
    );
  }
}

// Recipe Screen
class RecipeScreen extends StatefulWidget {
  const RecipeScreen({Key? key}) : super(key: key);

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final MemoryRepository repository = MemoryRepository();

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: StreamBuilder<List<Recipe>>(
        stream: repository.recipeStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final recipes = snapshot.data ?? [];
          if (recipes.isEmpty) {
            return const Center(child: Text('No recipes available.'));
          }
          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return ListTile(
                title: Text(recipe.title),
                subtitle:
                    Text('${recipe.ingredients.length} ingredients available'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add a new recipe
          final newRecipe = Recipe(
            id: DateTime.now().toString(),
            title: 'New Recipe ${DateTime.now().millisecondsSinceEpoch}',
            ingredients: [
              Ingredient(name: 'Ingredient 1'),
              Ingredient(name: 'Ingredient 2'),
            ],
          );
          repository.addRecipe(newRecipe);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
