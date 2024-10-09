import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Object Detection',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color.fromARGB(255, 249, 238, 255),
      ),
      home: const ObjDetectionScreen(),
    );
  }
}

class ObjDetectionScreen extends StatelessWidget {
  const ObjDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF610A8A),
        title: const Text('Object Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // logic here
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // logic here
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF610A8A),
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(  // Wrap the content with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Container(
                height: 250,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.camera_alt,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 100,
                color: const Color.fromARGB(255, 238, 213, 253),
                child: const Center(
                  child: Text(
                    'Text generated from obj detection',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:  const Color(0xFF610A8A),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
      ),
    );
  }

}