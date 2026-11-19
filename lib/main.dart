import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/profit_record.dart';
import 'pages/calculator_page.dart';
import 'pages/comparison_page.dart';
import 'pages/history_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const EcomProfitApp());
}

class EcomProfitApp extends StatelessWidget {
  const EcomProfitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '电商成本与利润分析',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // 深邃商务蓝
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFF0D9488), // 收益翡翠绿
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF38BDF8),
          primary: const Color(0xFF38BDF8),
          secondary: const Color(0xFF34D399),
          surface: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF8FAFC),
          ),
        ),
        cardTheme: const CardTheme(
          color: Color(0xFF1E293B),
          elevation: 0,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // 全局引用
  final GlobalKey<CalculatorPageState> _calculatorKey = GlobalKey<CalculatorPageState>();
  final GlobalKey<HistoryPageState> _historyKey = GlobalKey<HistoryPageState>();

  ProfitRecord? _activeRecord;

  void _onSelectRecordFromHistory(ProfitRecord record) {
    setState(() {
      _activeRecord = record;
      _currentIndex = 0; // 切换回测算主页
    });
    // 回填数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatorKey.currentState?.loadRecord(record);
    });
  }

  void _onSaved() {
    _historyKey.currentState?.refreshRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CalculatorPage(
            key: _calculatorKey,
            initialRecord: _activeRecord,
            onSaved: _onSaved,
          ),
          ComparisonPage(
            baseRecord: _activeRecord,
          ),
          HistoryPage(
            key: _historyKey,
            onSelectRecord: _onSelectRecordFromHistory,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
          if (idx == 2) {
            _historyKey.currentState?.refreshRecords();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate_rounded),
            label: '利润测算',
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows_rounded),
            selectedIcon: Icon(Icons.compare_arrows_rounded),
            label: '定价对比',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: '历史记录',
          ),
        ],
      ),
    );
  }
}
