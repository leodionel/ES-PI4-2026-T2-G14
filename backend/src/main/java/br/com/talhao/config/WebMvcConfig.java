
package br.com.talhao.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

// Configura a protecao das rotas HTTP do backend
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    private final JwtDecoder jwtDecoder;

    // Recebe o componente que valida os tokens JWT
    public WebMvcConfig(JwtDecoder jwtDecoder) {
        this.jwtDecoder = jwtDecoder;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {

        // Exige autenticacao nas rotas de propriedades
        registry.addInterceptor(
                new JwtAuthInterceptor(jwtDecoder)
        ).addPathPatterns(
                "/api/propriedades",
                "/api/propriedades/**"
        );
    }
}
