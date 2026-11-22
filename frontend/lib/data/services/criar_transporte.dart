// Escolhe como falar com o servidor: sockets no celular e no desktop,
// HTTP no navegador. A escolha acontece na compilação.
export 'criar_transporte_io.dart'
    if (dart.library.js_interop) 'criar_transporte_web.dart';
