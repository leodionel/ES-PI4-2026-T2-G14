
package br.com.talhao.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

// Configura a comunicação entre o Flutter Web e o backend
@Configuration
public class CorsConfig implements WebMvcConfigurer {

    // Endereços autorizados a acessar a API
    @Value("${app.cors.allowed-origins}")
    private String origensPermitidas;

    // Define quais requisições externas serão permitidas
    @Override
    public void addCorsMappings(CorsRegistry registry) {

        registry.addMapping("/api/**")

            // Permite os endereços configurados
            .allowedOrigins(origensPermitidas.split(","))

            // Métodos HTTP permitidos
            .allowedMethods(
                "GET",
                "POST",
                "PUT",
                "PATCH",
                "DELETE",
                "OPTIONS"
            )

            // Permite os cabeçalhos da requisição
            .allowedHeaders("*")

            // Não utiliza credenciais entre origens
            .allowCredentials(false)

            // Tempo de cache da autorização CORS
            .maxAge(3600);
    }
}
