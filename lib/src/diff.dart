import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/util.dart';

class Diff {
  final BasicInfo info;
  final DiffKind kind;
  Diff(this.info, this.kind);
}

enum DiffKind { add, remove, size, deferred }

class RemoveDiff extends Diff {
  RemoveDiff(BasicInfo info) : super(info, DiffKind.remove);
}

class AddDiff extends Diff {
  AddDiff(BasicInfo info) : super(info, DiffKind.add);
}

class SizeDiff extends Diff {
  final int sizeDifference;
  SizeDiff(BasicInfo info, this.sizeDifference) : super(info, DiffKind.size);
}

class DeferredStatusDiff extends Diff {
  final bool wasDeferredBefore;
  DeferredStatusDiff(BasicInfo info, this.wasDeferredBefore)
      : super(info, DiffKind.deferred);
}

List<Diff> diff(AllInfo oldInfo, AllInfo newInfo) {
  var differ = new _InfoDiffer(oldInfo, newInfo);
  differ.diff();
  return differ.diffs;
}

class _InfoDiffer extends InfoVisitor<Null, BasicInfo> {
  final AllInfo _old;
  final AllInfo _new;

  List<Diff> diffs = <Diff>[];

  _InfoDiffer(this._old, this._new);

  void diff() {
    _diffList(_old.libraries, _new.libraries);
  }

  @override
  visitAll(AllInfo info, [BasicInfo context]) {
    throw new StateError('should not diff AllInfo');
  }

  @override
  visitProgram(ProgramInfo info, [BasicInfo context]) {
    throw new StateError('should not diff ProgramInfo');
  }

  @override
  visitOutput(OutputUnitInfo info, [BasicInfo context]) {
    throw new StateError('should not diff OutputUnitInfo');
  }

  // TODO(het): diff constants
  @override
  visitConstant(ConstantInfo info, [BasicInfo context]) {
    throw new StateError('should not diff ConstantInfo');
  }

  @override
  visitLibrary(LibraryInfo info, [BasicInfo context]) {
    var other = context as LibraryInfo;
    _checkSize(info, other);
    _diffList(info.topLevelVariables, other.topLevelVariables);
    _diffList(info.topLevelFunctions, other.topLevelFunctions);
    _diffList(info.classes, other.classes);
  }

  @override
  visitClass(ClassInfo info, [BasicInfo context]) {
    var other = context as ClassInfo;
    _checkSize(info, other);
    _checkDeferredStatus(info, other);
    _diffList(info.fields, other.fields);
    _diffList(info.functions, other.functions);
  }

  @override
  visitClosure(ClosureInfo info, [BasicInfo context]) {
    var other = context as ClosureInfo;
    _checkSize(info, other);
    _checkDeferredStatus(info, other);
    _diffList([info.function], [other.function]);
  }

  @override
  visitField(FieldInfo info, [BasicInfo context]) {
    var other = context as FieldInfo;
    _checkSize(info, other);
    _checkDeferredStatus(info, other);
    _diffList(info.closures, other.closures);
  }

  @override
  visitFunction(FunctionInfo info, [BasicInfo context]) {
    var other = context as FunctionInfo;
    _checkSize(info, other);
    _checkDeferredStatus(info, other);
    _diffList(info.closures, other.closures);
  }

  @override
  visitTypedef(TypedefInfo info, [BasicInfo context]) {
    var other = context as TypedefInfo;
    _checkSize(info, other);
    _checkDeferredStatus(info, other);
  }

  void _checkSize(BasicInfo info, BasicInfo other) {
    if (info.size != other.size) {
      diffs.add(new SizeDiff(info, other.size - info.size));
    }
  }

  void _checkDeferredStatus(BasicInfo oldInfo, BasicInfo newInfo) {
    var oldIsDeferred = _isDeferred(oldInfo);
    var newIsDeferred = _isDeferred(newInfo);
    if (oldIsDeferred != newIsDeferred) {
      diffs.add(new DeferredStatusDiff(oldInfo, oldIsDeferred));
    }
  }

  bool _isDeferred(BasicInfo info) {
    var outputUnit = info.outputUnit;
    return outputUnit.name != null &&
        outputUnit.name.isNotEmpty &&
        outputUnit.name != 'main';
  }

  void _diffList(List<BasicInfo> oldInfos, List<BasicInfo> newInfos) {
    var oldNames = <String, BasicInfo>{};
    var newNames = <String, BasicInfo>{};
    for (var oldInfo in oldInfos) {
      oldNames[longName(oldInfo, useLibraryUri: true)] = oldInfo;
    }
    for (var newInfo in newInfos) {
      newNames[longName(newInfo, useLibraryUri: true)] = newInfo;
    }
    for (var oldName in oldNames.keys) {
      if (newNames[oldName] == null) {
        diffs.add(new RemoveDiff(oldNames[oldName]));
      } else {
        oldNames[oldName].accept(this, newNames[oldName]);
      }
    }
    for (var newName in newNames.keys) {
      if (oldNames[newName] == null) {
        diffs.add(new AddDiff(newNames[newName]));
      }
    }
  }
}
