
package br.com.talhao.exception;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

// Centraliza o tratamento de erros da API.
@RestControllerAdvice
public class ApiExceptionHandler {

    // Trata erros de validação dos DTOs.
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> tratarValidacao(
            MethodArgumentNotValidException exception) {

        // Armazena os campos que possuem erros.
        Map<String, String> campos = new LinkedHashMap<>();

        // Percorre todos os erros de validação.
        exception.getBindingResult()
            .getFieldErrors()
            .forEach(erro -> {
                campos.putIfAbsent(
                    erro.getField(),
                    erro.getDefaultMessage() == null
                        ? "Valor inválido"
                        : erro.getDefaultMessage()
                );
            });

        // Organiza a resposta enviada ao frontend.
        Map<String, Object> resposta = new LinkedHashMap<>();

        resposta.put("erro", "Dados inválidos");
        resposta.put("campos", campos);

        // Retorna HTTP 400 (Bad Request).
        return ResponseEntity.badRequest().body(resposta);
    }

    // Trata requisições com JSON inválido.
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, String>> tratarJsonInvalido(
            HttpMessageNotReadableException exception) {

        return ResponseEntity.badRequest().body(
            Map.of("erro", "O corpo da requisição é inválido")
        );
    }
}
