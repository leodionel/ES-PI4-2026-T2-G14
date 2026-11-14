package br.com.talhao.service;

import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.TalhaoRequest;
import br.com.talhao.dto.TalhaoResponse;
import br.com.talhao.model.Propriedade;
import br.com.talhao.model.Talhao;
import br.com.talhao.repository.AnaliseSoloRepository;
import br.com.talhao.repository.PropriedadeRepository;
import br.com.talhao.repository.TalhaoRepository;

// Responsavel pelas regras de negocio dos talhoes.
// O propriedadeId nunca vem do cliente: e obtido a partir do usuario autenticado.
@Service
public class TalhaoService {

    private final TalhaoRepository talhaoRepository;
    private final PropriedadeRepository propriedadeRepository;
    private final AnaliseSoloRepository analiseSoloRepository;
    private final MongoTemplate mongoTemplate;

    // Injecao de dependencias pelo Spring Boot
    public TalhaoService(
            TalhaoRepository talhaoRepository,
            PropriedadeRepository propriedadeRepository,
            AnaliseSoloRepository analiseSoloRepository,
            MongoTemplate mongoTemplate) {

        this.talhaoRepository = talhaoRepository;
        this.propriedadeRepository = propriedadeRepository;
        this.analiseSoloRepository = analiseSoloRepository;
        this.mongoTemplate = mongoTemplate;
    }

    // CADASTRAR UM TALHAO
    public TalhaoResponse criar(String usuarioId, TalhaoRequest dados) {

        Propriedade propriedade = propriedadeDoUsuario(usuarioId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Cadastre a propriedade antes de criar talhoes"
                ));

        // A lista de plantios comeca vazia; as analises ficam em colecao propria
        Talhao talhao = new Talhao(
                null,
                propriedade.id(),
                dados.nome().trim(),
                dados.areaHa(),
                Instant.now(),
                List.of()
        );

        return paraResponse(talhaoRepository.save(talhao));
    }

    // LISTAR OS TALHOES DO USUARIO
    public List<TalhaoResponse> listar(String usuarioId) {

        Optional<Propriedade> propriedade = propriedadeDoUsuario(usuarioId);

        // Sem propriedade, nao ha talhoes
        if (propriedade.isEmpty()) {
            return List.of();
        }

        return talhaoRepository
                .findByPropriedadeId(propriedade.get().id())
                .stream()
                .map(this::paraResponse)
                .toList();
    }

    // DETALHAR UM TALHAO
    public TalhaoResponse buscar(String id, String usuarioId) {
        return paraResponse(talhaoDoUsuario(id, usuarioId));
    }

    // BUSCAR O TALHAO COMPLETO (USADO POR OUTROS SERVICES)
    public Talhao buscarEntidade(String id, String usuarioId) {
        return talhaoDoUsuario(id, usuarioId);
    }

    // EDITAR NOME E AREA DE UM TALHAO
    public TalhaoResponse atualizar(
            String id,
            String usuarioId,
            TalhaoRequest dados) {

        // Confirma que o talhao pertence ao usuario
        Talhao atual = talhaoDoUsuario(id, usuarioId);

        // Altera so os dois campos, sem regravar o historico
        Query consulta = Query.query(
                Criteria.where("id").is(atual.id())
                        .and("propriedadeId").is(atual.propriedadeId())
        );
        Update alteracao = new Update()
                .set("nome", dados.nome().trim())
                .set("areaHa", dados.areaHa());

        mongoTemplate.updateFirst(consulta, alteracao, Talhao.class);

        return buscar(id, usuarioId);
    }

    // EXCLUIR UM TALHAO E O HISTORICO DELE
    public void excluir(String id, String usuarioId, String confirmacaoNome) {

        Talhao talhao = talhaoDoUsuario(id, usuarioId);

        // O nome digitado deve ser igual ao do talhao,
        // ignorando maiusculas e espacos nas pontas
        if (!normalizar(talhao.nome()).equals(normalizar(confirmacaoNome))) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "O nome digitado nao confere com o nome do talhao"
            );
        }

        // Remove o talhao e, em seguida, as analises dele
        talhaoRepository.delete(talhao);
        analiseSoloRepository.deleteByTalhaoId(talhao.id());
    }

    // BUSCAR A PROPRIEDADE DO USUARIO
    private Optional<Propriedade> propriedadeDoUsuario(String usuarioId) {
        return propriedadeRepository
                .findByUsuarioId(usuarioId)
                .stream()
                .findFirst();
    }

    // BUSCAR UM TALHAO SOMENTE SE PERTENCER AO USUARIO
    private Talhao talhaoDoUsuario(String id, String usuarioId) {

        Propriedade propriedade = propriedadeDoUsuario(usuarioId)
                .orElseThrow(this::talhaoNaoEncontrado);

        return talhaoRepository
                .findByIdAndPropriedadeId(id, propriedade.id())
                .orElseThrow(this::talhaoNaoEncontrado);
    }

    private ResponseStatusException talhaoNaoEncontrado() {
        return new ResponseStatusException(
                HttpStatus.NOT_FOUND,
                "Talhao nao encontrado"
        );
    }

    private String normalizar(String texto) {
        return texto == null ? "" : texto.trim().toLowerCase(Locale.ROOT);
    }

    private TalhaoResponse paraResponse(Talhao talhao) {
        return new TalhaoResponse(
                talhao.id(),
                talhao.nome(),
                talhao.areaHa(),
                talhao.criadoEm(),
                talhao.plantios().size(),
                (int) analiseSoloRepository.countByTalhaoId(talhao.id())
        );
    }
}
