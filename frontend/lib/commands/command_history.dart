import 'canvas_command.dart';

class CommandHistory {
  final List<CanvasCommand> _undoStack = [];
  final List<CanvasCommand> _redoStack = [];

  void execute(CanvasCommand command) {
    command.execute();
    _undoStack.add(command);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isNotEmpty) {
      final command = _undoStack.removeLast();
      command.undo();
      _redoStack.add(command);
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final command = _redoStack.removeLast();
      command.execute();
      _undoStack.add(command);
    }
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
}
