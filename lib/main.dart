// main.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const SkullKingMateApp());
}

/* =======================
 * 글로벌 상태
 * ======================= */

final ruleNotifier = ValueNotifier<RuleProfile>(const RuleProfile());
final scoreStore = ScoreStore();

/// 사용자 선택 테마 시드 컬러
final themeSeed = ValueNotifier<Color>(const Color(0xFFC5C6FF)); // 최초 라일락

/// 제공 팔레트
const List<Color> kThemePalette = [
  Color(0xFFF3FFAD),
  Color(0xFFBCBCBC),
  Color(0xFF83FFA4),
  Color(0xFFC5C6FF),
  Color(0xFFFFC5E5),
  Color(0xFFFFA7A8),
];

/* =======================
 * 모델
 * ======================= */

class ScoreStore {
  final ValueNotifier<ScoreSession?> session =
      ValueNotifier<ScoreSession?>(null);
  void reset() => session.value = null;
}

class RuleProfile {
  final int totalRounds;
  final int hitBidBasePerBid;
  final int hitTrickBonusPerTrick;
  final int missPenaltyPerDiff;
  final int zeroHitPerRound;
  final int zeroMissPerRound;
  final bool validateTotalTricksEqualsRound;
  const RuleProfile({
    this.totalRounds = 10,
    this.hitBidBasePerBid = 20,
    this.hitTrickBonusPerTrick = 0,
    this.missPenaltyPerDiff = -10,
    this.zeroHitPerRound = 10,
    this.zeroMissPerRound = -10,
    this.validateTotalTricksEqualsRound = true,
  });

  RuleProfile copyWith({
    int? totalRounds,
    int? hitBidBasePerBid,
    int? hitTrickBonusPerTrick,
    int? missPenaltyPerDiff,
    int? zeroHitPerRound,
    int? zeroMissPerRound,
    bool? validateTotalTricksEqualsRound,
  }) {
    return RuleProfile(
      totalRounds: totalRounds ?? this.totalRounds,
      hitBidBasePerBid: hitBidBasePerBid ?? this.hitBidBasePerBid,
      hitTrickBonusPerTrick:
          hitTrickBonusPerTrick ?? this.hitTrickBonusPerTrick,
      missPenaltyPerDiff: missPenaltyPerDiff ?? this.missPenaltyPerDiff,
      zeroHitPerRound: zeroHitPerRound ?? this.zeroHitPerRound,
      zeroMissPerRound: zeroMissPerRound ?? this.zeroMissPerRound,
      validateTotalTricksEqualsRound:
          validateTotalTricksEqualsRound ?? this.validateTotalTricksEqualsRound,
    );
  }
}

class Player {
  final String id;
  String name;
  final Color color;
  final List<int?> bids;
  final List<int?> tricks;
  final List<int> roundScores;
  final List<int> bonuses;
  Player({
    required this.id,
    required this.name,
    required this.color,
    required int totalRounds,
  })  : bids = List<int?>.filled(totalRounds, null),
        tricks = List<int?>.filled(totalRounds, null),
        roundScores = List<int>.filled(totalRounds, 0),
        bonuses = List<int>.filled(totalRounds, 0);

  int get totalScore => roundScores.fold(0, (a, b) => a + b);

  Player copyForRounds(int totalRounds) {
    final nb = List<int?>.filled(totalRounds, null);
    final nt = List<int?>.filled(totalRounds, null);
    final ns = List<int>.filled(totalRounds, 0);
    final bo = List<int>.filled(totalRounds, 0);
    for (int i = 0; i < math.min(totalRounds, bids.length); i++) {
      nb[i] = bids[i];
      nt[i] = tricks[i];
      ns[i] = roundScores[i];
      bo[i] = bonuses[i];
    }
    return Player(id: id, name: name, color: color, totalRounds: totalRounds)
      .._assign(nb, nt, ns, bo);
  }

  void _assign(List<int?> b, List<int?> t, List<int> s, List<int> bo) {
    for (int i = 0; i < b.length; i++) {
      bids[i] = b[i];
      tricks[i] = t[i];
      roundScores[i] = s[i];
      bonuses[i] = bo[i];
    }
  }
}

/* =======================
 * 점수 계산
 * ======================= */

int calcRoundCore({
  required int round,
  required int bid,
  required int tricks,
  required RuleProfile rp,
}) {
  if (bid == 0) {
    return tricks == 0
        ? rp.zeroHitPerRound * round
        : rp.zeroMissPerRound * round;
  } else {
    if (tricks == bid) {
      return rp.hitBidBasePerBid * bid + rp.hitTrickBonusPerTrick * tricks;
    } else {
      return rp.missPenaltyPerDiff * (tricks - bid).abs();
    }
  }
}

/* =======================
 * 테마 (Noto Sans KR + 색 시스템)
 * ======================= */

Color _pastelBg(Color seed) => Color.lerp(seed, Colors.white, 0.82)!;

