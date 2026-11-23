package br.com.talhao.controller;

import jakarta.validation.Valid;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.talhao.dto.RecuperacaoSenhaRequest;
import br.com.talhao.dto.RecuperacaoSenhaResponse;
import br.com.talhao.dto.RedefinicaoSenhaRequest;
import br.com.talhao.service.RecuperacaoSenhaService;

// Rotas abertas (sem token) da recuperacao de senha (RF03)
@RestController
@RequestMapping("/api/usuarios")
public class RecuperacaoSenhaController {

    private final RecuperacaoSenhaService recuperacaoSenhaService;

    public RecuperacaoSenhaController(
            RecuperacaoSenhaService recuperacaoSenhaService) {

        this.recuperacaoSenhaService = recuperacaoSenhaService;
    }

    // Pede um codigo de recuperacao para o e-mail informado
    @PostMapping("/recuperar-senha")
    public ResponseEntity<RecuperacaoSenhaResponse> solicitar(
            @Valid @RequestBody RecuperacaoSenhaRequest dados) {

        return ResponseEntity.ok(
                recuperacaoSenhaService.solicitar(dados.email())
        );
    }

    // Troca a senha usando o codigo
    @PostMapping("/redefinir-senha")
    public ResponseEntity<Void> redefinir(
            @Valid @RequestBody RedefinicaoSenhaRequest dados) {

        recuperacaoSenhaService.redefinir(
                dados.email(),
                dados.codigo(),
                dados.novaSenha()
        );

        return ResponseEntity.noContent().build();
    }
}
