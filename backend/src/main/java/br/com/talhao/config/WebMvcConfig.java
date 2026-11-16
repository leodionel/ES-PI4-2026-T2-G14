
package br.com.talhao.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    private final JwtDecoder jwtDecoder;

    public WebMvcConfig(JwtDecoder jwtDecoder) {
        this.jwtDecoder = jwtDecoder;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {

        registry.addInterceptor(
                new JwtAuthInterceptor(jwtDecoder)
        ).addPathPatterns(

                // PERFIL DO USUARIO AUTENTICADO
                "/api/usuarios/me",

                // TALHOES
                "/api/talhoes",
                "/api/talhoes/**",

                // CULTURAS
                "/api/culturas",
                "/api/culturas/**",

                // PROPRIEDADES
                "/api/propriedades",
                "/api/propriedades/**",

                // ANALISES DE SOLO
                "/api/analises-solo",
                "/api/analises-solo/**",

                // RELATORIOS PDF
                "/api/relatorios",
                "/api/relatorios/**"
        );
    }
}
