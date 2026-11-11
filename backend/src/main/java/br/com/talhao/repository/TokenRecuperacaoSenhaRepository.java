package br.com.talhao.repository;

import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;

import br.com.talhao.model.TokenRecuperacaoSenha;

// Responsável por acessar os tokens de recuperação no MongoDB.
public interface TokenRecuperacaoSenhaRepository
        extends MongoRepository<TokenRecuperacaoSenha, String> {

    // Procura um token pelo hash armazenado.
    Optional<TokenRecuperacaoSenha> findByTokenHash(String tokenHash);

    // Remove os tokens de recuperação associados a um usuário.
    void deleteByUsuarioId(String usuarioId);
}
