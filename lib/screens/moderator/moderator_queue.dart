import 'package:flutter/material.dart';

class ModeratorQueue extends StatefulWidget {
  const ModeratorQueue({Key? key}) : super(key: key);

  @override
  State<ModeratorQueue> createState() => _ModeratorQueueScreenState();
}

class _ModeratorQueueScreenState extends State<ModeratorQueue>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEEF4),
      appBar: AppBar(
        title: const Text("Moderator Queue",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE91E63),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Posts"),
            Tab(text: "Tasks"),
            Tab(text: "Reports"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostList(),
          _buildTaskList(),
          _buildReportList(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE91E63),
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'Queue'),
        ],
      ),
    );
  }

  Widget _buildPostList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildPostCard(context),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => _buildTaskCard(),
    );
  }

  Widget _buildReportList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => _buildReportCard(),
    );
  }

  Widget _buildPostCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: const Text("Successful Cleanup Drive"),
        subtitle: const Text("@juan_org • 2 mins ago"),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400),
          onPressed: () {
            _showReviewDialog(context, "post");
          },
          child: const Text('Review'),
        ),
      ),
    );
  }

  Widget _buildTaskCard() {
    return Card(
      child: ListTile(
        title: const Text("Medical Assistance - Brgy. Rizal"),
        subtitle: const Text("3 mins ago • Pending Review"),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400),
          child: const Text('Review'),
        ),
      ),
    );
  }

  Widget _buildReportCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.flash_on, color: Colors.orange),
        title: const Text("Fallen Electricity Pole"),
        subtitle: const Text("Brgy. San Juan, Molo, Iloilo City"),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400),
          child: const Text('Review'),
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, String type) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Accept Post?"),
        content: const Text(
            "Are you sure you would like to accept this post into the system?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Yes, accept post')),
        ],
      ),
    );
  }
}