ThemeData buildCleanTheme(Color seed) {
  final scheme =
      ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
  final bg = _pastelBg(seed);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    // 폰트 (pubspec.yaml의 family명과 동일)
    fontFamily: 'NotoSansKR',

    textTheme: const TextTheme().copyWith(
      titleLarge:
          const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: const TextStyle(fontWeight: FontWeight.w700),
      bodyLarge: const TextStyle(fontWeight: FontWeight.w400, height: 1.25),
      bodyMedium: const TextStyle(fontWeight: FontWeight.w400, height: 1.25),
      labelLarge: const TextStyle(fontWeight: FontWeight.w600),
    ),

    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Color.lerp(bg, Colors.white, 0.9),
      elevation: 0,
      foregroundColor: Colors.black,
      titleTextStyle: const TextStyle(
        fontFamily: 'NotoSansKR',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: Colors.black,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    // (사용자 환경 경고 해결용) CardThemeData / DialogThemeData 사용
    cardTheme: CardThemeData(
      color: Color.lerp(scheme.surface, Colors.white, 0.75),
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Color.lerp(bg, Colors.white, .92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontFamily: 'NotoSansKR',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: Colors.black,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'NotoSansKR',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        color: Colors.black87,
        height: 1.35,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: Color.lerp(bg, Colors.white, 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: const TextStyle(color: Color(0xFF6B7280)),
    ),

    chipTheme: ChipThemeData(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: const BorderSide(color: Color(0xFFE5E7EB)),
      backgroundColor: Color.lerp(bg, Colors.white, 0.75)!,
      labelStyle: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
  );
}

/* =======================
 * 공용 UI
 * ======================= */

class UiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const UiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
    return onTap == null
        ? card
        : InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: card,
          );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SectionTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class StatPill extends StatelessWidget {
  final String text;
  final Color? color;
  const StatPill(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/* =======================
 * 전환 애니메이션
 * ======================= */

Route _fadeSlide(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (c, a, s) => page,
    transitionsBuilder: (c, a, s, child) {
      final curved = CurvedAnimation(parent: a, curve: Curves.easeInOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

/* =======================
 * 앱 루트
 * ======================= */

class SkullKingMateApp extends StatelessWidget {
  const SkullKingMateApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: themeSeed,
      builder: (_, seed, __) => MaterialApp(
        title: '스컬킹 메이트',
        theme: buildCleanTheme(seed),
        debugShowCheckedModeBanner: false,
        home: const HomePage(),
      ),
    );
  }
}

/* =======================
 * 홈
 * ======================= */

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  void _openRulesEditor(BuildContext context) async {
    final updated = await showModalBottomSheet<RuleProfile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ValueListenableBuilder<RuleProfile>(
        valueListenable: ruleNotifier,
        builder: (_, rules, __) => RuleEditorSheet(rules: rules),
      ),
    );
    if (updated != null) ruleNotifier.value = updated;
  }

  void _openPalette(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionTitle('테마 색상 선택', subtitle: '블럭/포인트에 적용됩니다'),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in kThemePalette)
                    GestureDetector(
                      onTap: () {
                        themeSeed.value = c;
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCredit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Credit'),
        content: const Text('Creator : 조기홍\nEmail : bcfhlttu@naver.com'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(_fadeSlide(page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스컬킹 메이트'),
        actions: [
          IconButton(
              tooltip: 'Theme',
              onPressed: () => _openPalette(context),
              icon: const Icon(Icons.palette_outlined)),
          IconButton(
              tooltip: 'Settings',
              onPressed: () => _openRulesEditor(context),
              icon: const Icon(Icons.rule)),
          IconButton(
              tooltip: 'Credit',
              onPressed: () => _openCredit(context),
              icon: const Icon(Icons.info_outline)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: const [
            Expanded(
              child: _ToolCard(
                icon: Icons.summarize,
                title: '스코어키퍼',
                subtitle: '라운드별 점수 기록과 계산을 간편하게',
                target: ScorekeeperPage(),
              ),
            ),
            SizedBox(height: 14),
            Expanded(
              child: _ToolCard(
                icon: Icons.change_circle_outlined,
                title: '트릭 시뮬레이터',
                subtitle: '다각형 테이블에서 상황을 가볍게 테스트',
                target: WhatIfTrickPage(),
              ),
            ),
            SizedBox(height: 14),
            Expanded(
              child: _ToolCard(
                icon: Icons.help_outline_rounded,
                title: '알쏭달쏭',
                subtitle: '헷갈릴 때 바로 확인하는 상황 모음집',
                target: ConfusionGuidePage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget target;
  const _ToolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.target,
  });

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  double _scale = 1.0;

  void _go() async {
    setState(() => _scale = .98);
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    setState(() => _scale = 1);
    if (!mounted) return;
    Navigator.of(context).push(_fadeSlide(widget.target));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _go,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(widget.icon, size: 40, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(widget.subtitle,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.black54)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* =======================
 * 스코어키퍼
 * ======================= */

enum RoundPhase { bidding, tricks, bonus }

class ScoreSession {
  RuleProfile rules;
  int currentRound;
  RoundPhase phase;
  final List<Player> players;
  final List<int> krakenCounts; // 라운드별 크라켄 횟수

  ScoreSession({
    required this.rules,
    required this.players,
    this.currentRound = 1,
    this.phase = RoundPhase.bidding,
  }) : krakenCounts = List<int>.filled(rules.totalRounds, 0);
}

class ScorekeeperPage extends StatefulWidget {
  const ScorekeeperPage({Key? key}) : super(key: key);
  @override
  State<ScorekeeperPage> createState() => _ScorekeeperPageState();
}

class _ScorekeeperPageState extends State<ScorekeeperPage> {
  ScoreSession? _session;
  RuleProfile get _rules => ruleNotifier.value;

  final Map<String, int?> _bid = {};
  final Map<String, int?> _trick = {};
  final Map<String, int> _bonus = {};

  @override
  void initState() {
    super.initState();
    if (scoreStore.session.value == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askPlayersCount());
    } else {
      _attachSession(scoreStore.session.value!);
    }
    ruleNotifier.addListener(_onRulesChanged);
    scoreStore.session.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    ruleNotifier.removeListener(_onRulesChanged);
    scoreStore.session.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    final s = scoreStore.session.value;
    if (mounted && s != null) setState(() => _attachSession(s));
  }

  void _attachSession(ScoreSession s) {
    _session = s;
    _syncMapsForRound(resetToZero: true);
  }

  void _syncMapsForRound({bool resetToZero = false}) {
    _bid.clear();
    _trick.clear();
    _bonus.clear();
    final s = _session!;
    final r = s.currentRound - 1;
    for (final p in s.players) {
      _bid[p.id] = resetToZero ? (p.bids[r] ?? 0) : (p.bids[r] ?? 0);
      _trick[p.id] = resetToZero ? 0 : (p.tricks[r] ?? 0);
      _bonus[p.id] = (r >= 0 && r < p.bonuses.length) ? p.bonuses[r] : 0;
    }
  }

  Future<void> _askPlayersCount() async {
    int count = 4;

    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 6),
          title: const Text('출항 인원이 몇명인가!'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                // 내부 박스 배경 = 스캐폴드 배경색과 동일
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _SquareBtn(
                        icon: Icons.remove,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setS(() => count = (count - 1).clamp(2, 10));
                        },
                        onLongPress: () {
                          HapticFeedback.lightImpact();
                          setS(() => count = (count - 3).clamp(2, 10));
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$count명',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      _SquareBtn(
                        icon: Icons.add,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setS(() => count = (count + 1).clamp(2, 10));
                        },
                        onLongPress: () {
                          HapticFeedback.lightImpact();
                          setS(() => count = (count + 3).clamp(2, 10));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('최소 2 / 최대 10',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx, count),
                child: const Text('확인')),
          ],
        ),
      ),
    );

    final players = List.generate(n ?? 4, (k) {
      final idx = k + 1;
      return Player(
        id: UniqueKey().toString(),
        name: 'Player $idx',
        color: Colors.primaries[idx % Colors.primaries.length],
        totalRounds: _rules.totalRounds,
      );
    });

    scoreStore.session.value = ScoreSession(rules: _rules, players: players);
  }

  void _onRulesChanged() {
    final s = scoreStore.session.value;
    if (s == null) return;
    for (int i = 0; i < s.players.length; i++) {
      s.players[i] = s.players[i].copyForRounds(_rules.totalRounds);
    }
    if (s.currentRound > _rules.totalRounds) {
      s.currentRound = _rules.totalRounds;
    }

    // 크라켄 길이 재조정
    if (s.krakenCounts.length != _rules.totalRounds) {
      final old = List<int>.from(s.krakenCounts);
      for (int i = 0; i < _rules.totalRounds; i++) {
        if (i < old.length) {
          s.krakenCounts[i] = old[i];
        } else {
          s.krakenCounts[i] = 0;
        }
      }
    }
    setState(() {});
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  bool _isLeader(Player p, List<Player> players) {
    if (players.isEmpty) return false;
    final top =
        players.map((e) => e.totalScore).fold<int>(-0x3fffffff, math.max);
    return p.totalScore == top;
  }

  Future<void> _editAllNames() async {
    final s = _session!;
    final ctrls = [
      for (final p in s.players) TextEditingController(text: p.name)
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('플레이어 이름 편집'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < s.players.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: ctrls[i],
                    decoration: InputDecoration(labelText: '플레이어 ${i + 1}'),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('저장')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        for (int i = 0; i < s.players.length; i++) {
          final t = ctrls[i].text.trim();
          if (t.isNotEmpty) s.players[i].name = t;
        }
      });
    }
  }

  /* ---- 단계 진행 ---- */
  void _nextPhase() {
    final s = _session!;
    final rIdx = s.currentRound - 1;

    switch (s.phase) {
      case RoundPhase.bidding:
        for (final p in s.players) {
          final v = (_bid[p.id] ?? 0);
          if (v < 0 || v > s.currentRound) {
            _snack('${p.name}의 비딩은 0~${s.currentRound} 사이여야 합니다.');
            return;
          }
        }
        for (final p in s.players) {
          p.bids[rIdx] = (_bid[p.id] ?? 0);
        }
        setState(() {
          s.phase = RoundPhase.tricks;
          for (final p in s.players) {
            _trick[p.id] = 0; // 초기화
          }
        });
        return;

      case RoundPhase.tricks:
        int sum = 0;
        for (final p in s.players) {
          final v = (_trick[p.id] ?? 0);
          if (v < 0 || v > s.currentRound) {
            _snack('${p.name}의 트릭 수는 0~${s.currentRound} 사이여야 합니다.');
            return;
          }
          sum += v;
        }
        if (_rules.validateTotalTricksEqualsRound) {
          final k = s.krakenCounts[rIdx].clamp(0, s.currentRound);
          final valid = (sum + k == s.currentRound);
          if (!valid) {
            _snack(
                '트릭 합과 크라켄 수의 합이 라운드 수와 같아야 합니다. (현재 ${sum}+${k} ≠ ${s.currentRound})');
            return;
          }
        }
        for (final p in s.players) {
          final ok = ((_trick[p.id] ?? 0) == (_bid[p.id] ?? 0));
          if (!ok) _bonus[p.id] = 0;
        }
        setState(() => s.phase = RoundPhase.bonus);
        return;

      case RoundPhase.bonus:
        for (final p in s.players) {
          final bid = (_bid[p.id] ?? 0);
          final trik = (_trick[p.id] ?? 0);
          final base = calcRoundCore(
              round: s.currentRound, bid: bid, tricks: trik, rp: _rules);
          final bonus = (bid == trik) ? (_bonus[p.id] ?? 0) : 0;
          p.tricks[rIdx] = trik;
          p.bonuses[rIdx] = bonus;
          p.roundScores[rIdx] = base + bonus;
        }
        if (s.currentRound < _rules.totalRounds) {
          setState(() {
            s.currentRound += 1;
            s.phase = RoundPhase.bidding;
            _syncMapsForRound(resetToZero: true);
          });
        } else {
          _showSummaryDialog();
        }
        return;
    }
  }

  void _prevPhase() {
    final s = _session!;
    switch (s.phase) {
      case RoundPhase.bidding:
        return;
      case RoundPhase.tricks:
        setState(() => s.phase = RoundPhase.bidding);
        return;
      case RoundPhase.bonus:
        setState(() => s.phase = RoundPhase.tricks);
        return;
    }
  }

  void _showSummaryDialog() {
    final s = _session!;
    final sorted = [...s.players]
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    String medal(int index) {
      if (index == 0) return '🥇';
      if (index == 1) return '🥈';
      if (index == 2) return '🥉';
      return '';
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('게임 요약'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('기준 라운드: ',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('${_rules.totalRounds}'),
                    const Spacer(),
                    const Icon(Icons.emoji_events_outlined,
                        size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    Text('최고 점수 ${sorted.first.totalScore}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(sorted.length, (i) {
                final p = sorted[i];
                final m = medal(i);
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: m.isNotEmpty
                      ? Text(m, style: const TextStyle(fontSize: 20))
                      : const SizedBox(width: 16),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: StatPill('${p.totalScore} 점'),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('닫기')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              scoreStore.reset();
              _askPlayersCount();
            },
            child: const Text('새 게임'),
          ),
        ],
      ),
    );
  }

  Widget _scorePill(int score) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: child,
      ),
      child: StatPill('$score점', key: ValueKey(score)),
    );
  }

  /* ---- UI ---- */
  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final s = _session!;
    final round = s.currentRound;

    int crossAxisCount = MediaQuery.of(context).size.width >= 720 ? 3 : 2;

    String phaseLabel(RoundPhase p) {
      switch (p) {
        case RoundPhase.bidding:
          return '비딩';
        case RoundPhase.tricks:
          return '트릭';
        case RoundPhase.bonus:
          return '가산점';
      }
    }

    final bidSum = s.players.fold<int>(0, (a, p) => a + (_bid[p.id] ?? 0));
    final trickSum = s.players.fold<int>(0, (a, p) => a + (_trick[p.id] ?? 0));
    final k = s.krakenCounts[round - 1].clamp(0, round);
    // sumOk 로직은 유지하지만, 하단 안내 텍스트는 삭제하여 공간 확보
    final _ = (s.phase != RoundPhase.tricks) ||
        (!_rules.validateTotalTricksEqualsRound) ||
        (trickSum + k == round);
    // _ 변수는 사용하지 않지만, 로직 유지 목적으로 남겨둠.

    return Scaffold(
      appBar: AppBar(
        title: const Text('스코어키퍼'),
        actions: [
          IconButton(
              onPressed: _editAllNames,
              tooltip: '이름 편집',
              icon: const Icon(Icons.edit_outlined)),
          IconButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('리셋할까요?'),
                  content: const Text('리셋을 누르면 현재 스코어 세션이 초기화됩니다.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('취소')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('리셋')),
                  ],
                ),
              );
              if (ok == true) {
                scoreStore.reset();
                if (mounted) await _askPlayersCount();
              }
            },
            tooltip: '리셋',
            icon: const Icon(Icons.replay_outlined),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: Color.lerp(
                Theme.of(context).scaffoldBackgroundColor, Colors.white, 0.85),
            border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              // 왼쪽 안내 텍스트 제거 (공간 확보)
              const SizedBox(width: 4),
              const Spacer(),
              if (s.phase == RoundPhase.tricks) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final rIdx = s.currentRound - 1;
                    final v = await showDialog<int>(
                      context: context,
                      builder: (_) => _KrakenDialog(
                        initial: s.krakenCounts[rIdx],
                        max: s.currentRound,
                      ),
                    );
                    if (v != null) {
                      setState(() =>
                          s.krakenCounts[rIdx] = v.clamp(0, s.currentRound));
                    }
                  },
                  icon: const Icon(Icons.waves_rounded, size: 18),
                  label: Text('크라켄 $k'),
                ),
                const SizedBox(width: 8),
              ],
              s.phase != RoundPhase.bidding
                  ? OutlinedButton.icon(
                      onPressed: _prevPhase,
                      icon: const Icon(Icons.chevron_left, size: 18),
                      label: const Text('이전'),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _nextPhase,
                icon: Icon(
                  s.phase == RoundPhase.bonus
                      ? Icons.calculate_rounded
                      : Icons.chevron_right,
                  size: 18,
                ),
                label: Text(s.phase == RoundPhase.bonus ? '계산' : '다음 단계'),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        children: [
          Row(
            children: [
              Chip(label: Text('라운드 $round / ${_rules.totalRounds}')),
              const SizedBox(width: 6),
              Chip(label: Text('단계: ${phaseLabel(s.phase)}')),
              const Spacer(),
              if (s.phase == RoundPhase.bidding) Text('비딩 합: $bidSum'),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 184,
            ),
            itemCount: s.players.length,
            itemBuilder: (_, idx) {
              final p = s.players[idx];
              _bid.putIfAbsent(p.id, () => p.bids[round - 1] ?? 0);
              _trick.putIfAbsent(p.id, () => p.tricks[round - 1] ?? 0);
              _bonus.putIfAbsent(p.id, () => p.bonuses[round - 1] ?? 0);

              final isLeader = _isLeader(p, s.players);
              return _PlayerTile(
                key: ValueKey(p.id),
                player: p,
                isLeader: isLeader,
                totalScore: p.totalScore,
                scorePillBuilder: _scorePill,
                phase: s.phase,
                round: round,
                bid: _bid[p.id] ?? 0,
                trick: _trick[p.id] ?? 0,
                bonus: _bonus[p.id] ?? 0,
                onChangedBid: (v) => setState(() => _bid[p.id] = v),
                onChangedTrick: (v) => setState(() => _trick[p.id] = v),
                onChangedBonus: (v) => setState(() => _bonus[p.id] = v),
              );
            },
          ),
        ],
      ),
    );
  }
}

/* ---- 크라켄 회수 설정 다이얼로그 ---- */
class _KrakenDialog extends StatefulWidget {
  final int initial;
  final int max;
  const _KrakenDialog({Key? key, required this.initial, required this.max})
      : super(key: key);

  @override
  State<_KrakenDialog> createState() => _KrakenDialogState();
}

class _KrakenDialogState extends State<_KrakenDialog> {
  late int v;
  @override
  void initState() {
    super.initState();
    v = widget.initial.clamp(0, widget.max);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('크라켄 횟수'),
      content: SizedBox(
        width: 260,
        child: Row(
          children: [
            _SquareBtn(
                icon: Icons.remove,
                onTap: () => setState(() => v = (v - 1).clamp(0, widget.max))),
            Expanded(
              child: Center(
                child: Text('$v',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
              ),
            ),
            _SquareBtn(
                icon: Icons.add,
                onTap: () => setState(() => v = (v + 1).clamp(0, widget.max))),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
            onPressed: () => Navigator.pop(context, v),
            child: const Text('확인')),
      ],
    );
  }
}

/* ---- 미니 스텝퍼(버튼형) ---- */
class MiniStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final String label;
  final bool enabled;
  final ValueChanged<int> onChanged;
  const MiniStepper({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.label = '',
    this.enabled = true,
  }) : super(key: key);

  void _emit(int v) => onChanged(v.clamp(min, max));

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(min, max);
    final textStyle = TextStyle(
        color: enabled ? Colors.black87 : Colors.black26, fontSize: 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) Text(label, style: textStyle),
        const SizedBox(height: 6),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(12),
            border: const Border.fromBorderSide(
                BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              _SquareBtn(
                icon: Icons.remove,
                onTap: enabled
                    ? () {
                        HapticFeedback.lightImpact();
                        _emit(v - step);
                      }
                    : null,
                onLongPress: enabled
                    ? () {
                        HapticFeedback.lightImpact();
                        _emit(v - step * 5);
                      }
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$v',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: enabled ? Colors.black : Colors.black26,
                    ),
                  ),
                ),
              ),
              _SquareBtn(
                icon: Icons.add,
                onTap: enabled
                    ? () {
                        HapticFeedback.lightImpact();
                        _emit(v + step);
                      }
                    : null,
                onLongPress: enabled
                    ? () {
                        HapticFeedback.lightImpact();
                        _emit(v + step * 5);
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SquareBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const _SquareBtn({Key? key, required this.icon, this.onTap, this.onLongPress})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Icon(
          icon,
          size: 26,
          color: onTap == null ? Colors.black26 : Colors.black54,
        ),
      ),
    );
  }
}

