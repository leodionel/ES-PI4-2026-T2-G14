// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.talhao.dto.EventoHistoricoResponse;
import br.com.talhao.service.HistoricoTalhaoService;

// Recebe a requisicao da linha do tempo de um talhao
@RestController
@RequestMapping("/api/talhoes/{talhaoId}/historico")
public class HistoricoTalhaoController {

    private final HistoricoTalhaoService historicoTalhaoService;

    public HistoricoTalhaoController(
            HistoricoTalhaoService historicoTalhaoService) {
        this.historicoTalhaoService = historicoTalhaoService;
    }

    // Plantios, colheitas e analises do talhao, do mais antigo ao mais recente
    @GetMapping
    public ResponseEntity<List<EventoHistoricoResponse>> historico(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String talhaoId) {

        return ResponseEntity.ok(
                historicoTalhaoService.montar(talhaoId, usuarioId)
        );
    }
}
