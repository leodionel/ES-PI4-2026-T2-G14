package br.com.talhao.service;

import java.time.Instant;
import java.util.Locale;

import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import br.com.talhao.dto.CadastroUsuarioRequest;
import br.com.talhao.dto.UsuarioResponse;
import br.com.talhao.model.Usuario;
import br.com.talhao.repository.UsuarioRepository;

//Responsavel pelas regras de negocio dos usuarios
@Service 
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;

    //Recebe as dependencias pelo construtor
    public UsuarioService(
        UsuarioRepository usuarioRepository,
        PasswordEncoder passwordEncoder) {

    this.usuarioRepository = usuarioRepository;
    this.passwordEncoder = passwordEncoder;
}

//Realiza o cadastro de um novo usuario 
public UsuarioResponse cadastrar(CadastroUsuarioRequest dados) {

    //Remove espaços e padroniza o email em minusculo
    String email = dados.email()
        .trim()
        .toLowerCase(Locale.ROOT);

        //Impede o cadastro de um email ja utilizado
        if (usuarioRepository.existsByEmail(email)) {
            throw new ResponseStatusException(
                HttpStatus.CONFLICT,
                "E-mail já cadastrado"
            );
        }

        //Protege a senha utilizando BCrypt
        String senhaHash = passwordEncoder.encode(dados.senha());

        //Cria o usuario com os dados recebidos 
        Usuario usuario = new Usuario( 
            null,
            dados.nome().trim(),
            email,
            dados.telefone(),
            senhaHash,
            Instant.now()
        );

        try {
            //Salva o usuario no MongoDB
            Usuario usuarioSalvo = usuarioRepository.save(usuario);

            //Retorna os dados permitidos, sem a senha
            return new UsuarioResponse(
                usuarioSalvo.id(),
                usuarioSalvo.nome(),
                usuarioSalvo.email(),
                usuarioSalvo.telefone(),
                usuarioSalvo.criadoEm()
            );
        } catch (DuplicateKeyException erro) {
            
            //Trata também cadastros simultâneos com o mesmo email
            throw new ResponseStatusException(
                HttpStatus.CONFLICT,
                "E-mail já cadastrado",
                erro
            );
        }
    }
}