/* ---- 플레이어 타일 ---- */

class _PlayerTile extends StatelessWidget {
  final Player player;
  final bool isLeader;
  final int totalScore;
  final Widget Function(int) scorePillBuilder;
  final RoundPhase phase;
  final int round;
  final int bid;
  final int trick;
  final int bonus;
  final ValueChanged<int> onChangedBid;
  final ValueChanged<int> onChangedTrick;
  final ValueChanged<int> onChangedBonus;

  const _PlayerTile({
    Key? key,
    required this.player,
    required this.isLeader,
    required this.totalScore,
    required this.scorePillBuilder,
    required this.phase,
    required this.round,
    required this.bid,
    required this.trick,
    required this.bonus,
    required this.onChangedBid,
    required this.onChangedTrick,
    required this.onChangedBonus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 테두리 제거, 카드 고도감만 활용
    final canBonus = (bid == trick);
    return UiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (isLeader) ...const [
                      SizedBox(width: 6),
                      Icon(Icons.emoji_events,
                          size: 16, color: Color(0xFFF59E0B)),
                    ],
                  ],
                ),
              ),
              scorePillBuilder(totalScore),
            ],
          ),
          const SizedBox(height: 12),
          if (phase == RoundPhase.bidding)
            MiniStepper(
              min: 0,
              max: round,
              value: bid,
              onChanged: onChangedBid,
              label: '비딩(0~$round)',
            )
          else if (phase == RoundPhase.tricks)
            MiniStepper(
              min: 0,
              max: round,
              value: trick,
              onChanged: onChangedTrick,
              label: '트릭(0~$round)',
            )
          else
            MiniStepper(
              min: 0,
              max: 200,
              step: 10,
              value: canBonus ? bonus : 0,
              onChanged: onChangedBonus,
              label: canBonus ? '가산점(0~200, 10단위)' : '가산점(비딩=트릭일 때만)',
              enabled: canBonus,
            ),
        ],
      ),
    );
  }
}

