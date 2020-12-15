package com.example.sidecardemo;

import java.util.Random;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
public class DemoController {

    private final JdbcTemplate jdbcTemplate;
    public DemoController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping(path = "/")
    public ResponseEntity<String> get() {
//        log.info(jdbcTemplate.queryForMap("select count(*) from Person;").toString());
        Random r = new Random();
        String res = IntStream.range(0, r.nextInt(100))
            .mapToObj(i -> Integer.toString(r.nextInt(10)))
            .collect(Collectors.joining());
        log.info(res);
        return new ResponseEntity<>(res, HttpStatus.OK);
    }
}
