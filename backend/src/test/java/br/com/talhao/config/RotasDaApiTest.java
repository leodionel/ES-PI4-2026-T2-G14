package br.com.talhao.config;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import br.com.talhao.service.AnaliseSoloService;
import br.com.talhao.service.CulturaService;
import br.com.talhao.service.HistoricoTalhaoService;
import br.com.talhao.service.JwtService;
import br.com.talhao.service.PerfilService;
import br.com.talhao.service.PlantioService;
import br.com.talhao.service.PropriedadeService;
import br.com.talhao.service.RecuperacaoSenhaService;
import br.com.talhao.service.RelatorioPdfService;
import br.com.talhao.service.SimulacaoService;
import br.com.talhao.service.StatusSoloService;
import br.com.talhao.service.TalhaoResumoService;
import br.com.talhao.service.TalhaoService;
import br.com.talhao.service.UsuarioService;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Carrega TODOS os controllers juntos. Os outros testes de controller
// carregam um por vez e nao enxergam dois controllers com a mesma rota
// (o Spring nao sobe com "Ambiguous mapping") nem uma rota sem protecao.
//
// Ao criar um controller novo, acrescente aqui um @MockitoBean para cada
// Service dele; sem isso este teste falha e lembra de fazer isso.
@WebMvcTest
class RotasDaApiTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private JwtDecoder jwtDecoder;

    @MockitoBean
    private AnaliseSoloService analiseSoloService;

    @MockitoBean
    private CulturaService culturaService;

    @MockitoBean
    private HistoricoTalhaoService historicoTalhaoService;

    @MockitoBean
    private JwtService jwtService;

    @MockitoBean
    private PerfilService perfilService;

    @MockitoBean
    private PlantioService plantioService;

    @MockitoBean
    private PropriedadeService propriedadeService;

    @MockitoBean
    private RecuperacaoSenhaService recuperacaoSenhaService;

    @MockitoBean
    private RelatorioPdfService relatorioPdfService;

    @MockitoBean
    private SimulacaoService simulacaoService;

    @MockitoBean
    private StatusSoloService statusSoloService;

    @MockitoBean
    private TalhaoResumoService talhaoResumoService;

    @MockitoBean
    private TalhaoService talhaoService;

    @MockitoBean
    private UsuarioService usuarioService;

    // TESTE 1 - O contexto sobe com todos os controllers (sem rota repetida)
    @Test
    void deveCarregarTodosOsControllersSemRotaRepetida() throws Exception {

        mockMvc.perform(get("/status"))
                .andExpect(status().isOk());
    }

    // TESTE 2 - Toda rota da API, sem token, responde HTTP 401
    @ParameterizedTest
    @CsvSource({
            "GET,/api/usuarios/me",
            "PUT,/api/usuarios/me",
            "GET,/api/talhoes",
            "POST,/api/talhoes",
            "GET,/api/talhoes/t1",
            "PUT,/api/talhoes/t1",
            "DELETE,/api/talhoes/t1",
            "GET,/api/talhoes/t1/status-solo",
            "GET,/api/talhoes/t1/historico",
            "GET,/api/talhoes/t1/plantios",
            "POST,/api/talhoes/t1/plantios",
            "PUT,/api/talhoes/t1/plantios/p1/colheita",
            "POST,/api/talhoes/t1/simulacoes",
            "GET,/api/culturas",
            "GET,/api/propriedades",
            "POST,/api/propriedades",
            "GET,/api/propriedades/p1",
            "GET,/api/analises-solo",
            "POST,/api/analises-solo",
            "GET,/api/analises-solo/a1",
            "GET,/api/relatorios/propriedade/p1/pdf"
    })
    void deveExigirTokenEmTodasAsRotasDaApi(String metodo, String caminho)
            throws Exception {

        mockMvc.perform(request(HttpMethod.valueOf(metodo), caminho))
                .andExpect(status().isUnauthorized());
    }

    // TESTE 3 - Cadastro, login e recuperacao de senha continuam abertos (sem token chega na
    // validacao do corpo e responde 400, nao 401)
    @ParameterizedTest
    @CsvSource({
            "/api/usuarios/cadastro",
            "/api/usuarios/login",
            "/api/usuarios/recuperar-senha",
            "/api/usuarios/redefinir-senha"
    })
    void devemFicarAbertasAsRotasDeCadastroELogin(String caminho)
            throws Exception {

        mockMvc.perform(post(caminho)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
                .andExpect(status().isBadRequest());
    }
}
