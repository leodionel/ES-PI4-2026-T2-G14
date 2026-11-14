package br.com.talhao.repository;

import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import br.com.talhao.model.Cultura;

// Responsavel pelo acesso a colecao "culturas" do MongoDB
@Repository
public interface CulturaRepository
        extends MongoRepository<Cultura, String> {
}
