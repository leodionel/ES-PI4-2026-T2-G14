
package br.com.talhao.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;

import br.com.talhao.dto.CadastroAnaliseSoloRequest;
import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.service.AnaliseSoloService;

// Recebe as requisicoes HTTP relacionadas as analises de solo
@RestController
@RequestMapping("/api/analises-solo")
public class AnaliseSoloController {

    private final AnaliseSoloService analiseSoloService;

    // Injecao de dependencia do Service
    public AnaliseSoloController(
            AnaliseSoloService analiseSoloService) {

        this.analiseSoloService = analiseSoloService;
    }

    // Cadastra uma nova analise de solo
    @PostMapping
    public ResponseEntity<AnaliseSolo> cadastrar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @Valid @RequestBody CadastroAnaliseSoloRequest dados) {

        AnaliseSolo analise = analiseSoloService.cadastrar(
                usuarioId,
                dados
        );

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(analise);
    }

    // Lista todas as analises do usuario autenticado
    @GetMapping
    public ResponseEntity<List<AnaliseSolo>> listar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId) {

        List<AnaliseSolo> analises =
                analiseSoloService.listarPorUsuario(usuarioId);

        return ResponseEntity.ok(analises);
    }

    // Lista as analises de uma propriedade
    @GetMapping("/propriedade/{propriedadeId}")
    public ResponseEntity<List<AnaliseSolo>> listarPorPropriedade(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String propriedadeId) {

        List<AnaliseSolo> analises =
                analiseSoloService.listarPorPropriedade(
                        usuarioId,
                        propriedadeId
                );

        return ResponseEntity.ok(analises);
    }

    // Lista o historico de analises de um talhao
    @GetMapping("/propriedade/{propriedadeId}/talhao/{talhaoId}")
    public ResponseEntity<List<AnaliseSolo>> listarPorTalhao(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String propriedadeId,
            @PathVariable String talhaoId) {

        List<AnaliseSolo> analises =
                analiseSoloService.listarPorTalhao(
                        usuarioId,
                        propriedadeId,
                        talhaoId
                );

        return ResponseEntity.ok(analises);
    }

    // Busca uma analise pelo ID
    @GetMapping("/{id}")
    public ResponseEntity<AnaliseSolo> buscarPorId(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String id) {

        AnaliseSolo analise =
                analiseSoloService.buscarPorId(id, usuarioId);

        return ResponseEntity.ok(analise);
    }

    // Atualiza uma analise existente
    @PutMapping("/{id}")
    public ResponseEntity<AnaliseSolo> atualizar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String id,
            @Valid @RequestBody CadastroAnaliseSoloRequest dados) {

        AnaliseSolo analise =
                analiseSoloService.atualizar(
                        id,
                        usuarioId,
                        dados
                );

        return ResponseEntity.ok(analise);
    }

    // Exclui uma analise existente
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String id) {

        analiseSoloService.excluir(id, usuarioId);

        return ResponseEntity.noContent().build();
    }
}
