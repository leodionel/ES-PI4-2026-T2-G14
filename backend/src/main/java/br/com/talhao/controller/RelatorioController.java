
package br.com.talhao.controller;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.talhao.service.RelatorioPdfService;

// Disponibiliza os relatorios PDF pela API REST
@RestController
@RequestMapping("/api/relatorios")
public class RelatorioController {

    private final RelatorioPdfService relatorioPdfService;

    // Injecao de dependencia do Service
    public RelatorioController(
            RelatorioPdfService relatorioPdfService) {

        this.relatorioPdfService = relatorioPdfService;
    }

    // Gera e disponibiliza o relatorio PDF de uma propriedade
    @GetMapping("/propriedade/{id}/pdf")
    public ResponseEntity<byte[]> baixarRelatorio(
            @PathVariable String id,
            @RequestAttribute("usuarioIdAutenticado") String usuarioId) {

        // Gera o PDF apenas com os dados autorizados do usuario
        byte[] pdf = relatorioPdfService.gerarRelatorio(
                usuarioId,
                id
        );

        // Retorna o arquivo PDF para download
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"relatorio-propriedade.pdf\""
                )
                .contentLength(pdf.length)
                .body(pdf);
    }
}
