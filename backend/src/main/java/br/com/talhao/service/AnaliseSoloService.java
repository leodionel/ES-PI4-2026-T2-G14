
package br.com.talhao.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.CadastroAnaliseSoloRequest;
import br.com.talhao.model.AnaliseSolo;
import br.com.talhao.repository.AnaliseSoloRepository;

// Contem as regras de negocio das analises de solo
@Service
public class AnaliseSoloService {

    private final AnaliseSoloRepository analiseSoloRepository;
    private final PropriedadeService propriedadeService;

    // Recebe as dependencias pelo construtor
    public AnaliseSoloService(
            AnaliseSoloRepository analiseSoloRepository,
            PropriedadeService propriedadeService) {

        this.analiseSoloRepository = analiseSoloRepository;
        this.propriedadeService = propriedadeService;
    }

    // Cadastra uma nova analise de solo
    public AnaliseSolo cadastrar(
            String usuarioId,
            CadastroAnaliseSoloRequest dados) {

        // Verifica se a propriedade pertence ao usuario
        propriedadeService.buscarPorId(
                dados.propriedadeId(),
                usuarioId
        );

        // Cria a analise vinculada ao usuario
        AnaliseSolo analise = new AnaliseSolo(
                null,
                usuarioId,
                dados.propriedadeId(),
                dados.talhaoId(),
                dados.dataColeta(),
                dados.ph(),
                dados.fosforo(),
                dados.potassio(),
                dados.materiaOrganica(),
                dados.observacoes()
        );

        // Salva no MongoDB
        return analiseSoloRepository.save(analise);
    }

    // Lista todas as analises do usuario
    public List<AnaliseSolo> listarPorUsuario(
            String usuarioId) {

        return analiseSoloRepository
                .findByUsuarioIdOrderByDataColetaDesc(
                        usuarioId
                );
    }

    // Lista as analises de uma propriedade
    public List<AnaliseSolo> listarPorPropriedade(
            String usuarioId,
            String propriedadeId) {

        // Verifica se o usuario possui a propriedade
        propriedadeService.buscarPorId(
                propriedadeId,
                usuarioId
        );

        return analiseSoloRepository
                .findByUsuarioIdAndPropriedadeIdOrderByDataColetaDesc(
                        usuarioId,
                        propriedadeId
                );
    }

    // Lista o historico de analises de um talhao
    public List<AnaliseSolo> listarPorTalhao(
            String usuarioId,
            String propriedadeId,
            String talhaoId) {

        // Verifica o acesso a propriedade
        propriedadeService.buscarPorId(
                propriedadeId,
                usuarioId
        );

        return analiseSoloRepository
                .findByUsuarioIdAndPropriedadeIdAndTalhaoIdOrderByDataColetaDesc(
                        usuarioId,
                        propriedadeId,
                        talhaoId
                );
    }

    // Busca uma analise pelo ID
    public AnaliseSolo buscarPorId(
            String id,
            String usuarioId) {

        return analiseSoloRepository
                .findByIdAndUsuarioId(id, usuarioId)
                .orElseThrow(() ->
                        new ResponseStatusException(
                                HttpStatus.NOT_FOUND,
                                "Analise de solo nao encontrada"
                        )
                );
    }

    // Atualiza uma analise existente
    public AnaliseSolo atualizar(
            String id,
            String usuarioId,
            CadastroAnaliseSoloRequest dados) {

        // Confirma que a analise pertence ao usuario
        buscarPorId(id, usuarioId);

        // Verifica a propriedade informada
        propriedadeService.buscarPorId(
                dados.propriedadeId(),
                usuarioId
        );

        // Mantem o ID e o usuario original
        AnaliseSolo atualizada = new AnaliseSolo(
                id,
                usuarioId,
                dados.propriedadeId(),
                dados.talhaoId(),
                dados.dataColeta(),
                dados.ph(),
                dados.fosforo(),
                dados.potassio(),
                dados.materiaOrganica(),
                dados.observacoes()
        );

        return analiseSoloRepository.save(atualizada);
    }

    // Exclui uma analise existente
    public void excluir(
            String id,
            String usuarioId) {

        // Busca somente uma analise do usuario
        AnaliseSolo analise = buscarPorId(
                id,
                usuarioId
        );

        analiseSoloRepository.delete(analise);
    }
}
