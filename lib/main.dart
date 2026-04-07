import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '計算機',
      debugShowCheckedModeBanner: false,
      home: const CalculatorPage(),
    );
  }
}

class CalcTheme {
  final String name;
  final Color bg;
  final Color numBtn;
  final Color funcBtn;
  final Color funcFg;
  final Color opBtn;
  final Color opFg;
  const CalcTheme({
    required this.name,
    required this.bg,
    required this.numBtn,
    required this.funcBtn,
    required this.funcFg,
    required this.opBtn,
    required this.opFg,
  });
}

const _themes = [
  CalcTheme(
    name: 'オレンジ',
    bg:      Color(0xFFFF8C00),
    numBtn:  Color(0xFFCC6600),
    funcBtn: Color(0xFFFFB347),
    funcFg:  Color(0xFFCC6600),
    opBtn:   Colors.white,
    opFg:    Color(0xFFFF8C00),
  ),
  CalcTheme(
    name: 'レッド',
    bg:      Color(0xFFE53935),
    numBtn:  Color(0xFFB71C1C),
    funcBtn: Color(0xFFEF9A9A),
    funcFg:  Color(0xFFB71C1C),
    opBtn:   Colors.white,
    opFg:    Color(0xFFE53935),
  ),
  CalcTheme(
    name: 'イエロー',
    bg:      Color(0xFFFDD835),
    numBtn:  Color(0xFFF9A825),
    funcBtn: Color(0xFFFFF176),
    funcFg:  Color(0xFFF57F17),
    opBtn:   Colors.white,
    opFg:    Color(0xFFF57F17),
  ),
  CalcTheme(
    name: 'グリーン',
    bg:      Color(0xFF43A047),
    numBtn:  Color(0xFF1B5E20),
    funcBtn: Color(0xFFA5D6A7),
    funcFg:  Color(0xFF1B5E20),
    opBtn:   Colors.white,
    opFg:    Color(0xFF43A047),
  ),
  CalcTheme(
    name: 'ブルー',
    bg:      Color(0xFF1E88E5),
    numBtn:  Color(0xFF0D47A1),
    funcBtn: Color(0xFF90CAF9),
    funcFg:  Color(0xFF0D47A1),
    opBtn:   Colors.white,
    opFg:    Color(0xFF1E88E5),
  ),
  CalcTheme(
    name: 'パープル',
    bg:      Color(0xFF8E24AA),
    numBtn:  Color(0xFF4A148C),
    funcBtn: Color(0xFFCE93D8),
    funcFg:  Color(0xFF4A148C),
    opBtn:   Colors.white,
    opFg:    Color(0xFF8E24AA),
  ),
  CalcTheme(
    name: 'ピンク',
    bg:      Color(0xFFE91E8C),
    numBtn:  Color(0xFFAD1457),
    funcBtn: Color(0xFFF48FB1),
    funcFg:  Color(0xFFAD1457),
    opBtn:   Colors.white,
    opFg:    Color(0xFFE91E8C),
  ),
];

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  CalcTheme _theme    = _themes[0];
  double    _bgVivid  = 1.0;
  double    _btnVivid = 1.0;

  String _displayResult = '0';
  String _expression    = '';

  double? _firstOperand;
  String?  _operator;
  bool     _waitingForSecond = false;
  bool     _justCalculated   = false;

  Color _blendBg(Color vivid) {
    final pastel = Color.lerp(Colors.white, vivid, 0.45)!;
    return Color.lerp(pastel, vivid, _bgVivid)!;
  }

  Color _blendBtn(Color vivid) {
    final pastel = Color.lerp(Colors.white, vivid, 0.45)!;
    return Color.lerp(pastel, vivid, _btnVivid)!;
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SettingsSheet(
          currentTheme:    _theme,
          currentBgVivid:  _bgVivid,
          currentBtnVivid: _btnVivid,
          onThemeChanged:  (t) => setState(() => _theme = t),
          onBgVividChanged:  (v) => setState(() => _bgVivid = v),
          onBtnVividChanged: (v) => setState(() => _btnVivid = v),
        );
      },
    );
  }

  void _onTap(String label) {
    setState(() {
      if (label == 'AC') {
        _expression       = '';
        _displayResult    = '0';
        _firstOperand     = null;
        _operator         = null;
        _waitingForSecond = false;
        _justCalculated   = false;
      } else if (label == '⌫') {
        if (_displayResult.length > 1) {
          _displayResult = _displayResult.substring(0, _displayResult.length - 1);
        } else {
          _displayResult = '0';
        }
      } else if (label == '+/-') {
        if (_displayResult != '0') {
          if (_displayResult.startsWith('-')) {
            _displayResult = _displayResult.substring(1);
          } else {
            _displayResult = '-$_displayResult';
          }
        }
      } else if (label == '%') {
        final v = double.tryParse(_displayResult) ?? 0;
        _displayResult = _fmt(v / 100);
      } else if (label == '=') {
        if (_firstOperand != null && _operator != null && !_waitingForSecond) {
          final second = double.tryParse(_displayResult) ?? 0;
          final res    = _calc(_firstOperand!, _operator!, second);
          _expression    = '${_fmtForExpr(_firstOperand!)} $_operator ${_fmtForExpr(second)} =';
          _displayResult = _fmt(res);
          _firstOperand  = null;
          _operator      = null;
          _waitingForSecond = false;
          _justCalculated   = true;
        }
      } else if (['+', '-', '×', '÷'].contains(label)) {
        if (_firstOperand != null && _operator != null && !_waitingForSecond) {
          final second = double.tryParse(_displayResult) ?? 0;
          final res    = _calc(_firstOperand!, _operator!, second);
          _displayResult = _fmt(res);
          _firstOperand  = res;
          _expression    = '${_fmtForExpr(res)} $label';
        } else {
          _firstOperand = double.tryParse(_displayResult) ?? 0;
          _expression   = '${_fmtForExpr(_firstOperand!)} $label';
        }
        _operator         = label;
        _waitingForSecond = true;
        _justCalculated   = false;
      } else {
        if (_justCalculated) {
          _displayResult  = label == '.' ? '0.' : label;
          _expression     = '';
          _justCalculated = false;
        } else if (_waitingForSecond) {
          _displayResult    = label == '.' ? '0.' : label;
          _waitingForSecond = false;
        } else {
          if (label == '.' && _displayResult.contains('.')) return;
          _displayResult = (_displayResult == '0' && label != '.')
              ? label
              : _displayResult + label;
        }
      }
    });
  }

  double _calc(double a, String op, double b) {
    switch (op) {
      case '+': return a + b;
      case '-': return a - b;
      case '×': return a * b;
      case '÷': return b != 0 ? a / b : double.nan;
      default:  return b;
    }
  }

  String _fmt(double n) {
    if (n.isNaN || n.isInfinite) return 'Error';
    if (n == n.truncateToDouble() && n.abs() < 1e15) {
      return n.toInt().toString();
    }
    return n.toString();
  }

  String _fmtForExpr(double n) => _fmt(n);

  @override
  Widget build(BuildContext context) {
    final t         = _theme;
    final bgColor   = _blendBg(t.bg);
    final numColor  = _blendBtn(t.numBtn);
    final funcColor = _blendBtn(t.funcBtn);
    final funcFg    = _blendBtn(t.funcFg);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                onPressed: _openSettings,
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _expression,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final len = _displayResult.length;
                        double fontSize;
                        if (len <= 6) {
                          fontSize = 80;
                        } else if (len <= 12) {
                          fontSize = 60;
                        } else if (len <= 18) {
                          fontSize = 44;
                        } else {
                          fontSize = 32;
                        }
                        return SizedBox(
                          width: constraints.maxWidth,
                          child: Text(
                            _displayResult,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w300,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.right,
                            softWrap: true,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const cols      = 4;
                  const hPad      = 12.0;
                  const spacing   = 10.0;
                  const vPad      = 8.0;
                  const bottomPad = 12.0;
                  final btnW = (constraints.maxWidth - hPad * 2 - spacing * (cols - 1)) / cols;
                  const rows = 5;
                  final btnH = (constraints.maxHeight - vPad - bottomPad - spacing * (rows - 1)) / rows;
                  final btnSize = btnW < btnH ? btnW : btnH;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(hPad, vPad, hPad, bottomPad),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRow([
                          _BtnData(label: '⌫',  bg: funcColor, fg: funcFg,     bold: true),
                          _BtnData(label: 'AC', bg: funcColor, fg: funcFg,     bold: true),
                          _BtnData(label: '%',  bg: funcColor, fg: funcFg,     bold: true),
                          _BtnData(label: '÷',  bg: t.opBtn,   fg: t.opFg,     bold: true, opSize: true),
                        ], btnSize, spacing),
                        _buildRow([
                          _BtnData(label: '7', bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '8', bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '9', bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '×', bg: t.opBtn,  fg: t.opFg,       bold: true, opSize: true),
                        ], btnSize, spacing),
                        _buildRow([
                          _BtnData(label: '4', bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '5', bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '6', bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '-', bg: t.opBtn,  fg: t.opFg,       bold: true, opSize: true),
                        ], btnSize, spacing),
                        _buildRow([
                          _BtnData(label: '1', bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '2', bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '3', bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '+', bg: t.opBtn,  fg: t.opFg,       bold: true, opSize: true),
                        ], btnSize, spacing),
                        _buildRow([
                          _BtnData(label: '+/-', bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '0',   bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '.',   bg: numColor, fg: Colors.white, bold: true),
                          _BtnData(label: '=',   bg: t.opBtn,  fg: t.opFg,       bold: true, opSize: true),
                        ], btnSize, spacing),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<_BtnData> btns, double btnSize, double spacing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: btns
          .map((d) => _CircleButton(data: d, onTap: _onTap, size: btnSize))
          .toList(),
    );
  }
}

