// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

int f(int x(String y)) => null;
String g(int x(String y)) => null;
var /*@topType=List<(<unknown>::(String y) → int x) → Object>*/ v = /*@typeArgs=(<unknown>::(String y) → int x) → Object*/ [
  f,
  g
];
