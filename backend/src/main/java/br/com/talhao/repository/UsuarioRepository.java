
package br.com.talhao.repository;

import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.data.mongodb.repository.Update;

import br.com.talhao.model.Usuario;

// Responsável pela comunicação com a coleção
// de usuários no MongoDB.
public interface UsuarioRepository
        extends MongoRepository<Usuario, String> {

    //Busca um usuario pelo email cadastrado.
    Optional<Usuario> findByEmail(String email);

    //Verifica se já existe um usuário com esse email
    boolean existsByEmail(String email);

    @Query("{ '_id': ?0 }")
    @Update("{ '$set': { 'nome': ?1, 'telefone': ?2 } }")
    void atualizarDadosPessoais(String id, String nome, String telefone);

}
