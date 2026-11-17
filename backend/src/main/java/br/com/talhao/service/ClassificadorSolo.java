package br.com.talhao.service;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

import br.com.talhao.dto.IndicadorSolo;
import br.com.talhao.dto.StatusSoloResponse;
import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.GrupoP;
import br.com.talhao.model.StatusSolo;
import br.com.talhao.model.Tratamento;

// Classifica a analise de solo pelas tabelas do documento 02 (IAC, Boletim 100).
// Cada valor e arredondado para a precisao da tabela antes de comparar:
// pH e K com 1 casa decimal; P e V como numero inteiro.
public final class ClassificadorSolo {

    private ClassificadorSolo() {
    }

    // Calcula o status a partir da ultima analise (pode ser nula)
    // e da ultima cultura comercial do talhao (pode ser nula)
    public static StatusSoloResponse classificar(
            AnaliseSolo analise,
            Cultura ultimaComercial) {

        if (analise == null) {
            return new StatusSoloResponse(
                    StatusSolo.SEM_ANALISE, null, List.of(), List.of(), null);
        }

        List<IndicadorSolo> indicadores = new ArrayList<>();
        List<String> avisos = new ArrayList<>();

        adicionar(indicadores, avisos, "pH", analise.ph() == null
                ? null : classificarPh(analise.ph()));
        adicionar(indicadores, avisos, "V%", analise.saturacaoBases() == null
                ? null : classificarV(analise.saturacaoBases()));
        adicionar(indicadores, avisos, "K", analise.potassio() == null
                ? null : classificarK(analise.potassio()));

        // O fosforo depende do grupo da ultima cultura comercial
        if (ultimaComercial == null || ultimaComercial.grupoP() == null) {
            avisos.add("O talhao nao tem cultura comercial no historico, "
                    + "entao o fosforo nao entrou no status.");
        } else {
            adicionar(indicadores, avisos, "P", analise.fosforo() == null
                    ? null
                    : classificarP(analise.fosforo(), ultimaComercial.grupoP()));
        }

        List<String> motivos = indicadores.stream()
                .filter(i -> i.tratamento() != Tratamento.SEM_ALERTA)
                .map(i -> i.parametro() + " ("
                        + i.classe().toLowerCase(Locale.ROOT) + ")")
                .toList();

        StatusSolo status;
        if (indicadores.stream()
                .anyMatch(i -> i.tratamento() == Tratamento.CRITICA)) {
            status = StatusSolo.RISCO;
        } else if (!motivos.isEmpty()) {
            status = StatusSolo.ATENCAO;
        } else {
            status = StatusSolo.SAUDAVEL;
        }

        return new StatusSoloResponse(
                status,
                analise.dataColeta(),
                indicadores,
                motivos,
                avisos.isEmpty() ? null : String.join(" ", avisos)
        );
    }

    // Registra o indicador ou avisa que o valor nao foi informado
    private static void adicionar(
            List<IndicadorSolo> indicadores,
            List<String> avisos,
            String parametro,
            IndicadorSolo indicador) {

        if (indicador == null) {
            avisos.add("Sem valor registrado para " + parametro + ".");
        } else {
            indicadores.add(indicador);
        }
    }

    // pH em CaCl2 (tabela 4.1)
    static IndicadorSolo classificarPh(double valor) {

        long decimos = Math.round(valor * 10);
        String classe;
        Tratamento tratamento = Tratamento.SEM_ALERTA;

        if (decimos <= 43) {
            classe = "Acidez muito alta";
            tratamento = Tratamento.CRITICA;
        } else if (decimos <= 50) {
            classe = "Acidez alta";
            tratamento = Tratamento.ATENCAO;
        } else if (decimos <= 55) {
            classe = "Acidez média";
        } else if (decimos <= 60) {
            classe = "Acidez baixa";
        } else {
            classe = "Acidez muito baixa";
        }

        return new IndicadorSolo("pH", decimos / 10.0, "CaCl2", classe, tratamento);
    }

    // Saturacao por bases, em % (tabela 4.2)
    static IndicadorSolo classificarV(double valor) {

        long v = Math.round(valor);
        String classe;
        Tratamento tratamento = Tratamento.SEM_ALERTA;

        if (v <= 25) {
            classe = "Muito baixa";
            tratamento = Tratamento.CRITICA;
        } else if (v <= 50) {
            classe = "Baixa";
            tratamento = Tratamento.ATENCAO;
        } else if (v <= 70) {
            classe = "Média";
        } else if (v <= 90) {
            classe = "Alta";
        } else {
            classe = "Muito alta";
        }

        return new IndicadorSolo("V%", v, "%", classe, tratamento);
    }

    // Potassio trocavel, em mmolc/dm3 (tabela 4.4)
    static IndicadorSolo classificarK(double valor) {

        long decimos = Math.round(valor * 10);
        String classe;
        Tratamento tratamento = Tratamento.SEM_ALERTA;

        if (decimos <= 15) {
            classe = "Baixo";
            tratamento = Tratamento.ATENCAO;
        } else if (decimos <= 30) {
            classe = "Médio";
        } else if (decimos <= 60) {
            classe = "Alto";
        } else {
            // Possivel desequilibrio com calcio e magnesio
            classe = "Muito alto";
            tratamento = Tratamento.ATENCAO;
        }

        return new IndicadorSolo("K", decimos / 10.0, "mmolc/dm3", classe, tratamento);
    }

    // Fosforo (P resina), em mg/dm3, por grupo de cultura (tabela 4.3)
    static IndicadorSolo classificarP(double valor, GrupoP grupo) {

        long p = Math.round(valor);

        // Limites superiores de "Baixo" e de "Medio"
        long limiteBaixo = grupo == GrupoP.HORTALICAS ? 25 : 15;
        long limiteMedio = grupo == GrupoP.HORTALICAS ? 60 : 40;

        String classe;
        Tratamento tratamento = Tratamento.SEM_ALERTA;

        if (p <= limiteBaixo) {
            classe = "Baixo";
            tratamento = Tratamento.ATENCAO;
        } else if (p <= limiteMedio) {
            classe = "Médio";
        } else {
            classe = "Alto";
        }

        return new IndicadorSolo("P", p, "mg/dm3", classe, tratamento);
    }
}
