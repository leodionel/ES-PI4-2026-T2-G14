package br.com.talhao.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.talhao.service.StatusSoloService;
import br.com.talhao.dto.StatusSoloResponse;

// Consulta o status do solo de um talhao
@RestController
@RequestMapping("/api/talhoes/{talhaoId}/status-solo")
public class StatusSoloController {
    
    private final StatusSoloService statusSoloService;

    public StatusSoloController(StatusSoloService statusSoloService) {
        this.statusSoloService = statusSoloService;
    }

    @GetMapping
    public ResponseEntity<StatusSoloResponse> buscar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String talhaoId) {
            
        return ResponseEntity.ok(
                statusSoloService.buscar(talhaoId, usuarioId)
        );
    }
}
