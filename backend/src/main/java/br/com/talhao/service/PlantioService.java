// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.service;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.bson.types.ObjectId;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import com.mongodb.client.result.UpdateResult;

import br.com.talhao.dto.PlantioResponse;
import br.com.talhao.model.Cultura;
import br.com.talhao.model.Plantio;
import br.com.talhao.model.Talhao;

// Regras de negocio dos plantios (safras) de um talhao.
// Os plantios ficam dentro do documento do talhao.
@Service
public class PlantioService {

    private final TalhaoService talhaoService;
    private final CulturaService culturaService;
    private final MongoTemplate mongoTemplate;

    public PlantioService(
            TalhaoService talhaoService,
            CulturaService culturaService,
            MongoTemplate mongoTemplate) {

        this.talhaoService = talhaoService;
        this.culturaService = culturaService;
        this.mongoTemplate = mongoTemplate;
    }

    // REGISTRAR O PLANTIO DE UMA CULTURA
    public PlantioResponse registrar(
            String talhaoId,
            String usuarioId,
            String culturaId,
            LocalDate dataPlantio) {

        // Confirma que o talhao pertence ao usuario
        Talhao talhao = talhaoService.buscarEntidade(talhaoId, usuarioId);

        // A cultura precisa existir no catalogo
        Cultura cultura = culturaService.buscar(culturaId);

        // Uma safra por vez: o plantio anterior precisa ter a colheita
        // registrada antes de plantar outra cultura
        talhao.plantios()
                .stream()
                .filter(p -> p.dataColheita() == null)
                .findFirst()
                .ifPresent(aberto -> {
                    throw plantioAberto(aberto);
                });

        Plantio plantio = new Plantio(
                new ObjectId().toHexString(),
                cultura.id(),
                dataPlantio,
                null
        );

        // A condicao tambem vai na consulta: se outro pedido abrir um plantio
        // entre a leitura e a gravacao, nenhum documento e atualizado.
        // Acrescenta o plantio sem regravar o documento inteiro.
        UpdateResult resultado = mongoTemplate.updateFirst(
                consultaSemPlantioAberto(talhao),
                new Update().push("plantios", plantio),
                Talhao.class
        );

        if (resultado.getMatchedCount() == 0) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Ja existe um plantio sem colheita neste talhao. "
                    + "Registre a colheita antes de plantar outra cultura"
            );
        }

        return paraResponse(plantio, cultura.nome());
    }

    // LISTAR OS PLANTIOS DE UM TALHAO, DO MAIS ANTIGO AO MAIS RECENTE
    public List<PlantioResponse> listar(String talhaoId, String usuarioId) {

        Talhao talhao = talhaoService.buscarEntidade(talhaoId, usuarioId);

        Map<String, String> nomes = culturaService.listar()
                .stream()
                .collect(Collectors.toMap(
                        Cultura::id,
                        Cultura::nome
                ));

        return talhao.plantios()
                .stream()
                .sorted(Comparator.comparing(
                        Plantio::dataPlantio,
                        Comparator.nullsLast(Comparator.naturalOrder())
                ))
                .map(p -> paraResponse(
                        p,
                        nomes.getOrDefault(p.culturaId(), p.culturaId())
                ))
                .toList();
    }

    // REGISTRAR A COLHEITA DE UM PLANTIO ABERTO
    public PlantioResponse registrarColheita(
            String talhaoId,
            String plantioId,
            String usuarioId,
            LocalDate dataColheita) {

        Talhao talhao = talhaoService.buscarEntidade(talhaoId, usuarioId);

        Plantio plantio = talhao.plantios()
                .stream()
                .filter(p -> plantioId.equals(p.plantioId()))
                .findFirst()
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Plantio nao encontrado"
                ));

        if (plantio.dataColheita() != null) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "A colheita deste plantio ja foi registrada"
            );
        }

        if (dataColheita.isBefore(plantio.dataPlantio())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "A colheita nao pode ser anterior ao plantio"
            );
        }

        // So altera se o plantio ainda estiver aberto,
        // o que evita fechar o mesmo plantio duas vezes
        Query plantioAberto = new Query(new Criteria().andOperator(
                criterioDoTalhao(talhao),
                Criteria.where("plantios").elemMatch(
                        Criteria.where("plantioId").is(plantioId)
                                .and("dataColheita").is(null)
                )
        ));

        UpdateResult resultado = mongoTemplate.updateFirst(
                plantioAberto,
                new Update().set("plantios.$.dataColheita", dataColheita),
                Talhao.class
        );

        if (resultado.getMatchedCount() == 0) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "A colheita deste plantio ja foi registrada"
            );
        }

        // A cultura ja foi validada no plantio; se sair do catalogo,
        // a colheita (ja gravada) nao deve falhar por causa do nome
        String nome = culturaService.listar().stream()
                .filter(c -> c.id().equals(plantio.culturaId()))
                .map(Cultura::nome)
                .findFirst()
                .orElse(plantio.culturaId());

        return paraResponse(
                new Plantio(
                        plantio.plantioId(),
                        plantio.culturaId(),
                        plantio.dataPlantio(),
                        dataColheita
                ),
                nome
        );
    }

    private Criteria criterioDoTalhao(Talhao talhao) {
        return Criteria.where("id").is(talhao.id())
                .and("propriedadeId").is(talhao.propriedadeId());
    }

    // Talhao do usuario e sem nenhum plantio em aberto (sem dataColheita)
    private Query consultaSemPlantioAberto(Talhao talhao) {
        return new Query(new Criteria().andOperator(
                criterioDoTalhao(talhao),
                new Criteria().norOperator(
                        Criteria.where("plantios").elemMatch(
                                Criteria.where("dataColheita").is(null)
                        )
                )
        ));
    }

    private ResponseStatusException plantioAberto(Plantio aberto) {

        String nome = culturaService.listar().stream()
                .filter(c -> c.id().equals(aberto.culturaId()))
                .map(Cultura::nome)
                .findFirst()
                .orElse(aberto.culturaId());

        return new ResponseStatusException(
                HttpStatus.CONFLICT,
                "A safra de " + nome + " ainda esta aberta. "
                + "Registre a colheita antes de plantar outra cultura"
        );
    }

    private PlantioResponse paraResponse(Plantio plantio, String culturaNome) {
        return new PlantioResponse(
                plantio.plantioId(),
                plantio.culturaId(),
                culturaNome,
                plantio.dataPlantio(),
                plantio.dataColheita()
        );
    }
}
