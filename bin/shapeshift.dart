import 'package:shapeshift/shapeshift.dart';
import 'package:args/args.dart';

class Shapeshift {
  ArgResults args;
  
  void go(List<String> arguments) {
    parseArgs(arguments);
    String left = args.rest[0];
    String right = args.rest[1];
    String leftPath = "${args['base']}/$left";
    String rightPath = "${args['base']}/$right";
    if (args['subset'].isNotEmpty) {
      leftPath += "/${args['subset']}";
      rightPath += "/${args['subset']}";
    }
    new PackageReporter(leftPath, rightPath, out: args['out'])
        ..calculateAllDiffs()..report();
  }
  
  void parseArgs(List<String> arguments) {
    var parser = new ArgParser();
    parser.addOption('base', defaultsTo: '/Users/srawlins/code/dartlang.org/api-docs');
    parser.addOption('subset', defaultsTo: '');
    parser.addOption('out');
    args = parser.parse(arguments);
  }
}

void main(List<String> arguments) => new Shapeshift().go(arguments);