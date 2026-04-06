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

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
static const _bgColor   = Color(0xFFff8000); // 画面全体のオレンジ
static const _numColor  = Color(0xFFe07000); // 数字ボタンの背景色
static const _funcColor = Color(0xFFFFAA33); // 機能ボタンの背景色
static const _funcFg    = Color(0xFFe07000); // 機能ボタンの文字色
static const _opColor   = Colors.white; // 演算子ボタンの背景色
static const _orange    = Color(0xFFFF9800); // 演算子ボタンの文字色

  String _displayResult = '0';
  String _expression    = '';

  double? _firstOperand;
  String?  _operator;
  bool     _waitingForSecond = false;
  bool     _justCalculated   = false;

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
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── 表示エリア ──
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 上段：計算式
                    Text(
                      _expression,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 28,
                        height: 1.1, // 行間を狭く
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // 下段：数字を折り返し表示
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final len = _displayResult.length;
                        double fontSize;
                        if (len <= 6) {
                          fontSize = 96;
                        } else if (len <= 12) {
                          fontSize = 72;
                        } else if (len <= 18) {
                          fontSize = 52;
                        } else {
                          fontSize = 36;
                        }
                        return SizedBox(
                          width: constraints.maxWidth,
                          child: Text(
                            _displayResult,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w300,
                              height: 1.1, // 行間を狭く
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

            // ── ボタンエリア ──
            Expanded(
              flex: 6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const cols    = 4;
                  const hPad    = 12.0;
                  const spacing = 10.0;
                  final btnW = (constraints.maxWidth - hPad * 2 - spacing * (cols - 1)) / cols;
                  const rows    = 5;
                  const vPad    = 8.0;
                  final btnH = (constraints.maxHeight - vPad * 2 - spacing * (rows - 1)) / rows;
                  final btnSize = btnW < btnH ? btnW : btnH;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildRow([
                          _btn('⌫',  _funcColor, _funcFg),
                          _btn('AC', _funcColor, _funcFg),
                          _btn('%',  _funcColor, _funcFg),
                          _btn('÷',  _opColor,   _orange),
                        ], btnSize, spacing),
                        _buildRow([
                          _btn('7', _numColor, Colors.white),
                          _btn('8', _numColor, Colors.white),
                          _btn('9', _numColor, Colors.white),
                          _btn('×', _opColor,  _orange),
                        ], btnSize, spacing),
                        _buildRow([
                          _btn('4', _numColor, Colors.white),
                          _btn('5', _numColor, Colors.white),
                          _btn('6', _numColor, Colors.white),
                          _btn('-', _opColor,  _orange),
                        ], btnSize, spacing),
                        _buildRow([
                          _btn('1', _numColor, Colors.white),
                          _btn('2', _numColor, Colors.white),
                          _btn('3', _numColor, Colors.white),
                          _btn('+', _opColor,  _orange),
                        ], btnSize, spacing),
                        _buildRow([
                          _btn('+/-', _numColor, Colors.white),
                          _btn('0',   _numColor, Colors.white),
                          _btn('.',   _numColor, Colors.white),
                          _btn('=',   _opColor,  _orange),
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

  _BtnData _btn(String label, Color bg, Color fg) =>
      _BtnData(label: label, bg: bg, fg: fg);

  Widget _buildRow(List<_BtnData> btns, double btnSize, double spacing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: btns
          .map((d) => _CircleButton(data: d, onTap: _onTap, size: btnSize))
          .toList(),
    );
  }
}

class _BtnData {
  final String label;
  final Color  bg;
  final Color  fg;
  const _BtnData({required this.label, required this.bg, required this.fg});
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
                fontSize:   size * 0.30,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}