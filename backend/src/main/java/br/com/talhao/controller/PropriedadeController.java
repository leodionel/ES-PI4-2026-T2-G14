
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

import br.com.talhao.dto.CadastroPropriedadeRequest;
import br.com.talhao.model.Propriedade;
import br.com.talhao.service.PropriedadeService;

import jakarta.validation.Valid;

// Recebe as requisicoes HTTP relacionadas as propriedades
@RestController
@RequestMapping("/api/propriedades")
public class PropriedadeController {

    private final PropriedadeService propriedadeService;

    // Recebe o Service pelo construtor
    public PropriedadeController(
            PropriedadeService propriedadeService) {

        this.propriedadeService = propriedadeService;
    }

    // Endpoint para cadastrar uma propriedade
    @PostMapping
    public ResponseEntity<Propriedade> cadastrar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @Valid @RequestBody CadastroPropriedadeRequest dados) {

        // Cadastra a propriedade para o usuario autenticado
        Propriedade propriedade = propriedadeService.cadastrar(
                usuarioId,
                dados.nome(),
                dados.localizacao()
        );

        // Retorna HTTP 201 com a propriedade cadastrada
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(propriedade);
    }

    // Endpoint para listar as propriedades do usuario
    @GetMapping
    public ResponseEntity<List<Propriedade>> listar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId) {

        // Busca somente as propriedades do usuario autenticado
        List<Propriedade> propriedades =
                propriedadeService.listarPorUsuario(usuarioId);

        // Retorna HTTP 200 com a lista de propriedades
        return ResponseEntity.ok(propriedades);
    }

    // Endpoint para buscar uma propriedade pelo ID
    @GetMapping("/{id}")
    public ResponseEntity<Propriedade> buscarPorId(
            @PathVariable String id,
            @RequestAttribute("usuarioIdAutenticado") String usuarioId) {

        // Verifica se a propriedade pertence ao usuario
        Propriedade propriedade =
                propriedadeService.buscarPorId(id, usuarioId);

        // Retorna HTTP 200 com a propriedade encontrada
        return ResponseEntity.ok(propriedade);
    }

    // Endpoint para atualizar uma propriedade
    @PutMapping("/{id}")
    public ResponseEntity<Propriedade> atualizar(
            @PathVariable String id,
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @Valid @RequestBody CadastroPropriedadeRequest dados) {

        // Atualiza somente uma propriedade do usuario autenticado
        Propriedade propriedade = propriedadeService.atualizar(
                id,
                usuarioId,
                dados.nome(),
                dados.localizacao()
        );

        // Retorna HTTP 200 com os dados atualizados
        return ResponseEntity.ok(propriedade);
    }

    // Endpoint para excluir uma propriedade
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> excluir(
            @PathVariable String id,
            @RequestAttribute("usuarioIdAutenticado") String usuarioId) {

        // Exclui somente uma propriedade do usuario autenticado
        propriedadeService.excluir(id, usuarioId);

        // Retorna HTTP 204 - No Content
        return ResponseEntity.noContent().build();
    }
}
