// Copyright 2014 Google Inc. All Rights Reserved.
// Licensed under the Apache License, Version 2.0, found in the LICENSE file.


/// A library for determining the difference between two JSON objects.
///
/// ## Usage
///
/// In order to diff two JSON objects, stored as Dart strings, create a new
/// [JsonDiffer], passing the two objects:
///
///     JsonDiffer differ = new JsonDiffer(leftJsonString, rightJsonString)
///
/// To calculate the diff between the two objects, call `diff()` on the
/// [JsonDiffer], which will return a [DiffNode]:
///
///     DiffNode diff = differ.diff();
///
/// This [DiffNode] object is a hierarchical structure (like JSON) of the
/// differences between the two objects.
library json_diff;

import 'dart:convert';
import 'package:collection/equality.dart';

part 'src/diff_node.dart';
part 'src/json_differ.dart';
