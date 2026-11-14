package br.com.talhao.config;

import java.util.List;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import br.com.talhao.model.Cultura;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.TipoUso;
import br.com.talhao.repository.CulturaRepository;

// Grava o catalogo de culturas ao iniciar a aplicacao.
// Cada cultura tem ID fixo, entao reiniciar nao duplica dados.
@Component
public class CulturaSeedLoader implements ApplicationRunner {

    private final CulturaRepository culturaRepository;

    public CulturaSeedLoader(CulturaRepository culturaRepository) {
        this.culturaRepository = culturaRepository;
    }

    @Override
    public void run(ApplicationArguments args) {
        culturaRepository.saveAll(catalogo());
    }

    // Catalogo definido no documento 02-regras-agronomicas.md
    static List<Cultura> catalogo() {
        return List.of(
            new Cultura("soja", "Soja", "Glycine max", "Fabaceae",
                    Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS),
            new Cultura("feijao", "Feijão-comum", "Phaseolus vulgaris", "Fabaceae",
                    Grupo.LEGUMINOSA, TipoUso.COMERCIAL, GrupoP.ANUAIS),
            new Cultura("crotalaria", "Crotalária", "Crotalaria spp.", "Fabaceae",
                    Grupo.LEGUMINOSA, TipoUso.COBERTURA, null),
            new Cultura("milho", "Milho", "Zea mays", "Poaceae",
                    Grupo.GRAMINEA, TipoUso.COMERCIAL, GrupoP.ANUAIS),
            new Cultura("trigo", "Trigo", "Triticum aestivum", "Poaceae",
                    Grupo.GRAMINEA, TipoUso.COMERCIAL, GrupoP.ANUAIS),
            new Cultura("sorgo", "Sorgo", "Sorghum bicolor", "Poaceae",
                    Grupo.GRAMINEA, TipoUso.COMERCIAL, GrupoP.ANUAIS),
            new Cultura("milheto", "Milheto", "Pennisetum glaucum", "Poaceae",
                    Grupo.GRAMINEA, TipoUso.COBERTURA, null),
            new Cultura("aveia-preta", "Aveia-preta", "Avena strigosa", "Poaceae",
                    Grupo.GRAMINEA, TipoUso.COBERTURA, null),
            new Cultura("batata", "Batata", "Solanum tuberosum", "Solanaceae",
                    Grupo.OUTRAS, TipoUso.COMERCIAL, GrupoP.HORTALICAS)
        );
    }
}
