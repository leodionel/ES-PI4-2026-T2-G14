package br.com.talhao.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import br.com.talhao.model.AnaliseSolo;

//Responsavel pelo acesso as analises de solo no MongoDB
@Repository 
public interface AnaliseSoloRepository
    extends MongoRepository<AnaliseSolo, String> {

        //Lista todas as analises de um usuario
        List<AnaliseSolo> findByUsuarioIdOrderByDataColetaDesc(
            String usuarioId
        );

        //Lista as analises de uma propriedade do usuario
        List<AnaliseSolo> findByUsuarioIdAndPropriedadeIdOrderByDataColetaDesc( 
            String usuarioId,
            String propriedadeId
        );

        //Lista as analises de um talhao dentro de uma propriedade
        List<AnaliseSolo> findByUsuarioIdAndPropriedadeIdAndTalhaoIdOrderByDataColetaDesc(
            String usuarioId,
            String propriedadeId,
            String talhaoId
        );

        //Busca uma analise pelo ID, verificando o usuario
        Optional<AnaliseSolo> findByIdAndUsuarioId(
            String id,
            String usuarioId
        );

        // Conta as analises de um talhao
        long countByTalhaoId(String talhaoId);

        // Remove as analises de um talhao
        void deleteByTalhaoId(String talhaoId);
    }
