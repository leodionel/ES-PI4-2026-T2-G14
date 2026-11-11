package br.com.talhao.service;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.model.cultura.Cultura;
import br.com.talhao.repository.CulturaRepository;

// Consulta o catalogo de culturas, mantido em memoria depois da primeira leitura
@Service
public class CulturaService {

    private final CulturaRepository culturaRepository;

    // Catalogo em memoria (so muda quando a aplicacao reinicia)
    private volatile Map<String, Cultura> catalogo;

    public CulturaService(CulturaRepository culturaRepository) {
        this.culturaRepository = culturaRepository;
    }

    // LISTAR TODAS AS CULTURAS, EM ORDEM ALFABETICA
    public List<Cultura> listar() {
        return catalogo().values()
                .stream()
                .sorted(Comparator.comparing(Cultura::nome))
                .toList();
    }

    // BUSCAR UMA CULTURA PELO ID
    public Cultura buscar(String id) {

        Cultura cultura = catalogo().get(id);

        if (cultura == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Cultura nao encontrada no catalogo"
            );
        }

        return cultura;
    }

    // Le o catalogo do banco uma unica vez
    private Map<String, Cultura> catalogo() {

        Map<String, Cultura> atual = catalogo;

        if (atual == null) {
            synchronized (this) {
                atual = catalogo;

                if (atual == null) {
                    atual = culturaRepository.findAll()
                            .stream()
                            .collect(Collectors.toMap(
                                    Cultura::id,
                                    Function.identity()
                            ));

                    // Catalogo vazio nao e guardado, para tentar de novo depois
                    if (!atual.isEmpty()) {
                        catalogo = atual;
                    }
                }
            }
        }

        return atual;
    }
}
