package br.com.talhao;

import java.util.TimeZone;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

// Classe principal do backend Talhão
@SpringBootApplication
public class TalhaoApplication {

    public static void main(String[] args) {

        // Mantém as datas sem hora iguais em todos os ambientes
        TimeZone.setDefault(TimeZone.getTimeZone("UTC"));

        // Inicializa a aplicação Spring Boot (uma única vez)
        SpringApplication.run(TalhaoApplication.class, args);
    }
}
