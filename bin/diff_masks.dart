// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/command_runner.dart';

import 'package:dart2js_info/src/mask_diff.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart';

import 'usage_exception.dart';

/// A command that computes the diff between type-mask from two info files.
class DiffMaskCommand extends Command<void> with PrintUsageException {
  final String name = "diff_masks";
  final String description =
      "See type mask differences between two dump-info files.";

  void run() async {
    var args = argResults.rest;
    if (args.length < 2) {
      usageException(
          'Missing arguments, expected two dump-info files to compare');
      return;
    }

    var oldInfo = await infoFromFile(args[0]);
    var newInfo = await infoFromFile(args[1]);

    var overallSizeDiff = newInfo.program.size - oldInfo.program.size;
    print('total_size_difference $overallSizeDiff');
    print('');
    var diffs = diff(oldInfo, newInfo);
    int total = diffs.length;
    int onlyNullTotal = 0;
    for (var diff in diffs) {
      bool onlyNull = _compareModuloNull(diff.oldMask, diff.newMask);
      if (onlyNull) {
        onlyNullTotal++;
      } else {
        print('\n${longName(diff.info, useLibraryUri: true)}:\n'
            '  old: ${diff.oldMask}\n'
            '  new: ${diff.newMask}');
      }
    }

    print("Only null: $onlyNullTotal of $total (remaining: ${total - onlyNullTotal}");
  }
}

bool _compareModuloNull(String a, String b) {
  int i = 0;
  int j = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }

    if (a[i] == "n" && a.substring(i, i+5) == "null|") {
      i+=5;
      continue;
    }

    return false;
  }

  return i == a.length && j == b.length;
}
