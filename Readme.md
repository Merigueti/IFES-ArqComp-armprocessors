
# Extensão de Processador ARM Monociclo

Este repositório apresenta a implementação e a ampliação de um processador ARM com arquitetura monociclo, desenvolvido em **SystemVerilog**. A versão inicial da arquitetura conta com caminho de dados e unidade de controle separados, com suporte a instruções básicas. O projeto foi posteriormente expandido com novas instruções e módulos complementares.

## 📁 Estrutura do Repositório

```
├── src/
│   ├── arm_multi.sv
│   ├── arm_multi.vhd
│   ├── arm_pipelined.sv
│   ├── arm_pipelined.vhd
│   └── arm_single.sv
│   └── arm_single.vhd
├── testbench/
│   ├── memfile.s             # Programa de teste original (assembly)
│   ├── memfile.dat           # Programa de teste original (binário)
├── schematic/
│   └── processor\_diagram.png # Diagrama esquemático do processador
├── doc/
│   ├── Trabalho Prático.md         # Descrição do trabalho
├── README.md
└── LICENSE
```
## ⚙️ Funcionalidades

* Simulação de processador ARM monociclo com suporte às instruções:

  * ADD, SUB, AND, ORR, LDR, STR, B
* Extensão para incluir novas instruções:

  * MOV, CMP, TST, EOR, LSL, ASR, BL
  * Suporte a registradores com deslocamento em instruções do tipo DP
* Testbench customizado para validação funcional

## ▶️ Como Usar

1. Compile os arquivos SystemVerilog localizados em `src/` utilizando o ModelSim ou outro simulador compatível.
2. Carregue o arquivo `memfile.dat` (ou `memfile2.dat`) na memória de instruções.
3. Execute a simulação e analise os sinais através do simulador.

## 🧩 Dependências

* [ModelSim](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/modelSim.html) (ou outro simulador compatível)
* Editor de texto com suporte a Verilog/SystemVerilog, como Visual Studio Code

## 📄 Licença

O código está disponível sob uma licença de uso livre, destinada exclusivamente a fins educacionais e não comerciais.
