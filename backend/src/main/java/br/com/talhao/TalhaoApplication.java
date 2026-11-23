// Feito por Leonardo Dionel RA:25010092

// Contribuição: Matheus Rosini
// RA: 25015832
// Participação: configuração inicial da aplicação Spring Boot.

package br.com.talhao;

import java.util.TimeZone;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

// Classe principal do backend Talhão
@SpringBootApplication
public class TalhaoApplication {

    public static void main(String[] args) {
        TimeZone.setDefault(TimeZone.getTimeZone("UTC"));
        
        // Inicializa a aplicação Spring Boot
        SpringApplication.run(TalhaoApplication.class, args);
        
        
    }
}
