package br.com.talhao.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.talhao.dto.DashboardResponse;
import br.com.talhao.service.DashboardService;

// Rota do dashboard do usuario autenticado.
// A propriedade vem sempre do token, nunca da URL.
@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    // Retorna o resumo da propriedade
    @GetMapping
    public ResponseEntity<DashboardResponse> buscar(
            @RequestAttribute("usuarioIdAutenticado") String usuarioId) {

        return ResponseEntity.ok(dashboardService.montar(usuarioId));
    }
}
