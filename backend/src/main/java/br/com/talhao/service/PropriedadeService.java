
package br.com.talhao.service;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.model.Propriedade;
import br.com.talhao.repository.PropriedadeRepository;
import br.com.talhao.repository.TalhaoRepository;
import br.com.talhao.repository.UsuarioRepository;

// Responsavel pelas regras de negocio das propriedades rurais
@Service
public class PropriedadeService {

    private final PropriedadeRepository propriedadeRepository;
    private final UsuarioRepository usuarioRepository;
    private final TalhaoRepository talhaoRepository;

    // Injecao de dependencias pelo Spring Boot
    public PropriedadeService(
            PropriedadeRepository propriedadeRepository,
            UsuarioRepository usuarioRepository,
            TalhaoRepository talhaoRepository) {

        this.propriedadeRepository = propriedadeRepository;
        this.usuarioRepository = usuarioRepository;
        this.talhaoRepository = talhaoRepository;
    }

    // CADASTRAR UMA PROPRIEDADE
    public Propriedade cadastrar(
            String usuarioId,
            String nome,
            String localizacao) {

        validarUsuario(usuarioId);

        String nomeValidado = validarTexto(nome, "Nome");
        String localizacaoValidada =
                validarTexto(localizacao, "Localizacao");

        // RN11: no MVP cada usuario tem uma unica propriedade
        if (!propriedadeRepository.findByUsuarioId(usuarioId).isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "O usuario ja possui uma propriedade cadastrada"
            );
        }

        // O MongoDB gera o ID da nova propriedade
        Propriedade propriedade = new Propriedade(
                null,
                usuarioId,
                nomeValidado,
                localizacaoValidada
        );

        return propriedadeRepository.save(propriedade);
    }

    // LISTAR PROPRIEDADES DE UM USUARIO
    public List<Propriedade> listarPorUsuario(String usuarioId) {

        validarUsuario(usuarioId);

        return propriedadeRepository.findByUsuarioId(usuarioId);
    }

    // BUSCAR UMA PROPRIEDADE PELO ID
    public Propriedade buscarPorId(
            String id,
            String usuarioId) {

        validarIdentificador(id, "Propriedade");
        validarIdentificador(usuarioId, "Usuario");

        return propriedadeRepository
                .findByIdAndUsuarioId(id, usuarioId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Propriedade nao encontrada"
                ));
    }

    // ATUALIZAR UMA PROPRIEDADE
    public Propriedade atualizar(
            String id,
            String usuarioId,
            String nome,
            String localizacao) {

        // Verifica se a propriedade pertence ao usuario informado
        Propriedade propriedadeAtual =
                buscarPorId(id, usuarioId);

        String nomeValidado = validarTexto(nome, "Nome");
        String localizacaoValidada =
                validarTexto(localizacao, "Localizacao");

        // Mantem o ID e o proprietario originais
        Propriedade propriedadeAtualizada = new Propriedade(
                propriedadeAtual.id(),
                propriedadeAtual.usuarioId(),
                nomeValidado,
                localizacaoValidada
        );

        return propriedadeRepository.save(propriedadeAtualizada);
    }

    // EXCLUIR UMA PROPRIEDADE
    public void excluir(String id, String usuarioId) {

        // Busca a propriedade associada ao usuario informado
        Propriedade propriedade = buscarPorId(id, usuarioId);

        // Nao exclui enquanto houver talhoes (e historico) vinculados
        if (talhaoRepository.existsByPropriedadeId(propriedade.id())) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Exclua os talhoes da propriedade antes de exclui-la"
            );
        }

        propriedadeRepository.delete(propriedade);
    }

    // VERIFICAR SE O USUARIO EXISTE
    private void validarUsuario(String usuarioId) {

        validarIdentificador(usuarioId, "Usuario");

        if (!usuarioRepository.existsById(usuarioId)) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Usuario nao encontrado"
            );
        }
    }

    // VALIDAR CAMPOS OBRIGATORIOS
    private String validarTexto(String valor, String campo) {

        if (valor == null || valor.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    campo + " e obrigatorio"
            );
        }

        return valor.trim();
    }

    // VALIDAR IDENTIFICADORES OBRIGATORIOS
    private void validarIdentificador(String id, String campo) {

        if (id == null || id.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    campo + " deve possuir um identificador"
            );
        }
    }
}
