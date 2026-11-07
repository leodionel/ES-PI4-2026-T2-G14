
package br.com.talhao.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
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

// Recebe as requisicoes HTTP relacionadas aos usuarios
@RestController
@RequestMapping("/api/usuarios")
public class UsuarioController {

    private final UsuarioService usuarioService;
    private final JwtService jwtService;

    // Recebe os Services pelo construtor
    public UsuarioController(
            UsuarioService usuarioService,
            JwtService jwtService) {

        this.usuarioService = usuarioService;
        this.jwtService = jwtService;
    }

    // Endpoint para cadastrar um novo usuario
    @PostMapping("/cadastro")
    public ResponseEntity<UsuarioResponse> cadastrar(
            @Valid @RequestBody CadastroUsuarioRequest dados) {

        // Envia os dados para o Service realizar o cadastro
        UsuarioResponse usuario = usuarioService.cadastrar(dados);

        // Retorna HTTP 201 e os dados do usuario cadastrado
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(usuario);
    }

    // Endpoint para realizar o login
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(
            @Valid @RequestBody LoginRequest dados) {

        // Envia as credenciais para o Service validar
        UsuarioResponse usuario = usuarioService.login(dados);

        // Gera um token JWT usando o ID do usuario autenticado
        String token = jwtService.gerarToken(usuario.id());

        // Monta a resposta com o token e os dados do usuario
        LoginResponse resposta = new LoginResponse(token, usuario);

        // Retorna HTTP 200 com o token JWT e os dados do usuario
        return ResponseEntity.ok(resposta);
    }
}
