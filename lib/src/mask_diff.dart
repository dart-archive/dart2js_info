import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/util.dart';

class MaskDiff {
  final BasicInfo info;
  final String oldMask;
  final String newMask;
  MaskDiff(this.info, this.oldMask, this.newMask);
}

List<MaskDiff> diff(AllInfo oldInfo, AllInfo newInfo) {
  var differ = new _InfoDiffer(oldInfo, newInfo);
  differ.diff();
  return differ.diffs;
}

class _InfoDiffer extends InfoVisitor<Null> {
  final AllInfo _old;
  final AllInfo _new;

  BasicInfo _other;

  List<MaskDiff> diffs = <MaskDiff>[];

  _InfoDiffer(this._old, this._new);

  void diff() {
    _diffList(_old.libraries, _new.libraries);
  }

  @override
  visitAll(AllInfo info) {
    throw new StateError('should not diff AllInfo');
  }

  @override
  visitProgram(ProgramInfo info) {
    throw new StateError('should not diff ProgramInfo');
  }

  @override
  visitOutput(OutputUnitInfo info) {
    throw new StateError('should not diff OutputUnitInfo');
  }

  // TODO(het): diff constants
  @override
  visitConstant(ConstantInfo info) {
    throw new StateError('should not diff ConstantInfo');
  }

  @override
  visitLibrary(LibraryInfo info) {
    var other = _other as LibraryInfo;
    _diffList(info.topLevelVariables, other.topLevelVariables);
    _diffList(info.topLevelFunctions, other.topLevelFunctions);
    _diffList(info.classes, other.classes);
  }

  @override
  visitClass(ClassInfo info) {
    var other = _other as ClassInfo;
    _diffList(info.fields, other.fields);
    _diffList(info.functions, other.functions);
  }

  @override
  visitClosure(ClosureInfo info) {
    var other = _other as ClosureInfo;
    _diffList([info.function], [other.function]);
  }

  @override
  visitField(FieldInfo info) {
    var other = _other as FieldInfo;
    if (info.type != other.type) {
      diffs.add(new MaskDiff(info, info.type, other.type));
    }
    _diffList(info.closures, other.closures);
  }

  String _signature(FunctionInfo info) {
    var sb = new StringBuffer();
    sb.write(info.returnType);
    sb.write("(");
    for (var parameter in info.parameters) {
      sb.write(parameter.type);
      sb.write(" ");
      sb.write(parameter.name);
      sb.write(",");
    }
    sb.write(")");
    return '$sb';
  }

  @override
  visitFunction(FunctionInfo info) {
    var other = _other as FunctionInfo;
    var infoSignature = _signature(info);
    var otherSignature = _signature(other);
    if (infoSignature != otherSignature) {
      diffs.add(new MaskDiff(info, infoSignature, otherSignature));
    }
    _diffList(info.closures, other.closures);
  }

  @override
  visitTypedef(TypedefInfo info) {}

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
        diffs.add(new MaskDiff(oldNames[oldName], "removed", ""));
      } else {
        _other = newNames[oldName];
        oldNames[oldName].accept(this);
      }
    }
    for (var newName in newNames.keys) {
      if (oldNames[newName] == null) {
        diffs.add(new MaskDiff(newNames[newName], "", "added"));
      }
    }
  }
}
