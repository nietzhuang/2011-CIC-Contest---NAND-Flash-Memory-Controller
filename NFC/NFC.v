`timescale 1ns/100ps
`include "ctrl.v"

module NFC(
    input                  clk,
    input                  rst,
    output                 done,
    inout   [7:0]          F_IO_A,
    output                 F_CLE_A, 
    output                 F_ALE_A,
    output                 F_REN_A,
    output                 F_WEN_A,
    input                  F_RB_A,
    inout   [7:0]          F_IO_B,
    output                 F_CLE_B,
    output                 F_ALE_B,
    output                 F_REN_B, 
    output                 F_WEN_B, 
    input                  F_RB_B 
);

    localparam    READ_CMD    = 3'b001, 
                  READ_ADDR   = 3'b010, 
                  WRITE_CMD   = 3'b100, 
                  WRITE_ADDR  = 3'b101, 
                  WRITE       = 3'b110;

    integer         i;

    wire [2:0]      state;          

    wire [2:0]      cnt_addr;
    wire [8:0]      cnt_data;
    wire [9:0]      cnt_page;  

    reg [7:0]       addr;
    wire [7:0]      cmd_a;
    wire [7:0]      cmd_b;

    wire            wait_rb;

    wire [7:0]      out_a;
    wire [7:0]      out_b;
    wire            out_en_a;
    wire            out_en_b;
    
    reg [7:0]       mem[511:0]; 

    ctrl ctrl0( 
        .clk(clk),
        .rst(rst),
        .done(done),
        .state(state),
        .cnt_addr(cnt_addr),
        .cnt_data(cnt_data),
        .cnt_page(cnt_page),
        .wait_rb(wait_rb),
        .F_CLE_A(F_CLE_A),
        .F_ALE_A(F_ALE_A),
        .F_REN_A(F_REN_A),
        .F_WEN_A(F_WEN_A),
        .F_RB_A(F_RB_A),
        .F_CLE_B(F_CLE_B),
        .F_ALE_B(F_ALE_B),
        .F_REN_B(F_REN_B),
        .F_WEN_B(F_WEN_B),
        .F_RB_B(F_RB_B)
    );

    assign out_en_a = (state == READ_CMD) || (state == READ_ADDR);
    assign out_en_b = (state == WRITE_CMD) || (state == WRITE_ADDR) || (state == WRITE);

    assign out_a = (state == READ_CMD)?     cmd_a :
                   (state == READ_ADDR)?    addr : 8'b0;
    assign out_b = (state == WRITE_CMD)?    cmd_b :
                   (state == WRITE_ADDR)?   addr :
                   (state == WRITE)?        mem[cnt_data] : 8'b0;
                                      
     
    assign F_IO_A = (out_en_a)? out_a : 8'bz;
    assign F_IO_B = (out_en_b)? out_b : 8'bz;
   
    assign cmd_a = 8'h00;  // assume read always starts from 1st page.
    assign cmd_b = (wait_rb)? 8'h10 : 8'h80;
    
    always@*begin
    // Assume A8 is always LOW
        case(cnt_addr)
            3'b000:
                addr = 8'b0;  // column.
            3'b010:
                addr = cnt_page[7:0];  // row
            3'b100:
                addr = {6'b0, cnt_page[9:8]};
            default:
                addr = 8'b0;
        endcase 
    end 
    
    // Store a page data into controller buffer. 
    always@(posedge clk)begin 
        if(rst)begin 
            for(i = 0; i < 512; i = i + 1)
                mem[i] <= 8'b0;
        end
        else begin  
            if(~F_REN_A)  
                mem[cnt_data] <= F_IO_A;
        end 
    end    
endmodule 
