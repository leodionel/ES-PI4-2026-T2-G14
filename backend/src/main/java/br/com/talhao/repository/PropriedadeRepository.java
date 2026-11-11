
package br.com.talhao.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import br.com.talhao.model.Propriedade;

// Responsavel pelo acesso a colecao "propriedades" do MongoDB
@Repository
public interface PropriedadeRepository
        extends MongoRepository<Propriedade, String> {

    // Busca todas as propriedades de um usuario
    List<Propriedade> findByUsuarioId(String usuarioId);

    // Busca uma propriedade pelo ID e pelo usuario proprietario
    Optional<Propriedade> findByIdAndUsuarioId(
            String id,
            String usuarioId
    );

    // Verifica se uma propriedade pertence ao usuario
    boolean existsByIdAndUsuarioId(
            String id,
            String usuarioId
    );
}
