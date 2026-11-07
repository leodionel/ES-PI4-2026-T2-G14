
package br.com.talhao.config;

import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.web.servlet.HandlerInterceptor;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

// Valida o token JWT das requisicoes autenticadas
public class JwtAuthInterceptor implements HandlerInterceptor {

    private final JwtDecoder jwtDecoder;

    public JwtAuthInterceptor(JwtDecoder jwtDecoder) {
        this.jwtDecoder = jwtDecoder;
    }

    @Override
    public boolean preHandle(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler) throws Exception {

        // Recupera o token enviado no cabecalho Authorization
        String authorization = request.getHeader("Authorization");

        // Verifica se o cabecalho usa o formato Bearer
        if (authorization == null ||
                !authorization.startsWith("Bearer ")) {

            response.sendError(
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Token JWT ausente"
            );
            return false;
        }

        // Extrai o token, removendo o prefixo Bearer
        String token = authorization.substring(7).trim();

        if (token.isEmpty()) {
            response.sendError(
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Token JWT vazio"
            );
            return false;
        }

        try {
            // Valida assinatura e prazo de validade do JWT
            Jwt jwt = jwtDecoder.decode(token);

            // Confere se o token foi emitido pela nossa API
            if (jwt.getIssuer() == null ||
                    !"talhao-api".equals(jwt.getIssuer().toString()) ||
                    jwt.getSubject() == null ||
                    jwt.getSubject().isBlank()) {

                response.sendError(
                        HttpServletResponse.SC_UNAUTHORIZED,
                        "Token JWT invalido"
                );
                return false;
            }

            // Guarda o ID autenticado para os Controllers
            request.setAttribute(
                    "usuarioIdAutenticado",
                    jwt.getSubject()
            );

            // Permite que a requisicao continue
            return true;

        } catch (JwtException | IllegalArgumentException e) {

            response.sendError(
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Token JWT invalido ou expirado"
            );
            return false;
        }
    }
}
