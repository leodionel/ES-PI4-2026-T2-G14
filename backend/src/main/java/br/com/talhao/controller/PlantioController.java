package br.com.talhao.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.talhao.dto.ColheitaRequest;
import br.com.talhao.dto.PlantioRequest;
import br.com.talhao.dto.PlantioResponse;
import br.com.talhao.service.PlantioService;

import jakarta.validation.Valid;

// Recebe as requisicoes HTTP relacionadas aos plantios de um talhao
@RestController
@RequestMapping("/api/talhoes/{talhaoId}/plantios")
public class PlantioController {

    private final PlantioService plantioService;

    public PlantioController(PlantioService plantioService) {
        this.plantioService = plantioService;
    }

    // Registra o plantio de uma cultura
    @PostMapping
    public ResponseEntity<PlantioResponse> registrar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String talhaoId,
            @Valid @RequestBody PlantioRequest dados) {

        PlantioResponse plantio = plantioService.registrar(
                talhaoId,
                usuarioId,
                dados.culturaId(),
                dados.dataPlantio()
        );

        return ResponseEntity.status(HttpStatus.CREATED).body(plantio);
    }

    // Lista os plantios do talhao, do mais antigo ao mais recente
    @GetMapping
    public ResponseEntity<List<PlantioResponse>> listar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String talhaoId) {

        return ResponseEntity.ok(
                plantioService.listar(talhaoId, usuarioId)
        );
    }

    // Registra a colheita de um plantio
    @PutMapping("/{plantioId}/colheita")
    public ResponseEntity<PlantioResponse> registrarColheita(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId,
            @PathVariable String talhaoId,
            @PathVariable String plantioId,
            @Valid @RequestBody ColheitaRequest dados) {

        return ResponseEntity.ok(
                plantioService.registrarColheita(
                        talhaoId,
                        plantioId,
                        usuarioId,
                        dados.dataColheita()
                )
        );
    }
}
