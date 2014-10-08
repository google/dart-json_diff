part of shapeshift;

/// Return the full URL for dart core APIs.
String fullDartlangLocation(String qualifiedName) =>
    'https://api.dartlang.org/apidocs/channels/dev'
    '/dartdoc-viewer/' + Uri.encodeFull(qualifiedName);

String mdLinkToDartlang(String qualifiedName) {
  return '[${decoratedName(qualifiedName)}](${fullDartlangLocation(qualifiedName)})';
}

String decoratedName(String qualifiedName) {
  return qualifiedName
        .replaceAll("_", "\\_")
        .replaceFirst("dart-core.", "")
        .replaceAll('-dom-', '-')
        .replaceAll('-', ':');
}