/* =======================
 * 트릭 시뮬레이터
 * ======================= */

enum CardSuit { green, yellow, purple, black }

enum CardSpecial {
  none,
  pirate,
  mermaid,
  skullKing,
  escape,
  kraken,
  whiteWhale,
}

String suitLabel(CardSuit s) {
  switch (s) {
    case CardSuit.green:
      return '초록';
    case CardSuit.yellow:
      return '노랑';
    case CardSuit.purple:
      return '보라';
    case CardSuit.black:
      return '검정';
  }
}

class TrickCard {
  final CardSuit? suit;
  final int? rank;
  final CardSpecial special;
  const TrickCard.suit(this.suit, this.rank) : special = CardSpecial.none;
  const TrickCard.special(this.special)
      : suit = null,
        rank = null;

  bool get isNumber => special == CardSpecial.none && suit != null;

  @override
  String toString() {
    if (special != CardSpecial.none) {
      switch (special) {
        case CardSpecial.pirate:
          return '해적';
        case CardSpecial.mermaid:
          return '인어';
        case CardSpecial.skullKing:
          return '스컬킹';
        case CardSpecial.escape:
          return '탈출';
        case CardSpecial.kraken:
          return '크라켄';
        case CardSpecial.whiteWhale:
          return '백고래';
        case CardSpecial.none:
          break;
      }
    }
    return '${suitLabel(suit!)} $rank';
  }
}

