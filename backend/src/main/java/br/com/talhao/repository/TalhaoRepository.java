package br.com.talhao.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import br.com.talhao.model.Talhao;

// Responsavel pelo acesso a colecao "talhoes" do MongoDB
@Repository
public interface TalhaoRepository
        extends MongoRepository<Talhao, String> {

    // Busca todos os talhoes de uma propriedade
    List<Talhao> findByPropriedadeId(String propriedadeId);

    // Busca um talhao pelo ID dentro de uma propriedade
    Optional<Talhao> findByIdAndPropriedadeId(
            String id,
            String propriedadeId
    );
}
