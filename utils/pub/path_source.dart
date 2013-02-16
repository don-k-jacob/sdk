// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library path_source;

import 'dart:async';
import 'dart:io';

import '../../pkg/path/lib/path.dart' as path;

import 'io.dart';
import 'package.dart';
import 'pubspec.dart';
import 'version.dart';
import 'source.dart';
import 'utils.dart';

// TODO(rnystrom): Support relative paths. (See comment in _validatePath().)
/// A package [Source] that installs packages from a given local file path.
class PathSource extends Source {
  final name = 'path';
  final shouldCache = false;

  Future<Pubspec> describe(PackageId id) {
    return defer(() {
      _validatePath(id.name, id.description);
      return new Pubspec.load(id.name, id.description["path"],
          systemCache.sources);
    });
  }

  Future<bool> install(PackageId id, String destination) {
    return defer(() {
      try {
        _validatePath(id.name, id.description);
      } on FormatException catch(err) {
        return false;
      }

      return createPackageSymlink(id.name, destination, id.description["path"],
          relative: id.description["relative"]);
    }).then((_) => true);
  }

  /// Parses a path dependency. This takes in a path string and returns a map.
  /// The "path" key will be the original path but resolves relative to the
  /// containing path. The "relative" key will be `true` if the original path
  /// was relative.
  ///
  /// A path coming from a pubspec is a simple string. From a lock file, it's
  /// an expanded {"path": ..., "relative": ...} map.
  dynamic parseDescription(String containingPath, description,
                           {bool fromLockFile: false}) {
    if (fromLockFile) {
      if (description is! Map) {
        throw new FormatException("The description must be a map.");
      }

      if (description["path"] is! String) {
        throw new FormatException("The 'path' field of the description must "
            "be a string.");
      }

      if (description["relative"] is! bool) {
        throw new FormatException("The 'relative' field of the description "
            "must be a boolean.");
      }

      return description;
    }

    if (description is! String) {
      throw new FormatException("The description must be a path string.");
    }

    // Resolve the path relative to the containing file path, and remember
    // whether the original path was relative or absolute.
    bool isRelative = path.isRelative(description);
    if (path.isRelative(description)) {
      // Can't handle relative paths coming from pubspecs that are not on the
      // local file system.
      assert(containingPath != null);

      description = path.join(path.dirname(containingPath), description);
    }

    return {
      "path": description,
      "relative": isRelative
    };
  }

  /// Ensures that [description] is a valid path description. It must be a map,
  /// with a "path" key containing a path that points to an existing directory.
  /// Throws a [FormatException] if the path is invalid.
  void _validatePath(String name, description) {
    var dir = description["path"];

    if (fileExists(dir)) {
      throw new FormatException(
          "Path dependency for package '$name' must refer to a "
          "directory, not a file. Was '$dir'.");
    }

    if (!dirExists(dir)) {
      throw new FormatException("Could not find package '$name' at '$dir'.");
    }
  }
}