class TrickOutcome {
  final int? winnerIndex; // null=무효
  final String message;
  const TrickOutcome(this.winnerIndex, this.message);
}

class TrickEngine {
  static TrickOutcome evaluate({
    required List<TrickCard> seats,
    required int startIndex,
  }) {
    final n = seats.length;
    final order = List.generate(n, (i) => (startIndex + i) % n);
    final plays = [for (final i in order) seats[i]];

    int firstWhere(bool Function(TrickCard) test) {
      for (int i = 0; i < plays.length; i++) {
        if (test(plays[i])) return i;
      }
      return -1;
    }

    // 크라켄/백고래
    final krIdx = plays.indexWhere((c) => c.special == CardSpecial.kraken);
    final wwIdx = plays.indexWhere((c) => c.special == CardSpecial.whiteWhale);
    if (krIdx >= 0 || wwIdx >= 0) {
      if (krIdx >= 0 && wwIdx >= 0) {
        final lastIsKraken = krIdx > wwIdx;
        if (lastIsKraken) {
          final alt = _winnerWithout(plays, CardSpecial.kraken);
          final nextLead = alt ?? 0;
          return TrickOutcome(
            null,
            '크라켄! 트릭 무효. 다음 리드는 플레이어 ${order[nextLead] + 1}번.',
          );
        } else {
          final w = _whaleWinner(plays);
          if (w == null) {
            return TrickOutcome(order[startIndex], '백고래! 유효 수트가 없어 선 플레이어 유지.');
          }
          final winSeat = order[w];
          return TrickOutcome(
            winSeat,
            '백고래! 특수무효 → 리드 수트 최고 승. 다음 리드: ${winSeat + 1}번.',
          );
        }
      } else if (krIdx >= 0) {
        final alt = _winnerWithout(plays, CardSpecial.kraken);
        final nextLead = alt ?? 0;
        return TrickOutcome(
          null,
          '크라켄! 트릭 무효. 다음 리드: ${order[nextLead] + 1}번.',
        );
      } else {
        final w = _whaleWinner(plays);
        if (w == null) {
          return TrickOutcome(order[startIndex], '백고래! 유효 수트 없음 → 선 플레이어 유지.');
        }
        final winSeat = order[w];
        return TrickOutcome(
          winSeat,
          '백고래! 특수무효 → 리드 수트 최고 승. 다음 리드: ${winSeat + 1}번.',
        );
      }
    }

    // 스컬킹/인어/해적
    final hasSkull = plays.any((c) => c.special == CardSpecial.skullKing);
    final anyMermaid = plays.any((c) => c.special == CardSpecial.mermaid);
    final anyPirate = plays.any((c) => c.special == CardSpecial.pirate);

    if (hasSkull && anyMermaid) {
      final mIdx = firstWhere((c) => c.special == CardSpecial.mermaid);
      final winSeat = order[mIdx];
      return TrickOutcome(
        winSeat,
        '플레이어 ${winSeat + 1}번 승리! 보너스 +50. 다음 리드: ${winSeat + 1}번.',
      );
    }

    if (hasSkull && !anyMermaid) {
      final skIdx = firstWhere((c) => c.special == CardSpecial.skullKing);
      final winSeat = order[skIdx];
      final piratesCaptured =
          plays.where((c) => c.special == CardSpecial.pirate).length;
      final bonus = piratesCaptured * 30;
      final bonusText = piratesCaptured > 0 ? '보너스 +$bonus' : '보너스 없음';
      return TrickOutcome(
        winSeat,
        '플레이어 ${winSeat + 1}번 승리! $bonusText. 다음 리드: ${winSeat + 1}번.',
      );
    }

    if (anyPirate) {
      final pIdx = firstWhere((c) => c.special == CardSpecial.pirate);
      final winSeat = order[pIdx];
      return TrickOutcome(
        winSeat,
        '해적 우위! 플레이어 ${winSeat + 1}번 승리. 다음 리드: ${winSeat + 1}번.',
      );
    }

    if (anyMermaid) {
      final mIdx = firstWhere((c) => c.special == CardSpecial.mermaid);
      final winSeat = order[mIdx];
      return TrickOutcome(
        winSeat,
        '인어가 숫자카드를 제압! 플레이어 ${winSeat + 1}번 승리. 다음 리드: ${winSeat + 1}번.',
      );
    }

    // 일반 규칙
    final res = _normalWinner(plays);
    final winSeat = order[res];
    final lead = _leadSuit(plays);
    final leadText = (lead != null) ? suitLabel(lead) : '없음';
    return TrickOutcome(
      winSeat,
      '리드 수트($leadText)/검정 규칙으로 ${winSeat + 1}번 승리. 다음 리드: ${winSeat + 1}번.',
    );
  }

