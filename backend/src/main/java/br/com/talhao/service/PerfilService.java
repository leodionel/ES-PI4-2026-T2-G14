// Feito por Leonardo Dionel RA:25010092

package br.com.talhao.service;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.AtualizacaoPerfilRequest;
import br.com.talhao.dto.PerfilResponse;
import br.com.talhao.dto.PropriedadeResponse;
import br.com.talhao.dto.UsuarioResponse;
import br.com.talhao.model.Propriedade;
import br.com.talhao.model.Usuario;
import br.com.talhao.repository.PropriedadeRepository;
import br.com.talhao.repository.UsuarioRepository;

// Regras de negocio do perfil do usuario logado
@Service
public class PerfilService {

    private static final int NOME_MINIMO = 3;

    private final UsuarioRepository usuarioRepository;
    private final PropriedadeRepository propriedadeRepository;

    // Recebe as dependencias pelo construtor
    public PerfilService(
            UsuarioRepository usuarioRepository,
            PropriedadeRepository propriedadeRepository) {

        this.usuarioRepository = usuarioRepository;
        this.propriedadeRepository = propriedadeRepository;
    }

    // Retorna os dados pessoais e a propriedade do usuario
    public PerfilResponse buscar(String usuarioId) {

        Usuario usuario = buscarUsuario(usuarioId);

        return montarPerfil(usuario);
    }

    // Atualiza nome e telefone. Os demais campos nao mudam
    public PerfilResponse atualizar(
            String usuarioId,
            AtualizacaoPerfilRequest dados) {

        Usuario atual = buscarUsuario(usuarioId);

        // O limite minimo vale para o nome sem os espacos das pontas
        String nome = dados.nome().trim();

        if (nome.length() < NOME_MINIMO) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "O nome deve ter pelo menos " + NOME_MINIMO
                            + " caracteres"
            );
        }

        Usuario atualizado = new Usuario(
                atual.id(),
                nome,
                atual.email(),
                dados.telefone(),
                atual.senhaHash(),
                atual.criadoEm()
        );

        return montarPerfil(usuarioRepository.save(atualizado));
    }

    // Busca o usuario do token. Se ele nao existe mais,
    // a sessao deixa de valer e o app volta para o login
    private Usuario buscarUsuario(String usuarioId) {

        return usuarioRepository.findById(usuarioId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Sessão inválida"
                ));
    }

    // No MVP cada usuario tem no maximo uma propriedade (RN11)
    private PerfilResponse montarPerfil(Usuario usuario) {

        PropriedadeResponse propriedade = propriedadeRepository
                .findByUsuarioId(usuario.id())
                .stream()
                .findFirst()
                .map(this::paraResposta)
                .orElse(null);

        UsuarioResponse resposta = new UsuarioResponse(
                usuario.id(),
                usuario.nome(),
                usuario.email(),
                usuario.telefone(),
                usuario.criadoEm()
        );

        return new PerfilResponse(resposta, propriedade);
    }

    private PropriedadeResponse paraResposta(Propriedade propriedade) {

        return new PropriedadeResponse(
                propriedade.id(),
                propriedade.nome(),
                propriedade.localizacao()
        );
    }
}
