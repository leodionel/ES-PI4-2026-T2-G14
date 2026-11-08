package br.com.talhao.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

// Configura a proteção das senhas dos usuários
@Configuration
public class SenhaConfig {

    // Disponibiliza o codificador de senhas para o Spring
    @Bean
    public PasswordEncoder passwordEncoder() {

        // Utiliza o algoritmo BCrypt com fator de custo 12
        return new BCryptPasswordEncoder(12);
    }
}