  static int? _whaleWinner(List<TrickCard> plays) {
    final lead = _leadSuit(plays);
    if (lead == null) return null;
    int w = -1, best = -1;
    for (int i = 0; i < plays.length; i++) {
      final c = plays[i];
      if (c.isNumber && c.suit == lead) {
        final r = c.rank ?? 0;
        if (r > best) {
          best = r;
          w = i;
        }
      }
    }
    return w >= 0 ? w : null;
  }

  static int? _winnerWithout(List<TrickCard> plays, CardSpecial remove) {
    final filtered = plays.where((c) => c.special != remove).toList();
    if (filtered.isEmpty) return null;
    if (filtered.any((c) => c.special == CardSpecial.skullKing) &&
        filtered.any((c) => c.special == CardSpecial.mermaid)) {
      return filtered.indexWhere((c) => c.special == CardSpecial.mermaid);
    }
    if (filtered.any((c) => c.special == CardSpecial.skullKing)) {
      return filtered.indexWhere((c) => c.special == CardSpecial.skullKing);
    }
    final p = filtered.indexWhere((c) => c.special == CardSpecial.pirate);
    if (p >= 0) return p;
    return _normalWinner(filtered);
  }

  static int _normalWinner(List<TrickCard> plays) {
    final lead = _leadSuit(plays);
    int w = -1, best = -1;
    // 검정(트럼프)
    for (int i = 0; i < plays.length; i++) {
      final c = plays[i];
      if (c.isNumber && c.suit == CardSuit.black) {
        final r = c.rank ?? 0;
        if (r > best) {
          best = r;
          w = i;
        }
      }
    }
    if (w >= 0) return w;
    // 리드 수트
    for (int i = 0; i < plays.length; i++) {
      final c = plays[i];
      if (c.isNumber && lead != null && c.suit == lead) {
        final r = c.rank ?? 0;
        if (r > best) {
          best = r;
          w = i;
        }
      }
    }
    return (w >= 0) ? w : 0;
  }

  static CardSuit? _leadSuit(List<TrickCard> plays) {
    for (final c in plays) {
      if (c.isNumber) return c.suit;
    }
    return null;
  }
}

class WhatIfTrickPage extends StatefulWidget {
  const WhatIfTrickPage({Key? key}) : super(key: key);
  @override
  State<WhatIfTrickPage> createState() => _WhatIfTrickPageState();
}

class _WhatIfTrickPageState extends State<WhatIfTrickPage> {
  int numPlayers = 4;
  int startIndex = 0;
  late List<TrickCard?> seats;
  TrickOutcome? outcome;

  @override
  void initState() {
    super.initState();
    seats = List<TrickCard?>.filled(numPlayers, null);
  }

  void _setNumPlayers(int n) {
    setState(() {
      numPlayers = n;
      final old = seats;
      seats = List<TrickCard?>.filled(n, null);
      for (int i = 0; i < math.min(n, old.length); i++) seats[i] = old[i];
      startIndex = 0;
      outcome = null;
    });
  }

