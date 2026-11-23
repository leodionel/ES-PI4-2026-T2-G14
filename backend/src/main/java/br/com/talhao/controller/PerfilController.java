// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.talhao.dto.AtualizacaoPerfilRequest;
import br.com.talhao.dto.PerfilResponse;
import br.com.talhao.service.PerfilService;

import jakarta.validation.Valid;

// Rotas do perfil do usuario autenticado.
// O usuario vem sempre do token, nunca da URL.
@RestController
@RequestMapping("/api/usuarios/me")
public class PerfilController {

    private final PerfilService perfilService;

    public PerfilController(PerfilService perfilService) {
        this.perfilService = perfilService;
    }

    // Retorna os dados pessoais e a propriedade
    @GetMapping
    public ResponseEntity<PerfilResponse> buscar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId) {

        return ResponseEntity.ok(perfilService.buscar(usuarioId));
    }

    // Atualiza nome e telefone
    @PutMapping
    public ResponseEntity<PerfilResponse> atualizar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @Valid @RequestBody AtualizacaoPerfilRequest dados) {

        return ResponseEntity.ok(perfilService.atualizar(usuarioId, dados));
    }
}
