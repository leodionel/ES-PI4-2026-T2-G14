
package br.com.talhao;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

// Classe principal do backend Talhão
@SpringBootApplication
public class TalhaoApplication {

    public static void main(String[] args) {

        // Inicializa a aplicação Spring Boot
        SpringApplication.run(
            TalhaoApplication.class, args
        );
    }
}
