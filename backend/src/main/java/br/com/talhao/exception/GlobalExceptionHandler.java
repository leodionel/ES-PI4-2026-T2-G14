
package br.com.talhao.exception;

import java.util.LinkedHashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;

import org.springframework.http.converter.HttpMessageNotReadableException;

import org.springframework.validation.FieldError;

import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import org.springframework.web.context.request.WebRequest;

import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

// Centraliza o tratamento dos erros da API REST
@RestControllerAdvice
public class GlobalExceptionHandler
        extends ResponseEntityExceptionHandler {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // Trata erros de validacao dos DTOs
    // Exemplo: email invalido ou campo obrigatorio vazio
    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException exception,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        Map<String, String> campos = new LinkedHashMap<>();

        for (FieldError erro :
                exception.getBindingResult().getFieldErrors()) {

            String mensagem = erro.getDefaultMessage() != null
                    ? erro.getDefaultMessage()
                    : "Valor invalido";

            campos.putIfAbsent(
                    erro.getField(),
                    mensagem
            );
        }

        ProblemDetail problema = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST,
                "Um ou mais campos possuem valores invalidos."
        );

        problema.setTitle("Erro de validacao");

        // Informacoes que o Flutter pode exibir em cada campo
        problema.setProperty("campos", campos);

        return handleExceptionInternal(
                exception,
                problema,
                headers,
                status,
                request
        );
    }

    // Trata JSON incorreto ou dados incompatíveis
    // Exemplo: enviar texto onde deveria existir um numero
    @Override
    protected ResponseEntity<Object> handleHttpMessageNotReadable(
            HttpMessageNotReadableException exception,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        ProblemDetail problema = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST,
                "O corpo da requisicao possui um JSON invalido ou dados incompatíveis."
        );

        problema.setTitle("Requisicao invalida");

        return handleExceptionInternal(
                exception,
                problema,
                headers,
                status,
                request
        );
    }

    // Trata erros inesperados sem revelar informacoes internas
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ProblemDetail> tratarErroInterno(
            Exception exception) {

        // Registra o erro nos logs do backend
        LOGGER.error("Erro inesperado na API", exception);

        ProblemDetail problema = ProblemDetail.forStatusAndDetail(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "Ocorreu um erro interno. Tente novamente."
        );

        problema.setTitle("Erro interno do servidor");

        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(problema);
    }
}
