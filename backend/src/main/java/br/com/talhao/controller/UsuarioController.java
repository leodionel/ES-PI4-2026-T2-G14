
package br.com.talhao.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import br.com.talhao.dto.CadastroUsuarioRequest;
import br.com.talhao.dto.LoginRequest;
import br.com.talhao.dto.LoginResponse;
import br.com.talhao.dto.UsuarioResponse;
import br.com.talhao.service.JwtService;
import br.com.talhao.service.UsuarioService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioService usuarioService;
    private final JwtService jwtService;

    public UsuarioController(
            UsuarioService usuarioService,
            JwtService jwtService) {

        this.usuarioService = usuarioService;
        this.jwtService = jwtService;
    }

    // CADASTRO DE USUARIO
    @PostMapping("/cadastro")
    public ResponseEntity<UsuarioResponse> cadastrar(
            @Valid @RequestBody CadastroUsuarioRequest dados) {

        UsuarioResponse usuario =
                usuarioService.cadastrar(dados);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(usuario);
    }

    // LOGIN
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(
            @Valid @RequestBody LoginRequest dados) {

        UsuarioResponse usuario =
                usuarioService.login(dados);

        String token = jwtService.gerarToken(usuario.id());

        LoginResponse resposta =
                new LoginResponse(token, usuario);

        return ResponseEntity.ok(resposta);
    }

    // BUSCAR PERFIL DO USUARIO AUTENTICADO
    @GetMapping("/me")
    public ResponseEntity<UsuarioResponse> meuPerfil(
            @RequestAttribute("usuarioIdAutenticado")
            String usuarioId) {

        UsuarioResponse usuario =
                usuarioService.buscarPerfil(usuarioId);

        return ResponseEntity.ok(usuario);
    }
}
