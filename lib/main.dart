import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late BehaviorSubject<List<int>> _dataSubject;
  late ScrollController _scrollController;
  final int _perPage = 100;
  int _counter = 0;

  // Add TextEditingController to control the text of the TextField
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dataSubject = BehaviorSubject<List<int>>();
    _scrollController = ScrollController()
      ..addListener(_scrollListener);
    loadData();
  }

  @override
  void dispose() {
    _dataSubject.close();
    _scrollController.dispose();
    super.dispose();
  }

  void loadData() {
    // Simulating loading data asynchronously
    Future.delayed(const Duration(seconds: 2), () {
      // Generate a new list of integers. The amount of data generated is always _perPage.
      // The value of each item is calculated as _counter * _perPage + index + 1, which ensures that each batch of items starts where the last one left off.
      final newData = List.generate(
          _perPage, (index) => _counter * _perPage + index + 1);
      // Get the current data from _dataSubject. If _dataSubject is null, use an empty list.
      final currentData = _dataSubject.valueOrNull ?? [];
      // Add the new data to the current data and update _dataSubject.
      _dataSubject.add(currentData + newData);
      // Increment _counter for pagination. This will affect the starting point of the data generated in the next load.
      _counter++;
    });
  }

  void _scrollListener() {
    if (_scrollController.offset >=
        _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      // Reached the end, load more data
      loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Infinite Scroll Example'),
          actions: <Widget>[
            Expanded(
              // Add a TextField to the AppBar for user input
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    contentPadding: EdgeInsets.all(10),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                )
            ),
          ]
      ),
      body: StreamBuilder<List<int>>(
        stream: _dataSubject.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data!;
            // Filter the data based on the search query
            // If the search field is empty, display all items
            // If it's not, filter the items based on the search query
            // The filtering is case-insensitive and allows partial matches
            final filteredData = _searchController.text.isEmpty
                ? data
                : data.where((item) => 'Item $item'.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

            return NotificationListener<ScrollNotification>(
              // Listen for scroll events.
              onNotification: (ScrollNotification scrollInfo) {
                // If the user has scrolled to the end of the list, load more data.
                if (scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent) {
                  loadData();
                }
                // Return false to allow the notification to continue to be dispatched to further ancestors.
                return false;
              },
              child: ListView.builder(
                // Use the length of the filtered data to determine the itemCount
                // The total item count is the length of the data list plus 1 for the loading indicator if there's more data to load.
                itemCount: filteredData.length + (_counter > 1 ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < filteredData.length) {
                    // Build a list item for each item in the filtered data
                    return ListTile(
                      title: Text('Item ${filteredData[index]}'),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}