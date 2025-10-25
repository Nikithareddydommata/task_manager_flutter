/*
Task Manager – Flutter Web App
──────────────────────────────────────────────
✅ Sign Up + Sign In (local, offline)
✅ Tabs: Home, About, Services, Notifications, Contact Us, Tasks
✅ Works on Web + Mobile
Dependencies:
  shared_preferences: ^2.2.3
  url_launcher: ^6.3.0
*/

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF6750A4),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: theme,
      home: const AuthGate(),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// AUTH GATE (Sign In / Sign Up + local storage)
////////////////////////////////////////////////////////////////////////////////
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _authed = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tm_auth');
    setState(() {
      _authed = token != null;
      _loading = false;
    });
  }

  void _onSignedIn() => setState(() => _authed = true);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _authed ? const Shell() : AuthScreen(onSignedIn: _onSignedIn);
  }
}

class AuthScreen extends StatefulWidget {
  final VoidCallback onSignedIn;
  const AuthScreen({super.key, required this.onSignedIn});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _remember = true;
  bool _busy = false;
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  final _confirm = TextEditingController();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();

    if (_isSignUp) {
      await prefs.setString('tm_user', _email.text.trim());
      await prefs.setString('tm_pass', _pwd.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-up successful! Please sign in.')),
      );
      setState(() => _isSignUp = false);
    } else {
      final u = prefs.getString('tm_user');
      final p = prefs.getString('tm_pass');
      if (u == _email.text.trim() && p == _pwd.text.trim()) {
        if (_remember) await prefs.setString('tm_auth', 'ok');
        widget.onSignedIn();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
      }
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const _Mark(size: 36),
                        const SizedBox(width: 8),
                        Text('Task Manager', style: t.textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter email';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)
                            ? null
                            : 'Invalid email';
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pwd,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (v) =>
                          v != null && v.length >= 6 ? null : 'Min 6 chars',
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) =>
                            v == _pwd.text ? null : 'Passwords don’t match',
                      ),
                    ],
                    CheckboxListTile(
                      value: _remember,
                      onChanged: (v) => setState(() => _remember = v ?? true),
                      title: const Text('Remember me'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _submit,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(_isSignUp ? Icons.person_add : Icons.login),
                        label: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign In'
                            : 'No account? Sign Up',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// MAIN SHELL + TABS
////////////////////////////////////////////////////////////////////////////////
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;
  final _pages = const [
    HomeTab(),
    AboutTab(),
    ServicesTab(),
    NotificationsTab(),
    ContactTab(),
    TasksTab(),
  ];
  final _titles = const [
    'Home',
    'About',
    'Services',
    'Notifications',
    'Contact Us',
    'Tasks',
  ];

  Future<void> _logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('tm_auth');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    final navItems = const [
      NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.info), label: 'About'),
      NavigationDestination(icon: Icon(Icons.handyman), label: 'Services'),
      NavigationDestination(icon: Icon(Icons.notifications), label: 'Updates'),
      NavigationDestination(icon: Icon(Icons.contacts), label: 'Contact'),
      NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
    ];

    final content = Scaffold(
      appBar: AppBar(
        title: Text('Task Manager • ${_titles[_index]}'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: navItems,
            ),
    );

    if (!isWide) return content;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.only(top: 16),
              child: _Mark(size: 28),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.info),
                label: Text('About'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.handyman),
                label: Text('Services'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.notifications),
                label: Text('Updates'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.contacts),
                label: Text('Contact'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.checklist),
                label: Text('Tasks'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// HOME TAB
////////////////////////////////////////////////////////////////////////////////
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Welcome to Task Manager!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Organize work, hit deadlines, and collaborate effectively. Manage tasks across devices with ease.',
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// ABOUT TAB
////////////////////////////////////////////////////////////////////////////////
class AboutTab extends StatelessWidget {
  const AboutTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Us',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'We are the team behind the Task Manager App, committed to delivering seamless productivity tools to help users manage their tasks efficiently.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Text(
            'Meet Our Team',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              TeamMemberCard(
                name: 'Nikitha',
                role: 'CEO',
                imageUrl: 'https://i.ibb.co/SWkfyFD/photo.jpg',
              ),
              TeamMemberCard(
                name: 'Sucharitha',
                role: 'CTO',
                imageUrl: 'https://i.ibb.co/xKWqFP5Z/suc.jpg',
              ),
              TeamMemberCard(
                name: 'Sriram',
                role: 'COO',
                imageUrl: 'https://i.ibb.co/qLRBmJzk/sri.jpg',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TeamMemberCard extends StatelessWidget {
  final String name;
  final String role;
  final String imageUrl;

  const TeamMemberCard({
    required this.name,
    required this.role,
    required this.imageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipOval(
          child: Image.network(
            imageUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.person, size: 100, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(role, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// SERVICES, NOTIFICATIONS, CONTACT, TASKS, LOGO (no changes)
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// SERVICES TAB
////////////////////////////////////////////////////////////////////////////////
class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.dashboard_customize),
          title: Text('Project Boards'),
          subtitle: Text('Kanban boards for organizing tasks.'),
        ),
        ListTile(
          leading: Icon(Icons.people),
          title: Text('Team Collaboration'),
          subtitle: Text('Comments and real-time updates.'),
        ),
        ListTile(
          leading: Icon(Icons.analytics),
          title: Text('Analytics & Reports'),
          subtitle: Text('Track progress and deadlines.'),
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// NOTIFICATIONS TAB
////////////////////////////////////////////////////////////////////////////////
class NotificationsTab extends StatefulWidget {
  const NotificationsTab({super.key});
  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  List<Map<String, String>> notifs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(
      () => notifs = [
        {'date': 'Oct 12 2025', 'msg': 'Task Manager Web launched!'},
        {'date': 'Oct 08 2025', 'msg': 'Added Recurring Tasks.'},
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => notifs.clear()),
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: notifs.isEmpty
                ? const Center(child: Text('No notifications'))
                : ListView.builder(
                    itemCount: notifs.length,
                    itemBuilder: (_, i) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.notifications_active_outlined,
                        ),
                        title: Text(notifs[i]['msg']!),
                        subtitle: Text(notifs[i]['date']!),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// CONTACT TAB
////////////////////////////////////////////////////////////////////////////////
class ContactTab extends StatelessWidget {
  const ContactTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Contact Us',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text('#21 Tech Park Road, Hitech City, Hyderabad 500081 India'),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => launchUrl(Uri.parse('tel:+919876543210')),
          icon: const Icon(Icons.call),
          label: const Text('+91 98765 43210'),
        ),
        TextButton.icon(
          onPressed: () =>
              launchUrl(Uri.parse('mailto:support@taskmanager.com')),
          icon: const Icon(Icons.email_outlined),
          label: const Text('support@taskmanager.com'),
        ),
        TextButton.icon(
          onPressed: () => launchUrl(
            Uri.parse('https://maps.google.com/?q=Hitech%20City%20Hyderabad'),
          ),
          icon: const Icon(Icons.location_pin),
          label: const Text('View on Google Maps'),
        ),
      ],
    );
  }
}

////////////////////////////////////////////////////////////////////////////////
// TASKS TAB  (CRUD + local save)
////////////////////////////////////////////////////////////////////////////////
class TasksTab extends StatefulWidget {
  const TasksTab({super.key});
  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  List<Task> tasks = [];
  final _title = TextEditingController();
  final _notes = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('tm_tasks');
    tasks = raw == null
        ? []
        : (jsonDecode(raw) as List).map((e) => Task.fromJson(e)).toList();
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      'tm_tasks',
      jsonEncode(tasks.map((e) => e.toJson()).toList()),
    );
    setState(() {});
  }

  void _add() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _title.clear();
              _notes.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_title.text.isEmpty) return;
              tasks.insert(0, Task(_title.text, _notes.text));
              _title.clear();
              _notes.clear();
              Navigator.pop(context);
              _save();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggle(Task t) {
    setState(() => t.done = !t.done);
    _save();
  }

  void _delete(Task t) {
    setState(() => tasks.remove(t));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FilledButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('New Task'),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No tasks yet'))
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (_, i) {
                      final t = tasks[i];
                      return Card(
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(
                              t.done
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: t.done ? Colors.green : null,
                            ),
                            onPressed: () => _toggle(t),
                          ),
                          title: Text(
                            t.title,
                            style: TextStyle(
                              decoration:
                                  t.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: t.notes.isEmpty ? null : Text(t.notes),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(t),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class Task {
  String title;
  String notes;
  bool done;
  Task(this.title, this.notes, {this.done = false});
  Map<String, dynamic> toJson() => {'t': title, 'n': notes, 'd': done};
  static Task fromJson(Map<String, dynamic> m) =>
      Task(m['t'], m['n'] ?? '', done: m['d'] ?? false);
}

////////////////////////////////////////////////////////////////////////////////
// SIMPLE LOGO MARK
////////////////////////////////////////////////////////////////////////////////
class _Mark extends StatelessWidget {
  final double size;
  const _Mark({required this.size});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MarkPainter());
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFF6750A4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.12;
    final path = Path();
    final w = s.width, h = s.height;
    path.moveTo(w * 0.15, h * 0.55);
    path.lineTo(w * 0.40, h * 0.80);
    path.lineTo(w * 0.85, h * 0.25);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
