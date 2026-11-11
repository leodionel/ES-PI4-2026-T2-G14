package br.com.talhao.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.talhao.model.Cultura;
import br.com.talhao.service.CulturaService;

// Recebe as requisicoes HTTP relacionadas ao catalogo de culturas
@RestController
@RequestMapping("/api/culturas")
public class CulturaController {

    private final CulturaService culturaService;

    public CulturaController(CulturaService culturaService) {
        this.culturaService = culturaService;
    }

    // Lista o catalogo de culturas
    @GetMapping
    public ResponseEntity<List<Cultura>> listar() {
        return ResponseEntity.ok(culturaService.listar());
    }
}
