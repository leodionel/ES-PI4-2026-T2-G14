package br.com.talhao.controller;

import java.util.Map; 

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

//Informa se o backend esta respondendo
@RestController
@RequestMapping("/status")
public class StatusController {

    @GetMapping
    public Map<String, String> consultar(){
        return Map.of("status", "ativo");
    }
}