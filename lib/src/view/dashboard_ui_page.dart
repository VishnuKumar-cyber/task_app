import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../utils/path_provider.dart';

class DashboardUiPage extends StatefulWidget {
  const DashboardUiPage({super.key});

  @override
  State<DashboardUiPage> createState() => _DashboardUiPageState();
}

class _DashboardUiPageState extends State<DashboardUiPage> {
  List<Post> posts = [];
  bool isLoading = true;
  bool hasInternet = true;

  late StreamSubscription<InternetStatus> _internetListener;

  static const String cacheKey = 'cachedPosts';

  @override
  void initState() {
    super.initState();

    _internetListener = InternetConnection().onStatusChange.listen((
      InternetStatus status,
    ) {
      final connected = status == InternetStatus.connected;
      setState(() {
        hasInternet = connected;
      });
      if (connected) {
        fetchPosts();
      }
    });

    InternetConnection().hasInternetAccess.then((connected) {
      setState(() {
        hasInternet = connected;
      });
      fetchPosts();
    });
  }

  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true;
    });

    if (!hasInternet) {
      await loadFromCache();
      if (posts.isNotEmpty) {
        showLoginSuccessfulPopup();
      }
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        posts = data.map((json) => Post.fromJson(json)).toList();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, response.body);

        setState(() {
          isLoading = false;
        });
      } else {
        await loadFromCache();
        setState(() {
          isLoading = false;
        });
      }
    } catch (_) {
      await loadFromCache();
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedJson = prefs.getString(cacheKey);
    if (cachedJson != null) {
      final List<dynamic> data = json.decode(cachedJson);
      posts = data.map((json) => Post.fromJson(json)).toList();
    }
  }

  void showLoginSuccessfulPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Login Successful"),
          content: Text("You are offline. Loaded data from offline cache."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _internetListener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        automaticallyImplyLeading: false,
        actions: [
          Text("Vishnu"),
          SizedBox(width: 20),
          Text(hasInternet ? "Online" : "Offline"),
          SizedBox(width: 20),
        ],
        backgroundColor: hasInternet ? Colors.green : Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchPosts,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: posts.length,
                itemBuilder: (_, index) {
                  final post = posts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            post.body,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
