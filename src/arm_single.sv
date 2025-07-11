

module testbench();

  logic        clk;
  logic        reset;

  logic [31:0] WriteData, DataAdr;
  logic        MemWrite;

  // instantiate device to be tested
  top dut(clk, reset, WriteData, DataAdr, MemWrite);
  
  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

endmodule

module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, DataAdr, 
           output logic        MemWrite);

  logic [31:0] PC, Instr, ReadData;
  
  // instantiate processor and memories
  arm arm(clk, reset, PC, Instr, MemWrite, DataAdr, 
          WriteData, ReadData);
  imem imem(PC, Instr);
  dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData);
endmodule

module dmem(input  logic        clk, we,
            input  logic [31:0] a, wd,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
endmodule

module imem(input  logic [31:0] a,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];

  initial
      $readmemh("memfile.dat",RAM);

  assign rd = RAM[a[31:2]]; // word aligned
endmodule

module arm(input  logic        clk, reset,
           output logic [31:0] PC,
           input  logic [31:0] Instr,
           output logic        MemWrite,
           output logic [31:0] ALUResult, WriteData,
           input  logic [31:0] ReadData);

  logic [3:0] ALUFlags;
  logic       RegWrite, MovFlag, LslFlag,
              ALUSrc, MemtoReg, PCSrc;
  logic [1:0] RegSrc, ImmSrc;
  logic [2:0] ALUControl;

  controller c(clk, reset, Instr[31:5], ALUFlags, 
               RegSrc, RegWrite, ImmSrc, 
               ALUSrc, ALUControl,
               MemWrite, MemtoReg, MovFlag, LslFlag, PCSrc);
  datapath dp(clk, reset, 
              RegSrc, RegWrite, ImmSrc,
              MovFlag, LslFlag, ALUSrc, ALUControl,
              MemtoReg, PCSrc,
              ALUFlags, PC, Instr,
              ALUResult, WriteData, ReadData);
endmodule

module controller(input  logic         clk, reset,
                  input  logic [31:5] Instr,
                  input  logic [3:0]   ALUFlags,
                  output logic [1:0]   RegSrc,
                  output logic         RegWrite,
                  output logic [1:0]   ImmSrc,
                  output logic         ALUSrc, 
                  output logic [2:0]   ALUControl,
                  output logic         MemWrite, MemtoReg,
                  output logic         MovFlag, LslFlag,
                  output logic         PCSrc);

  logic [1:0] FlagW;
  logic       PCS, RegW, MemW, MovF, LslF;
  
  decoder dec(Instr[27:26], Instr[25:20], Instr[15:12], Instr[6:5], Instr[11:7],
              FlagW, PCS, RegW, MemW,
              MemtoReg, ALUSrc, MovF, LslF, ImmSrc, RegSrc, ALUControl);
  condlogic cl(clk, reset, Instr[31:28], ALUFlags,
             FlagW, PCS, RegW, MemW, MovF, LslF,
             PCSrc, RegWrite, MemWrite, MovFlag, LslFlag);
endmodule

module decoder(input  logic [1:0] Op,
               input  logic [5:0] Funct,
               input  logic [3:0] Rd,
               input  logic [1:0] ShiftType,     // Instr[6:5]
               input  logic [4:0] ShiftAmt,      // Instr[11:7]
               output logic [1:0] FlagW,
               output logic       PCS, RegW, MemW,
               output logic       MemtoReg, ALUSrc,
               output logic       MovF, LslF,
               output logic [1:0] ImmSrc, RegSrc,
               output logic [2:0] ALUControl);

  logic [9:0] controls;
  logic       Branch, ALUOp;
  logic       regw_internal;
  logic       isLSL, isMOV;

  assign isLSL = (Funct[4:1] == 4'b1101) &&
                 (ShiftType == 2'b00) &&
                 (ShiftAmt != 5'b00000);

  assign isMOV = (Funct[4:1] == 4'b1101) &&
               (ShiftType == 2'b00); 

  // Main Decoder
  always_comb begin
    case (Op)
      2'b00: begin
        if (Funct[5])       controls = 10'b0000101001;
        else                controls = 10'b0000001001;
      end
      2'b01: begin // Memory instructions
        if (Funct[0])
          controls = 10'b0001111000; // LDR
        else
          controls = 10'b1001110100; // STR
      end
      2'b10: controls = 10'b0110100010; // Branch
      default: controls = 10'bxxxxxxxxxx; // Invalid
    endcase
  end

  assign {RegSrc, ImmSrc, ALUSrc, MemtoReg, 
          regw_internal, MemW, Branch, ALUOp} = controls;

  // ALU Decoder + Flag and Shift Handling
  always_comb begin
    // Defaults
    ALUControl = 3'b000;
    FlagW      = 2'b00;
    MovF       = 1'b0;
    LslF       = 1'b0;

    if (ALUOp) begin
      if (isLSL)
        ALUControl = 3'b101;
      else begin
        case (Funct[4:1])
          4'b0100: ALUControl = 3'b000; // ADD
          4'b1101: ALUControl = 3'b000; // MOV (sem shift)
          4'b0010: ALUControl = 3'b001; // SUB
          4'b1010: ALUControl = 3'b001; // CMP
          4'b0000: ALUControl = 3'b010; // AND
          4'b1000: ALUControl = 3'b010; // TST
          4'b1100: ALUControl = 3'b011; // ORR
          4'b0001: ALUControl = 3'b100; // EOR
          default: ALUControl = 3'bxxx;
        endcase
      end

      MovF = isMOV;
      LslF = isLSL;

      FlagW[1] = Funct[0]; // S bit
      FlagW[0] = Funct[0] & (
                    ALUControl == 3'b000 || // ADD, MOV
                    ALUControl == 3'b001 || // SUB, CMP
                    ALUControl == 3'b010    // AND, TST
                 );
    end
  end

  // Writeback control (RegW)
  always_comb begin
    if (ALUOp && (
      Funct[4:1] == 4'b1010 || // CMP
      Funct[4:1] == 4'b1000    // TST
    ))
      RegW = 1'b0;
    else
      RegW = regw_internal;
  end

  // PC update condition
  assign PCS = ((Rd == 4'b1111) & RegW) | Branch;

endmodule



module condlogic(input  logic       clk, reset,
                 input  logic [3:0] Cond,
                 input  logic [3:0] ALUFlags,
                 input  logic [1:0] FlagW,
                 input  logic       PCS, RegW, MemW, MovF, LslF,
                 output logic       PCSrc, RegWrite, MemWrite, MovFlag, LslFlag);
                 
  logic [1:0] FlagWrite;
  logic [3:0] Flags;
  logic       CondEx;

  flopenr #(2)flagreg1(clk, reset, FlagWrite[1], 
                       ALUFlags[3:2], Flags[3:2]);
  flopenr #(2)flagreg0(clk, reset, FlagWrite[0], 
                       ALUFlags[1:0], Flags[1:0]);

  // write controls are conditional
  condcheck cc(Cond, Flags, CondEx);
  assign FlagWrite = FlagW & {2{CondEx}};
  assign RegWrite  = RegW  & CondEx;
  assign MemWrite  = MemW  & CondEx;
  assign PCSrc     = PCS   & CondEx;
  assign MovFlag   = MovF  & CondEx;
  assign LslFlag   = LslF  & CondEx;
endmodule    

module condcheck(input  logic [3:0] Cond,
                 input  logic [3:0] Flags,
                 output logic       CondEx);
  
  logic neg, zero, carry, overflow, ge;
  
  assign {neg, zero, carry, overflow} = Flags;
  assign ge = (neg == overflow);
                  
  always_comb
    case(Cond)
      4'b0000: CondEx = zero;             // EQ
      4'b0001: CondEx = ~zero;            // NE
      4'b0010: CondEx = carry;            // CS
      4'b0011: CondEx = ~carry;           // CC
      4'b0100: CondEx = neg;              // MI
      4'b0101: CondEx = ~neg;             // PL
      4'b0110: CondEx = overflow;         // VS
      4'b0111: CondEx = ~overflow;        // VC
      4'b1000: CondEx = carry & ~zero;    // HI
      4'b1001: CondEx = ~(carry & ~zero); // LS
      4'b1010: CondEx = ge;               // GE
      4'b1011: CondEx = ~ge;              // LT
      4'b1100: CondEx = ~zero & ge;       // GT
      4'b1101: CondEx = ~(~zero & ge);    // LE
      4'b1110: CondEx = 1'b1;             // Always
      default: CondEx = 1'bx;             // undefined
    endcase
endmodule

module datapath(input  logic        clk, reset,
                input  logic [1:0]  RegSrc,
                input  logic        RegWrite,
                input  logic [1:0]  ImmSrc,
                input  logic        MovFlag, LslFlag,
                input  logic        ALUSrc,
                input  logic [2:0]  ALUControl,
                input  logic        MemtoReg,
                input  logic        PCSrc,
                output logic [3:0]  ALUFlags,
                output logic [31:0] PC,
                input  logic [31:0] Instr,
                output logic [31:0] ALUResult, WriteData,
                input  logic [31:0] ReadData);

  logic [31:0] PCNext, PCPlus4, PCPlus8;
  logic [31:0] ExtImm, SrcA, SrcB, Result;
  logic [31:0] SrcA_actual, SrcB_actual;
  logic [31:0] ShiftAmount; 
  logic [3:0]  RA1, RA2;

  // next PC logic
  mux2 #(32)  pcmux(PCPlus4, Result, PCSrc, PCNext);
  flopr #(32) pcreg(clk, reset, PCNext, PC);
  adder #(32) pcadd1(PC, 32'b100, PCPlus4);
  adder #(32) pcadd2(PCPlus4, 32'b100, PCPlus8);

  // register file logic
  mux2 #(4)   ra1mux(Instr[19:16], 4'b1111, RegSrc[0], RA1);
  mux2 #(4)   ra2mux(Instr[3:0], Instr[15:12], RegSrc[1], RA2);
  regfile     rf(clk, RegWrite, RA1, RA2,
                 Instr[15:12], Result, PCPlus8, 
                 SrcA, WriteData); 
  mux2 #(32)  resmux(ALUResult, ReadData, MemtoReg, Result);
  extend      ext(Instr[23:0], ImmSrc, ExtImm);

  assign ShiftAmount = {27'b0, Instr[11:7]};

  // Mux para selecionar o operando de deslocamento
  mux2 #(32) shiftmux(SrcA, ShiftAmount, LslFlag, SrcB_actual);

  // Lógica corrigida para ALUSrc - não force para 0 quando LslFlag=1
  wire effectiveALUSrc = ALUSrc;
  mux2 #(32) srcbmux(SrcB_actual, ExtImm, effectiveALUSrc, SrcB);
  mux2 #(32) srcamux(SrcA, 32'b0, MovFlag, SrcA_actual);
  

  alu         alu(SrcA_actual, SrcB, ALUControl, 
                  ALUResult, ALUFlags);
endmodule


module regfile(input  logic        clk, 
               input  logic        we3, 
               input  logic [3:0]  ra1, ra2, wa3, 
               input  logic [31:0] wd3, r15,
               output logic [31:0] rd1, rd2);

  logic [31:0] rf[14:0];

  // three ported register file
  // read two ports combinationally
  // write third port on rising edge of clock
  // register 15 reads PC+8 instead

  always_ff @(posedge clk)
    if (we3) rf[wa3] <= wd3;	

  assign rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1];
  assign rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];
endmodule

module extend(input  logic [23:0] Instr,
              input  logic [1:0]  ImmSrc,
              output logic [31:0] ExtImm);
 
  always_comb
    case(ImmSrc) 
               // 8-bit unsigned immediate
      2'b00:   ExtImm = {24'b0, Instr[7:0]};  
               // 12-bit unsigned immediate 
      2'b01:   ExtImm = {20'b0, Instr[11:0]}; 
               // 24-bit two's complement shifted branch 
      2'b10:   ExtImm = {{6{Instr[23]}}, Instr[23:0], 2'b00}; 
      default: ExtImm = 32'bx; // undefined
    endcase             
endmodule

module adder #(parameter WIDTH=8)
              (input  logic [WIDTH-1:0] a, b,
               output logic [WIDTH-1:0] y);
             
  assign y = a + b;
endmodule

module flopenr #(parameter WIDTH = 8)
                (input  logic             clk, reset, en,
                 input  logic [WIDTH-1:0] d, 
                 output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset)   q <= 0;
    else if (en) q <= d;
endmodule

module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             s, 
              output logic [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule


module alu(input  logic [31:0] a, b,
           input  logic [2:0]  ALUControl,
           output logic [31:0] Result,
           output logic [3:0]  ALUFlags);

  logic        neg, zero, carry, overflow;
  logic [31:0] condinvb;
  logic [32:0] sum;

  assign condinvb = ALUControl[0] ? ~b : b;
  assign sum = a + condinvb + ALUControl[0];

  always_comb
    casex (ALUControl[2:0])
      3'b00?: Result = sum;
      3'b010: Result = a & b;
      3'b011: Result = a | b;
      3'b100: Result = a ^ b;
      3'b101: Result = a << b[4:0];
    endcase

  assign neg      = Result[31];
  assign zero     = (Result == 32'b0);
  assign carry    = (ALUControl[2] == 1'b0) & sum[32];
  assign overflow = (ALUControl[2] == 1'b0) & 
                    ~(a[31] ^ b[31] ^ ALUControl[0]) & 
                    (a[31] ^ sum[31]); 
  assign ALUFlags    = {neg, zero, carry, overflow};
endmodule