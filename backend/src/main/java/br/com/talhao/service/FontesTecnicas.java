package br.com.talhao.service;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import br.com.talhao.model.FonteTecnica;

// Fontes tecnicas do documento 02 citadas pelas regras
public final class FontesTecnicas {

    private static final Map<String, FonteTecnica> FONTES = Map.of(
            "F1", new FonteTecnica("F1",
                    "IAC. Boletim Tecnico 100: Recomendacoes de Adubacao e Calagem para o Estado de Sao Paulo. 3. ed. 2022",
                    "https://www.iac.sp.gov.br/publicacoes/boletim100.php"),
            "F2", new FonteTecnica("F2",
                    "IAC. Interpretacao de resultados de analise de solo",
                    "https://www.iac.sp.gov.br/produtoseservicos/analisedosolo/interpretacaoanalise.php"),
            "F4", new FonteTecnica("F4",
                    "Embrapa. Indicacoes Tecnicas para a Cultura da Soja no RS e SC, secao Rotacao de culturas",
                    "https://www.infoteca.cnptia.embrapa.br/infoteca/bitstream/doc/1011192/1/IndicacoesTecnicasEmbrapa003.pdf"),
            "F5", new FonteTecnica("F5",
                    "Embrapa. Tecnologias de producao de soja 105, capitulo sobre sistemas de producao e rotacao",
                    "https://ainfo.cnptia.embrapa.br/digital/bitstream/item/223209/1/SP-17-2020-online-1.pdf"),
            "F6", new FonteTecnica("F6",
                    "Mercante, F. M. et al. Fixacao biologica de nitrogenio em adubos verdes. Embrapa, 2023, cap. 8",
                    "https://www.infoteca.cnptia.embrapa.br/infoteca/handle/doc/1161220"),
            "F7", new FonteTecnica("F7",
                    "Alves et al. Balanco de N em rotacao de culturas sob plantio direto em Dourados, MS. Embrapa Agrobiologia, 2005",
                    null)
    );

    private FontesTecnicas() {
    }

    // Devolve as fontes pelos ids informados, na mesma ordem
    public static List<FonteTecnica> de(String... ids) {
        return Arrays.stream(ids).map(FONTES::get).toList();
    }
}
