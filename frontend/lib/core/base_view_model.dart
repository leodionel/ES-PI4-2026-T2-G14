import 'package:flutter/foundation.dart';
import 'app_exception.dart';
import 'app_textos.dart';

// Estados da tela
enum UiStatus { inicial, carregando, sucesso, erro }

//Controle compartilhado pelas ViewModels
abstract class BaseViewModel extends ChangeNotifier {
  UiStatus _status = UiStatus.inicial;
  String? _erro;
  bool _descartado = false;

  UiStatus get status => _status;
  String? get erro => _erro;
  bool get carregando => _status == UiStatus.carregando;

  Future<void> executar(Future<void> Function() acao) async {
    // Evita repetir a acao enquanto ela esta em andamento
    if (_descartado || carregando) return;

    _status = UiStatus.carregando;
    _erro = null;
    notifyListeners();

    try {
      await acao();

      if (_descartado) return;
      _status = UiStatus.sucesso;
    } on AppException catch (erro) {
      if (_descartado) return;

      _status = UiStatus.erro;
      _erro = erro.mensagem;
    } catch (_) {
      if (_descartado) return;

      _status = UiStatus.erro;
      _erro = AppTextos.erroInesperado;
    }

    //Avisa a tela que os dados mudaram
    if (!_descartado) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Para de enviar atualizacao quando a viewmodel e encerrada
    _descartado = true;
    super.dispose();
  }
}
