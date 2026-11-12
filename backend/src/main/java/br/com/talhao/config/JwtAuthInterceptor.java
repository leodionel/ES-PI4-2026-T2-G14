
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

        // Permite requisicoes OPTIONS (preflight CORS)
        // sem exigir um token JWT
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        // Recupera o cabecalho Authorization
        String authorization = request.getHeader("Authorization");

        // Verifica se foi enviado um token Bearer
        if (authorization == null ||
                !authorization.startsWith("Bearer ")) {

            response.sendError(
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Token JWT ausente"
            );
            return false;
        }

        // Extrai o token
        String token = authorization.substring(7).trim();

        if (token.isEmpty()) {
            response.sendError(
                    HttpServletResponse.SC_UNAUTHORIZED,
                    "Token JWT vazio"
            );
            return false;
        }

        try {
            // Verifica assinatura e expiracao
            Jwt jwt = jwtDecoder.decode(token);

            // Le o emissor diretamente como String
            String emissor = jwt.getClaimAsString("iss");

            // Recupera o ID do usuario
            String usuarioId = jwt.getSubject();

            // Verifica se o token pertence a nossa API
            if (!"talhao-api".equals(emissor) ||
                    usuarioId == null ||
                    usuarioId.isBlank()) {

                response.sendError(
                        HttpServletResponse.SC_UNAUTHORIZED,
                        "Token JWT invalido"
                );
                return false;
            }

            // Disponibiliza o ID autenticado aos Controllers
            request.setAttribute(
                    "usuarioIdAutenticado",
                    usuarioId
            );

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
