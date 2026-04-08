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

// bgVivid値とテーマカラーでテキスト色を返す
Color _textColor(double bgVivid, Color themeColor, {double opacity = 1.0}) {
  // ビビッド（0.6以上）→白、パステル→テーマカラーを暗くした色
  final base = bgVivid >= 0.6
      ? Colors.white
      : HSLColor.fromColor(themeColor)
          .withLightness(0.25)
          .withSaturation(0.8)
          .toColor();
  return opacity == 1.0 ? base : base.withOpacity(opacity);
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  CalcTheme _theme    = _themes[0];
  double    _bgVivid  = 1.0;
  double    _btnVivid = 1.0;
  int       _tabIndex = 0;

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
Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: '計算機',
                      selected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                      selectedColor: Colors.white,
                      unselectedColor: Colors.white38,
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: '時間計算',
                      selected: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                      selectedColor: Colors.white,
                      unselectedColor: Colors.white38,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                    onPressed: _openSettings,
                  ),
                ],
              ),
            ),
            if (_tabIndex == 0) ...[
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
            ] else ...[
              Expanded(
                child: TimeCalcPage(
                  bgColor:   bgColor,
                  numColor:  numColor,
                  funcColor: funcColor,
                  funcFg:    funcFg,
                  theme:     t,
                  bgVivid:   _bgVivid,
                ),
              ),
            ],
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