  void _simulate() {
    if (seats.any((c) => c == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 플레이어의 카드를 선택해주세요.')));
      return;
    }
    final r = TrickEngine.evaluate(
      seats: seats.cast<TrickCard>(),
      startIndex: startIndex,
    );
    setState(() => outcome = r);
  }

  void _clear() {
    setState(() {
      seats = List<TrickCard?>.filled(numPlayers, null);
      outcome = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('트릭 시뮬레이터')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            UiCard(
              child: Row(
                children: [
                  const Text('인원:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: numPlayers,
                    items: List.generate(7, (i) => i + 2)
                        .map((e) =>
                            DropdownMenuItem(value: e, child: Text('$e명')))
                        .toList(),
                    onChanged: (v) => _setNumPlayers(v ?? numPlayers),
                  ),
                  const SizedBox(width: 16),
                  const Text('선(리드):'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: startIndex,
                    items: List.generate(
                      numPlayers,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text('플레이어 ${i + 1}'),
                      ),
                    ).toList(),
                    onChanged: (v) =>
                        setState(() => startIndex = v ?? startIndex),
                  ),
                  const Spacer(),
                  if (outcome != null)
                    Flexible(
                      child: Text(outcome!.message, textAlign: TextAlign.end),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: _PolygonTable(
                  numPlayers: numPlayers,
                  startIndex: startIndex,
                  seats: seats,
                  onPick: (i) async {
                    final c = await showDialog<TrickCard>(
                      context: context,
                      builder: (_) => _CardPickerDialog(initial: seats[i]),
                    );
                    if (c != null) setState(() => seats[i] = c);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: seats.every((c) => c != null) ? _simulate : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('시뮬레이션 실행'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('초기화'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PolygonTable extends StatelessWidget {
  final int numPlayers;
  final int startIndex;
  final List<TrickCard?> seats;
  final ValueChanged<int> onPick;
  const _PolygonTable({
    Key? key,
    required this.numPlayers,
    required this.startIndex,
    required this.seats,
    required this.onPick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = math.min(MediaQuery.of(context).size.width, 360.0);
    final center = Offset(size / 2, size / 2);
    final radius = size * 0.36;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
              ),
            ),
          ),
          ...List.generate(numPlayers, (i) {
            final theta = -math.pi / 2 + 2 * math.pi * i / numPlayers;
            final pos = Offset(
              center.dx + math.cos(theta) * radius,
              center.dy + math.sin(theta) * radius,
            );
            final c = seats[i];
            final isLead = i == startIndex;
            return Positioned(
              left: pos.dx - 56,
              top: pos.dy - 42,
              width: 112,
              height: 84,
              child: UiCard(
                padding: const EdgeInsets.all(10),
                onTap: () => onPick(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        if (isLead) ...const [
                          SizedBox(width: 6),
                          Icon(Icons.flag_outlined, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c?.toString() ?? '카드 선택',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: c == null ? Colors.black54 : null,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/* ---- 카드 선택 다이얼로그 ---- */
class _CardPickerDialog extends StatefulWidget {
  final TrickCard? initial;
  const _CardPickerDialog({Key? key, this.initial}) : super(key: key);
  @override
  State<_CardPickerDialog> createState() => _CardPickerDialogState();
}

class _CardPickerDialogState extends State<_CardPickerDialog> {
  CardSuit? suit;
  int rank = 10;
  CardSpecial special = CardSpecial.none;

  @override
  void initState() {
    super.initState();
    _load(widget.initial);
  }

  void _load(TrickCard? c) {
    if (c == null) {
      suit = null;
      rank = 10;
      special = CardSpecial.none;
      return;
    }
    if (c.special != CardSpecial.none) {
      special = c.special;
      suit = null;
      rank = 10;
    } else {
      suit = c.suit;
      rank = c.rank ?? 10;
      special = CardSpecial.none;
    }
  }

  void _emit() {
    if (special != CardSpecial.none) {
      Navigator.pop(context, TrickCard.special(special));
    } else if (suit != null) {
      Navigator.pop(context, TrickCard.suit(suit, rank));
    }
  }

  Widget _suitChip(CardSuit s) {
    Color dot;
    switch (s) {
      case CardSuit.green:
        dot = Colors.lightGreen;
        break;
      case CardSuit.yellow:
        dot = Colors.amber;
        break;
      case CardSuit.purple:
        dot = Colors.purple;
        break;
      case CardSuit.black:
        dot = Colors.black;
        break;
    }
    return ChoiceChip(
      selected: suit == s && special == CardSpecial.none,
      onSelected: (_) {
        setState(() {
          suit = s;
          special = CardSpecial.none;
        });
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(suitLabel(s)),
        ],
      ),
    );
  }

  Widget _specialChip(CardSpecial sp, String label) {
    return ChoiceChip(
      selected: special == sp,
      onSelected: (_) {
        setState(() {
          special = sp;
          suit = null;
        });
      },
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('카드 선택'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _suitChip(CardSuit.green),
                _suitChip(CardSuit.yellow),
                _suitChip(CardSuit.purple),
                _suitChip(CardSuit.black),
                const SizedBox(width: 12),
                _specialChip(CardSpecial.pirate, '해적'),
                _specialChip(CardSpecial.mermaid, '인어'),
                _specialChip(CardSpecial.skullKing, '스컬킹'),
                _specialChip(CardSpecial.escape, '탈출'),
                _specialChip(CardSpecial.kraken, '크라켄'),
                _specialChip(CardSpecial.whiteWhale, '백고래'),
              ],
            ),
            const SizedBox(height: 12),
            if (special == CardSpecial.none && suit != null)
              Row(
                children: [
                  Text('${suitLabel(suit!)} 숫자:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 32,
                      magnification: 1.1,
                      scrollController: FixedExtentScrollController(
                        initialItem: (rank - 1).clamp(0, 13),
                      ),
                      onSelectedItemChanged: (i) =>
                          setState(() => rank = i + 1),
                      children: [
                        for (int v = 1; v <= 14; v++) Center(child: Text('$v')),
                      ],
                    ),
                  ),
                ],
              )
            else
              const Text(
                '특수 카드는 숫자 선택이 필요 없습니다.',
                style: TextStyle(color: Colors.black54),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(onPressed: _emit, child: const Text('선택')),
      ],
    );
  }
}

/* =======================
 * 알쏭달쏭(상황 모음집) - 새로 정리
 * ======================= */

class ConfusionGuidePage extends StatelessWidget {
  const ConfusionGuidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sections = <(String, List<String>)>[
      (
        '특수카드 상호작용 우선순위',
        [
          '우위는 순환 구조: 해적 > 인어 > 스컬킹 > 해적.',
          '같은 종류가 둘 이상이면 먼저 낸 플레이어가 승리.',
          '특수 우위가 하나라도 존재하면, 숫자카드는 승부에서 제외.',
          '스컬킹이 해적을 이기면 잡은 해적 장수 × 30점 보너스.',
        ],
      ),
      (
        '백고래 & 크라켄',
        [
          '백고래: 이 트릭의 모든 특수효과 무효화. 숫자/수트 규칙으로만 승부.',
          '크라켄: 트릭 무효(승자 없음). 다음 리드는 “크라켄을 제외하고 평가했을 때의 승자”.',
          '백고래와 크라켄이 함께 나오면 가장 나중에 낸 카드의 효과가 최종 적용.',
        ],
      ),
      (
        '리드/수트 규칙(숫자 승부)',
        [
          '리드 수트는 가장 먼저 나온 숫자카드의 수트.',
          '검정(트럼프)이 있다면 검정끼리 비교, 가장 큰 수가 승리.',
          '검정이 없으면 리드 수트끼리 비교, 가장 큰 수가 승리.',
          '숫자카드가 한 장도 없었다면 승자 없음(백고래가 있으면 위 규칙으로 재평가).',
        ],
      ),
      (
        '탈출(스케이프)',
        [
          '수트에 참여하지 않는 “패스” 카드. 우승 판정에 직접 관여하지 않음.',
          '리드 수트 결정에도 영향을 주지 않음.',
        ],
      ),
      (
        '0비딩/보너스 메모',
        [
          '0비딩 성공: 라운드 × 10점, 실패: 라운드 × (-10)점.',
          '비딩 성공 시 가산점은 UI에서 직접 입력(기본 0~200, 10단위).',
        ],
      ),
      (
        '자주 헷갈리는 포인트',
        [
          '스컬킹과 인어가 함께 나오면 인어 승(+50).',
          '해적이 하나라도 있으면 숫자/인어는 제외, 가장 먼저 낸 해적이 승리.',
          '크라켄이 나온 트릭은 트릭 수에 미포함. 라운드 검증은 “트릭 합 + 크라켄 수 = 라운드 수”.',
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('알쏭달쏭')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: sections.length,
        itemBuilder: (_, i) {
          final (title, lines) = sections[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: UiCard(
              child: ExpansionTile(
                title: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: lines
                    .map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(t)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* =======================
 * 룰북 & 설정
 * ======================= */

class RulebookPage extends StatelessWidget {
  const RulebookPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final items = <_RuleItem>[
      _RuleItem(
        '비딩/점수 요약',
        'bid>0: 정확히 맞추면 +20×bid, 빗나가면 -10×|차이|.\n'
            'bid=0: 성공 +10×라운드, 실패 -10×라운드.',
      ),
      _RuleItem(
        '특수카드 요약(핵심)',
        '• 인어: 숫자카드 전부를 이김(해적에게는 짐). 스컬킹과 함께 나오면 인어 승(+50).\n'
            '• 스컬킹: 해적/숫자카드를 이김(인어에게 짐). 해적 포획 +30/장.\n'
            '• 백고래: 특수효과 무력화 → 리드 수트 최고 승.\n'
            '• 크라켄: 트릭 무효. 다음 리드는 "크라켄 제외 시 승자".',
      ),
      _RuleItem('검정/리드 규칙', '검정(트럼프)이 있으면 숫자 비교에서 우선. 없으면 리드 수트 최고가 승.'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('룰북&상호작용')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final it = items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: UiCard(
              child: ExpansionTile(
                title: Text(it.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(it.body),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RuleItem {
  final String title;
  final String body;
  _RuleItem(this.title, this.body);
}

class RuleEditorSheet extends StatefulWidget {
  final RuleProfile rules;
  const RuleEditorSheet({Key? key, required this.rules}) : super(key: key);
  @override
  State<RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<RuleEditorSheet> {
  late int _rounds;
  late int _hitBase;
  late int _hitTrickBonus;
  late int _missPenalty;
  late int _zeroHit;
  late int _zeroMiss;
  late bool _validateSum;

  @override
  void initState() {
    super.initState();
    final r = widget.rules;
    _rounds = r.totalRounds;
    _hitBase = r.hitBidBasePerBid;
    _hitTrickBonus = r.hitTrickBonusPerTrick;
    _missPenalty = r.missPenaltyPerDiff;
    _zeroHit = r.zeroHitPerRound;
    _zeroMiss = r.zeroMissPerRound;
    _validateSum = r.validateTotalTricksEqualsRound;
  }

  Widget _numField({
    required String label,
    required int value,
    required void Function(int) onChanged,
    String hint = '',
  }) {
    final ctrl = TextEditingController(text: '$value');
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, helperText: hint),
      onChanged: (v) {
        final n = int.tryParse(v);
        if (n != null) onChanged(n);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewInsets.bottom + 16.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, pad),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              '설정',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            UiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('테마'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in kThemePalette)
                        GestureDetector(
                          onTap: () => setState(() => themeSeed.value = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            UiCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('총 라운드'),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: _rounds,
                        items: const [7, 10, 13]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text('$e')))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _rounds = v ?? _rounds),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Text('트릭 합계 검증'),
                          Switch(
                            value: _validateSum,
                            onChanged: (v) => setState(() => _validateSum = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 3.2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _numField(
                        label: '비드 성공(×bid)',
                        value: _hitBase,
                        onChanged: (n) => _hitBase = n,
                        hint: '기본 20',
                      ),
                      _numField(
                        label: '성공 트릭 보너스(×tricks)',
                        value: _hitTrickBonus,
                        onChanged: (n) => _hitTrickBonus = n,
                        hint: '보통 0',
                      ),
                      _numField(
                        label: '실패 패널티(×|차이|)',
                        value: _missPenalty,
                        onChanged: (n) => _missPenalty = n,
                        hint: '기본 -10',
                      ),
                      _numField(
                        label: '0비딩 성공(×round)',
                        value: _zeroHit,
                        onChanged: (n) => _zeroHit = n,
                        hint: '기본 10',
                      ),
                      _numField(
                        label: '0비딩 실패(×round)',
                        value: _zeroMiss,
                        onChanged: (n) => _zeroMiss = n,
                        hint: '기본 -10',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(
                  context,
                  RuleProfile(
                    totalRounds: _rounds,
                    hitBidBasePerBid: _hitBase,
                    hitTrickBonusPerTrick: _hitTrickBonus,
                    missPenaltyPerDiff: _missPenalty,
                    zeroHitPerRound: _zeroHit,
                    zeroMissPerRound: _zeroMiss,
                    validateTotalTricksEqualsRound: _validateSum,
                  ),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('적용'),
            ),
          ],
        ),
      ),
    );
  }
}
