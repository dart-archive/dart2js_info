// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:test/test.dart';

main() {
  group('parse', () {
    test('hello_world', () {
      var helloWorld = new File('test/hello_world/hello_world.js.info.json');
      var json = jsonDecode(helloWorld.readAsStringSync());
      var decoded = new AllInfoJsonCodec().decode(json);

      var program = decoded.program;
      expect(program, isNotNull);

      expect(program.entrypoint, isNotNull);
      expect(program.size, 10324);
      expect(program.compilationMoment,
          DateTime.parse("2017-04-17 09:46:41.661617"));
      expect(program.compilationDuration, new Duration(microseconds: 357402));
      expect(program.toJsonDuration, new Duration(milliseconds: 4));
      expect(program.dumpInfoDuration, new Duration(seconds: 0));
      expect(program.noSuchMethodEnabled, false);
      expect(program.minified, false);
    });

    test('hello_world_deferred', () {
      final helloWorldDeferred = new File(
          'test/hello_world_deferred/hello_world_deferred.js.info.json');
      final json = jsonDecode(helloWorldDeferred.readAsStringSync());
      final decoded = new AllInfoJsonCodec().decode(json);

      // There is only one deferred import, which should be from the main output unit
      // to the second output unit.
      expect(decoded.outputUnits, hasLength(2));
      expect(decoded.deferredImports, hasLength(1));
      final deferredImport = decoded.deferredImports.first;
      expect(deferredImport.name, "deferred_import");
      expect(deferredImport.parent, const TypeMatcher<LibraryInfo>());
      expect(deferredImport.requiredOutputUnits, hasLength(1));
      final requiredOutputUnit = deferredImport.requiredOutputUnits.first;
      expect(requiredOutputUnit.name, isNot("main"));
    });
  });
}
