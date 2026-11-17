package br.com.talhao.service;

import java.time.LocalDate;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Talhao;
import br.com.talhao.repository.AnaliseSoloRepository;

// Calcula o status do solo de um talhao a partir da ultima analise
@Service
public class StatusSoloService {

    private final TalhaoService talhaoService;
    private final AnaliseSoloRepository analiseSoloRepository;
    private final CulturaService culturaService;

    public StatusSoloService(
            TalhaoService talhaoService,
            AnaliseSoloRepository analiseSoloRepository,
            CulturaService culturaService) {

        this.talhaoService = talhaoService;
        this.analiseSoloRepository = analiseSoloRepository;
        this.culturaService = culturaService;
    }

    // STATUS DE UM TALHAO DO USUARIO
    public StatusSoloResponse buscar(String talhaoId, String usuarioId) {
        return calcular(talhaoService.buscarEntidade(talhaoId, usuarioId));
    }

    // STATUS DE UM TALHAO JA CARREGADO (usado tambem pela simulacao)
    public StatusSoloResponse calcular(Talhao talhao) {

        AnaliseSolo ultima = analiseSoloRepository
                .findFirstByTalhaoIdOrderByDataColetaDesc(talhao.id())
                .orElse(null);

        Map<String, Cultura> catalogo = culturaService.listar().stream()
                .collect(Collectors.toMap(Cultura::id, Function.identity()));

        Cultura comercial = HistoricoTalhao
                .ultimaComercial(talhao, catalogo, LocalDate.now())
                .orElse(null);

        return ClassificadorSolo.classificar(ultima, comercial);
    }
}