// ── 設定シート ──
class _SettingsSheet extends StatefulWidget {
  final CalcTheme currentTheme;
  final double currentBgVivid;
  final double currentBtnVivid;
  final void Function(CalcTheme) onThemeChanged;
  final void Function(double) onBgVividChanged;
  final void Function(double) onBtnVividChanged;

  const _SettingsSheet({
    required this.currentTheme,
    required this.currentBgVivid,
    required this.currentBtnVivid,
    required this.onThemeChanged,
    required this.onBgVividChanged,
    required this.onBtnVividChanged,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late double    _bgVivid;
  late double    _btnVivid;
  late CalcTheme _selectedTheme; // ← 設定画面内で選択中のテーマを管理

  @override
  void initState() {
    super.initState();
    _bgVivid       = widget.currentBgVivid;
    _btnVivid      = widget.currentBtnVivid;
    _selectedTheme = widget.currentTheme;
  }

  Color _blendBg(Color vivid) {
    final pastel = Color.lerp(Colors.white, vivid, 0.45)!;
    return Color.lerp(pastel, vivid, _bgVivid)!;
  }

  Color _blendBtn(Color vivid) {
    final pastel = Color.lerp(Colors.white, vivid, 0.45)!;
    return Color.lerp(pastel, vivid, _btnVivid)!;
  }

  Widget _miniBtn(String label, Color bg, Color fg) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t         = _selectedTheme;
    final bgColor   = _blendBg(t.bg);
    final numColor  = _blendBtn(t.numBtn);
    final funcColor = _blendBtn(t.funcBtn);
    final funcFg    = _blendBtn(t.funcFg);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── ミニプレビュー ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'プレビュー',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _miniBtn('AC', funcColor, funcFg),
                      _miniBtn('%',  funcColor, funcFg),
                      _miniBtn('÷',  t.opBtn,   t.opFg),
                      _miniBtn('7',  numColor,  Colors.white),
                      _miniBtn('8',  numColor,  Colors.white),
                      _miniBtn('=',  t.opBtn,   t.opFg),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'テーマカラー',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _themes.map((t) {
                final isSelected = t.name == _selectedTheme.name;
                return GestureDetector(
                  onTap: () {
                    // 閉じずにプレビューだけ更新
                    setState(() => _selectedTheme = t);
                    widget.onThemeChanged(t);
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: t.bg,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              '背景スタイル',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('パステル', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Slider(
                    value: _bgVivid,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    activeColor: _selectedTheme.bg,
                    onChanged: (v) {
                      setState(() => _bgVivid = v);
                      widget.onBgVividChanged(v);
                    },
                  ),
                ),
                const Text('ビビッド', style: TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'ボタンスタイル',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('パステル', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: Slider(
                    value: _btnVivid,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    activeColor: _selectedTheme.bg,
                    onChanged: (v) {
                      setState(() => _btnVivid = v);
                      widget.onBtnVividChanged(v);
                    },
                  ),
                ),
                const Text('ビビッド', style: TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 16),

            // ── 閉じるボタン ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedTheme.bg,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '閉じる',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BtnData {
  final String label;
  final Color  bg;
  final Color  fg;
  final bool   bold;
  final bool   opSize;
  const _BtnData({
    required this.label,
    required this.bg,
    required this.fg,
    this.bold   = false,
    this.opSize = false,
  });
}

class _CircleButton extends StatelessWidget {
  final _BtnData               data;
  final void Function(String)  onTap;
  final double                 size;

  const _CircleButton({
    required this.data,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = data.opSize ? size * 0.42 : size * 0.30;

    return SizedBox(
      width:  size,
      height: size,
      child: Material(
        color:  data.bg,
        shape:  const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onTap(data.label),
          child: Center(
            child: Text(
              data.label,
              style: TextStyle(
                color:      data.fg,
                fontSize:   fontSize,
                fontWeight: data.bold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}