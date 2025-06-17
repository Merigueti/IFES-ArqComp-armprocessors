


### Fórmula geral de speedup:

$$
\text{Speedup} = \frac{\text{Tempo de execução da baseline}}{\text{Tempo de execução da nova versão}}
$$

---

### Em nosso caso:

Tendo **"arm\_single" (205ps)** como nossa baseline.

Então:

#### Speedup do "arm\_multi" (multi-core):

$$
\text{Speedup}_{multi} = \frac{205ps}{755ps} \approx 0,27
$$


---

#### Speedup do "arm\_pipelined":

$$
\text{Speedup}_{pipelined} = \frac{205ps}{375ps} \approx 0,55
$$


---

### Resumo final:

| Processador    | Tempo (ps) | Speedup (vs single) |
| -------------- | ---------- | ------------------- |
| arm\_single    | 205        | 1,00x               |
| arm\_multi     | 755        | 0,27x               |
| arm\_pipelined | 375        | 0,55x               |
