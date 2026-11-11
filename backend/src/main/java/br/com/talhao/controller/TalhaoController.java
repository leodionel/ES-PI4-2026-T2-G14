package br.com.talhao.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.ExclusaoTalhaoRequest;
import br.com.talhao.dto.TalhaoRequest;
import br.com.talhao.dto.TalhaoResponse;
import br.com.talhao.service.TalhaoService;

import jakarta.validation.Valid;

// Recebe as requisicoes HTTP relacionadas aos talhoes
@RestController
@RequestMapping("/api/talhoes")
public class TalhaoController {

    private final TalhaoService talhaoService;
    private final JwtDecoder jwtDecoder;

    // Recebe as dependencias pelo construtor
    public TalhaoController(
            TalhaoService talhaoService,
            JwtDecoder jwtDecoder) {

        this.talhaoService = talhaoService;
        this.jwtDecoder = jwtDecoder;
    }

    // Cadastra um talhao
    @PostMapping
    public ResponseEntity<TalhaoResponse> criar(
            @RequestHeader(value = "Authorization", required = false)
            String authorization,
            @Valid @RequestBody TalhaoRequest dados) {

        TalhaoResponse talhao =
                talhaoService.criar(usuarioId(authorization), dados);

        return ResponseEntity.status(HttpStatus.CREATED).body(talhao);
    }

    // Lista os talhoes do usuario autenticado
    @GetMapping
    public ResponseEntity<List<TalhaoResponse>> listar(
            @RequestHeader(value = "Authorization", required = false)
            String authorization) {

        return ResponseEntity.ok(
                talhaoService.listar(usuarioId(authorization))
        );
    }

    // Detalha um talhao, com a quantidade de safras e analises
    @GetMapping("/{id}")
    public ResponseEntity<TalhaoResponse> buscar(
            @RequestHeader(value = "Authorization", required = false)
            String authorization,
            @PathVariable String id) {

        return ResponseEntity.ok(
                talhaoService.buscar(id, usuarioId(authorization))
        );
    }

    // Edita nome e area de um talhao
    @PutMapping("/{id}")
    public ResponseEntity<TalhaoResponse> atualizar(
            @RequestHeader(value = "Authorization", required = false)
            String authorization,
            @PathVariable String id,
            @Valid @RequestBody TalhaoRequest dados) {

        return ResponseEntity.ok(
                talhaoService.atualizar(id, usuarioId(authorization), dados)
        );
    }

    // Exclui um talhao, desde que o nome seja digitado corretamente
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(
            @RequestHeader(value = "Authorization", required = false)
            String authorization,
            @PathVariable String id,
            @Valid @RequestBody ExclusaoTalhaoRequest dados) {

        talhaoService.excluir(
                id,
                usuarioId(authorization),
                dados.confirmacaoNome()
        );

        return ResponseEntity.noContent().build();
    }

    // Obtem o ID do usuario a partir do token JWT (claim "sub").
    // Este e o unico ponto que depende de como o token e emitido.
    private String usuarioId(String authorization) {

        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Token ausente"
            );
        }

        try {
            String usuarioId = jwtDecoder
                    .decode(authorization.substring(7))
                    .getSubject();

            if (usuarioId == null || usuarioId.isBlank()) {
                throw new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Token invalido"
                );
            }

            return usuarioId;

        } catch (JwtException erro) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Token invalido",
                    erro
            );
        }
    }
}
