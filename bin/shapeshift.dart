import 'dart:io';
import 'package:shapeshift/shapeshift.dart';

void main() {
  const String dir = "/Users/srawlins/code/dartlang.org/api-docs/";
  const String leftApi = "api_docs-v1.5.8";
  const String rightApi = "api_docs-v1.6.0";
  File leftFile, rightFile;
  
  PackageReporter packageReporter = new PackageReporter(
      "/Users/srawlins/code/dartlang.org/api-docs/$leftApi/docgen/args",
      "/Users/srawlins/code/dartlang.org/api-docs/$rightApi/docgen/args");
  
  packageReporter..calculateDiff("args.json")
      ..calculateDiff("args.ArgParser.json")
      ..calculateDiff("args.ArgResults.json")
      ..calculateDiff("args.Option.json")..report();
}