import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../models/brewing_method.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import 'about_screen.dart';
import 'package:auto_route/auto_route.dart';
import '../app_router.gr.dart';
import "package:universal_html/html.dart" as html;
import '../utils/icon_utils.dart';
import '../purchase_manager.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (kIsWeb) {
      html.document.title = 'Escoffee App';
    }
    // Initialize the purchase manager and set up the callback
    PurchaseManager().initialize();
    PurchaseManager().deliverProductCallback = (details) {
      _showThankYouPopup(details);
    };
  }

  // Method to show the popup
  void _showThankYouPopup(PurchaseDetails details) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Thank You!"),
          content: const Text(
              "I really appreciate your support! Wish you a lot of great brews! ☕️"),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && kIsWeb) {
      html.document.title = 'Escoffee App';
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final brewingMethods = Provider.of<List<BrewingMethod>>(context);

    return Scaffold(
      appBar: buildPlatformSpecificAppBar(),
      body: FutureBuilder<Recipe?>(
        future: recipeProvider.getLastUsedRecipe(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          Recipe? mostRecentRecipe = snapshot.data;

          return Column(
            children: [
              if (mostRecentRecipe != null)
                ListTile(
                  leading:
                      getIconByBrewingMethod(mostRecentRecipe.brewingMethodId),
                  title: Text(
                      'Receta usada recientemente: ${mostRecentRecipe.name}'),
                  onTap: () {
                    context.router.push(RecipeDetailRoute(
                        brewingMethodId: mostRecentRecipe.brewingMethodId,
                        recipeId: mostRecentRecipe.id));
                  },
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: brewingMethods.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading: getIconByBrewingMethod(brewingMethods[index]
                          .id), // Use the brewing method id from the list
                      title: Text(brewingMethods[index].name),
                      onTap: () {
                        context.router.push(RecipeListRoute(
                            brewingMethodId: brewingMethods[index].id));
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Cambia el color a tu preferencia
                  ),
                  child: const Text('Consejos para preparar café'),
                  onPressed: () {
                    context.router.push(const CoffeeTipsRoute());
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget buildPlatformSpecificAppBar() {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return CupertinoNavigationBar(
        middle: const Text('EsCoffee',
            style: TextStyle(fontFamily: kIsWeb ? 'Lato' : null)),
        trailing: IconButton(
          icon: const Icon(Icons.info),
          onPressed: () {
            context.router.push(const AboutRoute());
          },
        ),
      );
    } else {
      return AppBar(
        title: Image.asset('assets/logoapp.png', fit: BoxFit.contain),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      );
    }
  }
}
