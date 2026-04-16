import 'package:flutter/material.dart';
import 'moderator_queue.dart';

class ModeratorDashboard extends StatelessWidget {
  const ModeratorDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEEF4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/panikasog-logo.png', height: 30), // optional logo
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {},
            child: const CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/150'), // replace
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFE91E63),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/moderator_queue');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'Queue'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Moderator’s Dashboard",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Dashboard stats
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildDashboardCard(
                    icon: Icons.people,
                    label: 'Active Volunteers',
                    value: '342',
                    trendUp: true),
                _buildDashboardCard(
                    icon: Icons.check_circle,
                    label: 'Task Completed',
                    value: '342',
                    trendUp: true),
                _buildDashboardCard(
                    icon: Icons.warning,
                    label: 'Hazard Reports',
                    value: '342',
                    trendUp: false),
                _buildDashboardCard(
                    icon: Icons.chat,
                    label: 'Community Posts',
                    value: '342',
                    trendUp: true),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('Tasks', count: 21),
            _buildTaskCard('Medical Assistance for Injured Individuals - Brgy. Rizal'),

            const SizedBox(height: 16),
            _buildSectionTitle('Community Posts', count: 54),
            _buildPostCard(context,
                title: 'Community Cleanup Drive',
                user: '@juan_org',
                location: 'Brgy. Malinis, Iloilo City',
                likes: 1267,
                comments: 45),

            const SizedBox(height: 16),
            _buildSectionTitle('Reports', count: 12),
            _buildReportCard(
                'Fallen Electricity Pole', 'Electricity', 'Power Outage'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required String value,
    required bool trendUp,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: trendUp ? Colors.green : Colors.red.shade700, size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {int? count}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$title ${count != null ? "($count)" : ""}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () {}, child: const Text('Verify')),
      ],
    );
  }

  Widget _buildTaskCard(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('URGENT', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context,
      {required String title,
      required String user,
      required String location,
      required int likes,
      required int comments}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(location, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Our community cleanup drive was a huge success! 🌟'),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.thumb_up, size: 18, color: Colors.pink.shade400),
              const SizedBox(width: 4),
              Text('$likes'),
              const SizedBox(width: 16),
              Icon(Icons.comment, size: 18, color: Colors.purple.shade400),
              const SizedBox(width: 4),
              Text('$comments'),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade400,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/moderator_queue');
                },
                child: const Text('Review'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String tag1, String tag2) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _buildTag(tag1),
            const SizedBox(width: 8),
            _buildTag(tag2),
          ])
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}
