package br.com.talhao.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.talhao.dto.ExclusaoTalhaoRequest;
import br.com.talhao.dto.TalhaoRequest;
import br.com.talhao.dto.TalhaoResponse;
import br.com.talhao.service.TalhaoService;

import jakarta.validation.Valid;

// Recebe as requisicoes HTTP relacionadas aos talhoes.
// O usuario vem do JwtAuthInterceptor (atributo "usuarioIdAutenticado").
@RestController
@RequestMapping("/api/talhoes")
public class TalhaoController {

    private final TalhaoService talhaoService;

    // Recebe o Service pelo construtor
    public TalhaoController(TalhaoService talhaoService) {
        this.talhaoService = talhaoService;
    }

    // Cadastra um talhao
    @PostMapping
    public ResponseEntity<TalhaoResponse> criar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @Valid @RequestBody TalhaoRequest dados) {

        TalhaoResponse talhao = talhaoService.criar(usuarioId, dados);

        return ResponseEntity.status(HttpStatus.CREATED).body(talhao);
    }

    // Lista os talhoes do usuario autenticado
    @GetMapping
    public ResponseEntity<List<TalhaoResponse>> listar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId) {

        return ResponseEntity.ok(talhaoService.listar(usuarioId));
    }

    // Detalha um talhao, com a quantidade de safras e analises
    @GetMapping("/{id}")
    public ResponseEntity<TalhaoResponse> buscar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String id) {

        return ResponseEntity.ok(talhaoService.buscar(id, usuarioId));
    }

    // Edita nome e area de um talhao
    @PutMapping("/{id}")
    public ResponseEntity<TalhaoResponse> atualizar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String id,
            @Valid @RequestBody TalhaoRequest dados) {

        return ResponseEntity.ok(
                talhaoService.atualizar(id, usuarioId, dados)
        );
    }

    // Exclui um talhao, desde que o nome seja digitado corretamente
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String id,
            @Valid @RequestBody ExclusaoTalhaoRequest dados) {

        talhaoService.excluir(id, usuarioId, dados.confirmacaoNome());

        return ResponseEntity.noContent().build();
    }
}
