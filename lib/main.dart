import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/profit_record.dart';
import 'pages/calculator_page.dart';
import 'pages/pricing_tools_page.dart';
import 'pages/monthly_simulator_page.dart';
import 'pages/history_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const EcomProfitApp());
}

class EcomProfitApp extends StatefulWidget {
  const EcomProfitApp({super.key});

  @override
  State<EcomProfitApp> createState() => _EcomProfitAppState();
}

class _EcomProfitAppState extends State<EcomProfitApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '少伟利润通',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF059669), // 翡翠绿
          secondary: const Color(0xFF0284C7), // 商务蓝
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF10B981),
          primary: const Color(0xFF10B981),
          secondary: const Color(0xFF38BDF8),
          surface: const Color(0xFF1E293B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF8FAFC),
          ),
          iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 0,
        ),
      ),
      home: MainNavigationScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const MainNavigationScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final GlobalKey<CalculatorPageState> _calculatorKey = GlobalKey<CalculatorPageState>();
  final GlobalKey<HistoryPageState> _historyKey = GlobalKey<HistoryPageState>();

  ProfitRecord? _activeRecord;

  void _onSelectRecordFromHistory(ProfitRecord record) {
    setState(() {
      _activeRecord = record;
      _currentIndex = 0;
    });
    _calculatorKey.currentState?.loadRecord(record);
  }

  void _onApplyReverseToCalculator(ProfitRecord record) {
    setState(() {
      _activeRecord = record;
      _currentIndex = 0;
    });
    _calculatorKey.currentState?.loadRecord(record);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    final List<Widget> pages = [
      CalculatorPage(
        key: _calculatorKey,
        initialRecord: _activeRecord,
        onSaved: () => _historyKey.currentState?.refreshRecords(),
        onRecordChanged: (rec) => _activeRecord = rec,
      ),
      PricingToolsPage(
        baseRecord: _activeRecord,
        onApplyToCalculator: _onApplyReverseToCalculator,
      ),
      MonthlySimulatorPage(
        baseRecord: _activeRecord,
      ),
      HistoryPage(
        key: _historyKey,
        onSelectRecord: _onSelectRecordFromHistory,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          // 悬浮深色/浅色模式切换按钮（位于右上角，不遮挡内容）
          Positioned(
            top: MediaQuery.of(context).padding.top + 6,
            right: 80, // 避开 AppBar actions
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                tooltip: isDark ? "切换至浅色模式" : "切换至深色模式",
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
                ),
                onPressed: widget.onToggleTheme,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          indicatorColor: const Color(0xFF10B981).withOpacity(0.18),
          height: 65,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            setState(() {
              _currentIndex = index;
            });
            if (index == 3) {
              _historyKey.currentState?.refreshRecords();
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calculate_outlined, size: 22),
              selectedIcon: Icon(Icons.calculate_rounded, color: Color(0xFF059669), size: 24),
              label: '利润测算',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined, size: 22),
              selectedIcon: Icon(Icons.tune_rounded, color: Color(0xFF059669), size: 24),
              label: '定价决策',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined, size: 22),
              selectedIcon: Icon(Icons.insights_rounded, color: Color(0xFF059669), size: 24),
              label: '月度沙盘',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined, size: 22),
              selectedIcon: Icon(Icons.history_rounded, color: Color(0xFF059669), size: 24),
              label: '历史记录',
            ),
          ],
        ),
      ),
    );
  }
}
