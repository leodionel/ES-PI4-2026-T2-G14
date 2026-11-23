// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.service;

import java.util.ArrayList;
import java.util.List;

import br.com.talhao.dto.CenarioResponse;
import br.com.talhao.dto.RegraAplicada;
import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.model.Classificacao;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Efeito;
import br.com.talhao.model.Grupo;
import br.com.talhao.model.StatusSolo;

// Regras de rotacao R1 a R7 do documento 02 (sem acesso ao banco)
public final class RegrasRotacao {

    private RegrasRotacao() {
    }

    // Aplica as regras a uma cultura candidata.
    // historico: ultimas safras, da mais recente para a mais antiga (ate 2).
    public static List<RegraAplicada> avaliar(
            Cultura candidata,
            List<Cultura> historico,
            StatusSoloResponse status) {

        List<RegraAplicada> regras = new ArrayList<>();

        Cultura anterior = historico.size() > 0 ? historico.get(0) : null;
        Cultura duasAtras = historico.size() > 1 ? historico.get(1) : null;

        // R1: mesma cultura da safra anterior
        if (anterior != null && anterior.id().equals(candidata.id())) {
            regras.add(regra("R1", Efeito.RESTRITIVA,
                    "Esta cultura foi plantada na safra anterior. "
                    + "Repetir a mesma cultura em seguida aumenta o risco "
                    + "de doenças e pragas.",
                    "F4"));
        }

        // R2: mesma cultura de duas safras atras e diferente da anterior
        if (duasAtras != null
                && duasAtras.id().equals(candidata.id())
                && (anterior == null || !anterior.id().equals(candidata.id()))) {
            regras.add(regra("R2", Efeito.ALERTA,
                    "Esta cultura também foi plantada duas safras atrás. "
                    + "Alternar só duas culturas pode manter riscos de pragas "
                    + "e doenças. Considere uma terceira.",
                    "F4"));
        }

        // R3: leguminosa -> gramínea
        if (anterior != null
                && anterior.grupo() == Grupo.LEGUMINOSA
                && candidata.grupo() == Grupo.GRAMINEA) {
            regras.add(regra("R3", Efeito.FAVORAVEL,
                    "A cultura anterior é uma leguminosa. Alternar com uma "
                    + "gramínea diversifica o sistema.",
                    "F2", "F7"));
        }

        // R4: gramínea -> leguminosa
        if (anterior != null
                && anterior.grupo() == Grupo.GRAMINEA
                && candidata.grupo() == Grupo.LEGUMINOSA) {
            regras.add(regra("R4", Efeito.FAVORAVEL,
                    "A cultura anterior é uma gramínea. Uma leguminosa "
                    + "diversifica o sistema e pode obter parte do nitrogênio "
                    + "por fixação biológica.",
                    "F6"));
        }

        // R5: feijao logo depois de soja
        if (anterior != null
                && "soja".equals(anterior.id())
                && "feijao".equals(candidata.id())) {
            regras.add(regra("R5", Efeito.ALERTA,
                    "Feijão logo depois de soja: em alguns sistemas, a "
                    + "sucessão imediata aumenta o risco de doenças de raiz e "
                    + "caule. Confirme a orientação para a sua região.",
                    "F5"));
        }

        // R6: solo em atencao ou risco (neutra, vale para todos os cenarios)
        if (status.status() == StatusSolo.ATENCAO
                || status.status() == StatusSolo.RISCO) {
            regras.add(regra("R6", Efeito.NEUTRA,
                    "O solo deste talhão tem "
                    + String.join(", ", status.motivos())
                    + " fora da faixa. A escolha da cultura não corrige isso.",
                    "F1"));
        }

        // R7: historico com menos de duas safras (neutra)
        if (historico.size() < 2) {
            regras.add(regra("R7", Efeito.NEUTRA,
                    "Histórico insuficiente: algumas regras não puderam ser "
                    + "avaliadas."));
        }

        return regras;
    }

    // Combina os efeitos das regras (secao 6.3 do documento 02)
    public static Classificacao classificar(List<RegraAplicada> regras) {

        if (tem(regras, Efeito.RESTRITIVA)) {
            return Classificacao.NAO_RECOMENDADO;
        }
        if (tem(regras, Efeito.ALERTA)) {
            return Classificacao.ACEITAVEL;
        }
        if (tem(regras, Efeito.FAVORAVEL)) {
            return Classificacao.RECOMENDADO;
        }
        return Classificacao.ACEITAVEL;
    }

    // As opcoes sao equivalentes quando todas tem a mesma classificacao
    // e todas tem (ou todas nao tem) alerta
    public static boolean equivalentes(List<CenarioResponse> cenarios) {

        if (cenarios.isEmpty()) {
            return false;
        }

        Classificacao primeira = cenarios.get(0).classificacao();
        boolean primeiraTemAlerta = tem(cenarios.get(0).regras(), Efeito.ALERTA);

        return cenarios.stream().allMatch(c ->
                c.classificacao() == primeira
                && tem(c.regras(), Efeito.ALERTA) == primeiraTemAlerta);
    }

    private static boolean tem(List<RegraAplicada> regras, Efeito efeito) {
        return regras.stream().anyMatch(r -> r.efeito() == efeito);
    }

    private static RegraAplicada regra(
            String id,
            Efeito efeito,
            String mensagem,
            String... fontes) {

        return new RegraAplicada(id, efeito, mensagem, FontesTecnicas.de(fontes));
    }
}
