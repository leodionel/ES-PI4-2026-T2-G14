package br.com.talhao.service;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import br.com.talhao.model.Cultura;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.Talhao;
import br.com.talhao.model.TipoUso;

// Leituras do historico de plantios de um talhao (sem acesso ao banco)
public final class HistoricoTalhao {

    private HistoricoTalhao() {
    }

    // Culturas plantadas ate a data, da mais recente para a mais antiga.
    // Culturas fora do catalogo sao ignoradas.
    public static List<Cultura> culturasRecentes(
            Talhao talhao,
            Map<String, Cultura> catalogo,
            LocalDate hoje) {

        return talhao.plantios().stream()
                .filter(p -> p.dataPlantio() != null
                        && !p.dataPlantio().isAfter(hoje))
                .sorted(Comparator.comparing(Plantio::dataPlantio).reversed())
                .map(p -> catalogo.get(p.culturaId()))
                .filter(c -> c != null)
                .toList();
    }

    // Cultura comercial mais recente; define o grupo usado no fosforo
    public static Optional<Cultura> ultimaComercial(
            Talhao talhao,
            Map<String, Cultura> catalogo,
            LocalDate hoje) {

        return culturasRecentes(talhao, catalogo, hoje).stream()
                .filter(c -> c.tipoUso() == TipoUso.COMERCIAL
                        && c.grupoP() != null)
                .findFirst();
    }

    // Plantio atual: o mais recente ja iniciado e sem colheita registrada.
    // Se duas datas empatam, vale o plantio registrado por ultimo.
    // Culturas fora do catalogo sao ignoradas.
    public static Optional<Plantio> plantioAtual(
            Talhao talhao,
            Map<String, Cultura> catalogo,
            LocalDate hoje) {

        return talhao.plantios().stream()
                .filter(p -> p.dataColheita() == null
                        && p.dataPlantio() != null
                        && !p.dataPlantio().isAfter(hoje)
                        && catalogo.containsKey(p.culturaId()))
                .reduce((anterior, atual) ->
                        atual.dataPlantio().isBefore(anterior.dataPlantio())
                                ? anterior
                                : atual);
    }
}
