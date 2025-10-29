import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(RandomChoiceApp());
}

class RandomChoiceApp extends StatefulWidget {
  RandomChoiceApp({Key? key}) : super(key: key);

  @override
  State<RandomChoiceApp> createState() => _RandomChoiceAppState();
}

class _RandomChoiceAppState extends State<RandomChoiceApp> {
  ThemeMode _themeMode = ThemeMode.dark; // по умолчанию тёмная тема

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Случайный Выбор',
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.indigo),
      darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.indigo),
      themeMode: _themeMode,
      home: HomePage(onToggleTheme: toggleTheme),
    );
  }
}

class ApiConfig {
  // Если пользователь явно установил URL — используем его.
  static String? _override;

  static String get baseUrl {
    if (_override != null && _override!.isNotEmpty) return _override!;
    // web: оставим локальный IP по умолчанию (можно менять в настройках)
    if (kIsWeb) return 'http://192.168.0.108:8000';
    try {
      if (Platform.isAndroid) {
        // Если запущено в Android (эмулятор): 10.0.2.2 маппит на хост
        return 'http://10.0.2.2:8000';
      }
      if (Platform.isIOS) {
        // iOS симулятор может использовать localhost
        return 'http://127.0.0.1:8000';
      }
    } catch (_) {}
    // По умолчанию используем локальный IP машины (подставьте ваш адрес)
    return 'http://192.168.0.108:8000';
  }

  static void setBaseUrl(String url) {
    _override = url;
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  HomePage({Key? key, this.onToggleTheme}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> lists = [];
  final _ctrl = TextEditingController();
  bool loading = false;
  String? error;
  bool _fadeIn = false;

  @override
  void initState() {
    super.initState();
    loadLists();
  }

  Future<void> loadLists() async {
    setState(() {
      loading = true;
      error = null;
      _fadeIn = false;
    });
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/lists'));
      if (res.statusCode == 200) {
        lists = json.decode(res.body);
        // включаем простую анимацию появления
        Future.delayed(Duration(milliseconds: 50), () {
          setState(() => _fadeIn = true);
        });
      } else {
        error = 'Ошибка сервера: ${res.statusCode}';
      }
    } catch (e) {
      error = 'Не удалось подключиться';
    }
    setState(() => loading = false);
  }

  Future<void> addList() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    try {
      final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/lists'),
          headers: {'Content-Type': 'application/json'}, body: json.encode({'name': name}));
      if (res.statusCode == 200) {
        _ctrl.clear();
        await loadLists();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: ${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> deleteList(int id) async {
    try {
      await http.delete(Uri.parse('${ApiConfig.baseUrl}/lists/$id'));
      await loadLists();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  void openSettings() {
    final c = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Настройки'),
              content: TextField(
                controller: c,
                decoration: InputDecoration(labelText: 'API URL'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Отмена')),
                TextButton(
                    onPressed: () {
                      ApiConfig.setBaseUrl(c.text.trim());
                      Navigator.pop(context);
                      loadLists();
                    },
                    child: Text('Сохранить'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Случайный Выбор'),
        actions: [
          IconButton(onPressed: openSettings, icon: Icon(Icons.settings)),
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(hintText: 'Новый список'),
                    onSubmitted: (_) => addList(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: addList, child: Text('Добавить'))
              ],
            ),
            SizedBox(height: 12),
            if (loading) Expanded(child: Center(child: CircularProgressIndicator()))
            else if (error != null) Expanded(child: Center(child: Text(error!)))
            else if (lists.isEmpty)
              Expanded(child: Center(child: Text('Нет списков')))
            else
              Expanded(
                child: AnimatedOpacity(
                  opacity: _fadeIn ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: ListView.builder(
                    itemCount: lists.length,
                    itemBuilder: (_, i) {
                      final it = lists[i];
                      return ListTile(
                        title: Text(it['name']),
                        subtitle: Text('ID: ${it['id']}'),
                        trailing: IconButton(icon: Icon(Icons.delete), onPressed: () => deleteList(it['id'])),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ListDetailPage(listId: it['id'], listName: it['name']))).then((_) => loadLists()),
                      );
                    },
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class ListDetailPage extends StatefulWidget {
  final int listId;
  final String listName;
  const ListDetailPage({Key? key, required this.listId, required this.listName}) : super(key: key);

  @override
  State<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends State<ListDetailPage> {
  List<dynamic> choices = [];
  final _ctrl = TextEditingController();
  bool loading = false;
  String result = '';
  bool _resultVisible = false;

  @override
  void initState() {
    super.initState();
    loadChoices();
  }

  Future<void> loadChoices() async {
    setState(() => loading = true);
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/lists/${widget.listId}/choices'));
      if (res.statusCode == 200) {
        choices = json.decode(res.body);
      }
    } catch (e) {}
    setState(() => loading = false);
  }

  Future<void> addChoice() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    try {
      final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/lists/${widget.listId}/choices'),
          headers: {'Content-Type': 'application/json'}, body: json.encode({'text': text}));
      if (res.statusCode == 200) {
        _ctrl.clear();
        await loadChoices();
      }
    } catch (e) {}
  }

  Future<void> deleteChoice(int id) async {
    try {
      await http.delete(Uri.parse('${ApiConfig.baseUrl}/choices/$id'));
      await loadChoices();
      setState(() => result = '');
    } catch (e) {}
  }

  Future<void> pick() async {
    if (choices.isEmpty) return;
    try {
      final res = await http.post(Uri.parse('${ApiConfig.baseUrl}/lists/${widget.listId}/pick'));
      if (res.statusCode == 200) {
        final it = json.decode(res.body);
        setState(() {
          result = it['text'];
          _resultVisible = true;
        });
        // скрыть результат через несколько секунд (простая анимация)
        Future.delayed(Duration(seconds: 5), () {
          if (mounted) setState(() => _resultVisible = false);
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.listName)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(controller: _ctrl, decoration: InputDecoration(hintText: 'Новый вариант')),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: addChoice, child: Text('Добавить'))
              ],
            ),
            SizedBox(height: 12),
            if (loading) Expanded(child: Center(child: CircularProgressIndicator()))
            else if (choices.isEmpty)
              Expanded(child: Center(child: Text('Нет вариантов')))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: choices.length,
                  itemBuilder: (_, i) {
                    final c = choices[i];
                    return ListTile(
                      title: Text(c['text']),
                      trailing: IconButton(onPressed: () => deleteChoice(c['id']), icon: Icon(Icons.delete)),
                    );
                  },
                ),
              ),
            SizedBox(height: 12),
            ElevatedButton(onPressed: pick, child: Text('Случайный выбор')),
            AnimatedOpacity(
              opacity: _resultVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  color: Colors.amber.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Выбрано: $result', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}