// ── タブボタン ──
class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected ? selectedColor : unselectedColor,
              fontSize: 16,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            height: 2,
            width: 48,
            decoration: BoxDecoration(
              color: selected ? selectedColor : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 時間計算ページ ──
class TimeCalcPage extends StatefulWidget {
  final Color bgColor;
  final Color numColor;
  final Color funcColor;
  final Color funcFg;
  final CalcTheme theme;
  final double bgVivid;

  const TimeCalcPage({
    super.key,
    required this.bgColor,
    required this.numColor,
    required this.funcColor,
    required this.funcFg,
    required this.theme,
    required this.bgVivid,
  });

  @override
  State<TimeCalcPage> createState() => _TimeCalcPageState();
}

class _TimeCalcPageState extends State<TimeCalcPage> {
  int _mode = 0;

  int? _startH, _startM, _endH, _endM;
  int? _baseH, _baseM, _durH, _durM;

  String _inputTarget = 'start';
  String _inputBuffer = '';

  String get _resultText {
    if (_mode == 0) {
      if (_startH == null || _endH == null) return '--:--';
      int diff = (_endH! * 60 + _endM!) - (_startH! * 60 + _startM!);
      if (diff < 0) diff += 24 * 60;
      return '${diff ~/ 60}時間${(diff % 60).toString().padLeft(2, '0')}分';
    } else {
      if (_baseH == null || _durH == null) return '--:--';
      int total = (_baseH! * 60 + _baseM! + _durH! * 60 + _durM!) % (24 * 60);
      return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
    }
  }

  String _fmtTime(int? h, int? m) {
    if (h == null) return '--:--';
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  void _setNow(String target) {
    final now = DateTime.now();
    setState(() {
      _inputTarget = target;
      _inputBuffer = '';
      if (target == 'start') { _startH = now.hour; _startM = now.minute; }
      else if (target == 'end')  { _endH = now.hour;   _endM = now.minute; }
      else if (target == 'base') { _baseH = now.hour;  _baseM = now.minute; }
    });
  }

  void _onKey(String key) {
    setState(() {
      if (key == 'AC') {
        _inputBuffer = '';
        _startH = _startM = _endH = _endM = null;
        _baseH = _baseM = _durH = _durM = null;
        return;
      }
      if (key == '⌫') {
        if (_inputBuffer.isNotEmpty) {
          _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
        }
        _applyBuffer();
        return;
      }
      if (_inputBuffer.length >= 4) return;
      _inputBuffer += key;
      _applyBuffer();
    });
  }

  void _applyBuffer() {
    if (_inputBuffer.isEmpty) {
      switch (_inputTarget) {
        case 'start': _startH = _startM = null; break;
        case 'end':   _endH   = _endM   = null; break;
        case 'base':  _baseH  = _baseM  = null; break;
        case 'dur':   _durH   = _durM   = null; break;
      }
      return;
    }
    final buf = _inputBuffer.padLeft(4, '0');
    final h = int.parse(buf.substring(0, 2)).clamp(0, 23);
    final m = int.parse(buf.substring(2, 4)).clamp(0, 59);
    switch (_inputTarget) {
      case 'start': _startH = h; _startM = m; break;
      case 'end':   _endH   = h; _endM   = m; break;
      case 'base':  _baseH  = h; _baseM  = m; break;
      case 'dur':   _durH   = h; _durM   = m; break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t         = widget.theme;
    final numColor  = widget.numColor;
    final funcColor = widget.funcColor;
    final funcFg    = widget.funcFg;

final primaryTxt   = _textColor(widget.bgVivid, widget.theme.bg);
    final secondaryTxt = _textColor(widget.bgVivid, widget.theme.bg, opacity: 0.6);
    final nowBg        = _textColor(widget.bgVivid, widget.theme.bg).withOpacity(0.15);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _ModeTab(label: '経過時間', selected: _mode == 0, color: t.opBtn,
                  onTap: () => setState(() { _mode = 0; _inputTarget = 'start'; _inputBuffer = ''; })),
                _ModeTab(label: '終了時刻', selected: _mode == 1, color: t.opBtn,
                  onTap: () => setState(() { _mode = 1; _inputTarget = 'base'; _inputBuffer = ''; })),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_mode == 0) ...[
            _TimeInputCard(
              label: '開始時刻',
              value: _fmtTime(_startH, _startM),
              selected: _inputTarget == 'start',
              primaryTxt: primaryTxt,
              secondaryTxt: secondaryTxt,
              nowBg: nowBg,
              onTap: () => setState(() { _inputTarget = 'start'; _inputBuffer = ''; }),
              onNow: () => _setNow('start'),
            ),
            const SizedBox(height: 8),
            _TimeInputCard(
              label: '終了時刻',
              value: _fmtTime(_endH, _endM),
              selected: _inputTarget == 'end',
              primaryTxt: primaryTxt,
              secondaryTxt: secondaryTxt,
              nowBg: nowBg,
              onTap: () => setState(() { _inputTarget = 'end'; _inputBuffer = ''; }),
              onNow: () => _setNow('end'),
            ),
          ] else ...[
            _TimeInputCard(
              label: '開始時刻',
              value: _fmtTime(_baseH, _baseM),
              selected: _inputTarget == 'base',
              primaryTxt: primaryTxt,
              secondaryTxt: secondaryTxt,
              nowBg: nowBg,
              onTap: () => setState(() { _inputTarget = 'base'; _inputBuffer = ''; }),
              onNow: () => _setNow('base'),
            ),
            const SizedBox(height: 8),
            _TimeInputCard(
              label: '経過時間 (時:分)',
              value: _fmtTime(_durH, _durM),
              selected: _inputTarget == 'dur',
              primaryTxt: primaryTxt,
              secondaryTxt: secondaryTxt,
              nowBg: nowBg,
              onTap: () => setState(() { _inputTarget = 'dur'; _inputBuffer = ''; }),
              onNow: null,
            ),
          ],

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _mode == 0 ? '経過時間' : '終了時刻',
                  style: TextStyle(
                    color: secondaryTxt,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _resultText,
                  style: TextStyle(
                    color: primaryTxt,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
const cols    = 3;
                const spacing = 10.0;
                final btnW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
                const rows = 4;
                final btnH = (constraints.maxHeight - spacing * (rows - 1)) / rows;
                final btnSize = btnW < btnH ? btnW : btnH;

                final keys = [
                  ['7', '8', '9'],
                  ['4', '5', '6'],
                  ['1', '2', '3'],
                  ['00', '0', '⌫'],
                ];

return Column(
                  children: keys.map((row) {
                    return Expanded(
                      child: Row(
                        children: row.map((key) {
                          final isFunc = key == '⌫';
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3.0),
                              child: Material(
                                color: isFunc ? funcColor : numColor,
                                borderRadius: BorderRadius.circular(12),
                                elevation: 2,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _onKey(key),
                                  child: Center(
                                    child: Text(
                                      key,
                                      style: TextStyle(
                                        color: isFunc ? funcFg : Colors.white,
                                        fontSize: btnSize * 0.28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── モード切替タブ ──
class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.black87 : Colors.white60,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 時刻入力カード ──
class _TimeInputCard extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final Color primaryTxt;
  final Color secondaryTxt;
  final Color nowBg;
  final VoidCallback onTap;
  final VoidCallback? onNow;

  const _TimeInputCard({
    required this.label,
    required this.value,
    required this.selected,
    required this.primaryTxt,
    required this.secondaryTxt,
    required this.nowBg,
    required this.onTap,
    required this.onNow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? Colors.white24 : Colors.black12,
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: Colors.white54, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: secondaryTxt,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(value,
                    style: TextStyle(
                        color: primaryTxt,
                        fontSize: 34,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const Spacer(),
            if (onNow != null)
              GestureDetector(
                onTap: onNow,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: nowBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryTxt.withOpacity(0.3)),
                  ),
                  child: Text('今',
                      style: TextStyle(
                          color: primaryTxt,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
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
  late CalcTheme _selectedTheme;

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
        child: Text(label,
            style: TextStyle(
                color: fg, fontSize: 13, fontWeight: FontWeight.bold)),
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
                  const Text('プレビュー',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
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
            const Text('テーマカラー',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _themes.map((t) {
                final isSelected = t.name == _selectedTheme.name;
                return GestureDetector(
                  onTap: () {
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
                      Text(t.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          )),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('背景スタイル',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
            const Text('ボタンスタイル',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                child: const Text('閉じる',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
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