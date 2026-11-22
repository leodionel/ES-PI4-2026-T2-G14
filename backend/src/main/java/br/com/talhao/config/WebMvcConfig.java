
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

        // Toda rota da API exige token. Uma rota nova ja nasce protegida;
        // so as rotas abertas abaixo ficam de fora.
        registry.addInterceptor(
                new JwtAuthInterceptor(jwtDecoder)
        ).addPathPatterns(
                "/api/**"
        ).excludePathPatterns(
                // Entrar e criar conta nao tem token ainda
                "/api/usuarios/cadastro",
                "/api/usuarios/login",
                "/api/usuarios/recuperacao-senha",
                "/api/usuarios/redefinir-senha"
        );
    }
}
