package br.com.talhao.exception;

import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import br.com.talhao.dto.ErroValidacaoResponse;

// Centraliza o tratamento de erros dos controllers
@RestControllerAdvice
public class TratadorDeErros {

    // Trata os campos que falharam na validacao
    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ErroValidacaoResponse tratarValidacao(
            MethodArgumentNotValidException erro) {

        // Guarda o nome do campo e a mensagem correspondente
        Map<String, String> campos = new LinkedHashMap<>();

        for (var campo : erro.getBindingResult().getFieldErrors()) {
            // Mantem uma mensagem por campo
            campos.putIfAbsent(
                campo.getField(),
                campo.getDefaultMessage()
            );
        }

        return new ErroValidacaoResponse(
            "Confira os campos informados.",
            campos
        );
    }
}