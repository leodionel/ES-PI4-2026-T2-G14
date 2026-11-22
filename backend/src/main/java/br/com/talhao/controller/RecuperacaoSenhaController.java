package br.com.talhao.controller;

import br.com.talhao.dto.RecuperacaoSenhaRequest;
import br.com.talhao.dto.RedefinirSenhaRequest;
import br.com.talhao.service.RecuperacaoSenhaService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/usuarios")
public class RecuperacaoSenhaController {
    private final RecuperacaoSenhaService service;

    public RecuperacaoSenhaController(RecuperacaoSenhaService service) {
        this.service = service;
    }

    @PostMapping("/recuperacao-senha")
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void solicitar(@Valid @RequestBody RecuperacaoSenhaRequest dados) {
        service.solicitar(dados.email());
    }

    @PostMapping("/redefinir-senha")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void redefinir(@Valid @RequestBody RedefinirSenhaRequest dados) {
        service.redefinir(dados);
    }
}
