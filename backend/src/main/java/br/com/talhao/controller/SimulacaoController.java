// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.talhao.dto.SimulacaoRequest;
import br.com.talhao.dto.SimulacaoResponse;
import br.com.talhao.service.SimulacaoService;

import jakarta.validation.Valid;



// Executa simulacoes de rotacao para um talhao
@RestController
@RequestMapping("/api/talhoes/{talhaoId}/simulacoes")
public class SimulacaoController {
    private final SimulacaoService simulacaoService;

    public SimulacaoController(SimulacaoService simulacaoService) {
        this.simulacaoService = simulacaoService;
    }

    // Nao grava nada; apenas calcula e devolve os cenarios
    @PostMapping
    public ResponseEntity<SimulacaoResponse> simular(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String talhaoId,
            @Valid @RequestBody SimulacaoRequest dados) {

        return ResponseEntity.ok(
                simulacaoService.simular(
                        talhaoId, 
                        usuarioId, 
                        dados.culturaIds()
                )   
        );
    }
}
