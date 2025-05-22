// `timescale 1ns/1ps //OUTDATED CODE. DOES NOT PASS GATELEVEL TESTS
// module ramram (
//     input logic clk,
//     input logic reset,
//     input logic wb0_stb, //strobe input, which means the master is requesting a transaction. when high and subordinate is ready, do trsnsation
//     input logic wb0_we, // write enable
//     input logic [3:0] wb0_sel, //1111 = all 4 bytes, 0001 = lowest byte
//     input logic [7:0] wb0_addr, //addy
//     input logic [31:0] wb0_data_i, // write data
//     output logic wb0_ack,  //ack for one cc after transfer is over
//     output logic [31:0] wb0_data_o, // read data output, 
//     output logic wb0_stall, // output to say that i cannnot takee anything... mmmph
//     // the rest of them
//     input  logic wb1_stb,
//     input  logic wb1_we,
//     input  logic [3:0] wb1_sel,
//     input  logic [7:0] wb1_addr,
//     input  logic [31:0] wb1_data_i,
//     output logic wb1_ack,
//     output logic [31:0] wb1_data_o,
//     output logic wb1_stall
// );

// logic busy0;       // if ememory thing is happening, is 1
// logic busy1;
// logic who; // 0 = port0, 1 = port1
// logic en; //
// logic [3:0] we0; //wrie enable, 
// logic [3:0] we1;
// logic [7:0]  addr;
// logic [31:0] di; //datain
// wire  [31:0] d_out0; //dataout
// wire [31:0] d_out1;

// DFFRAM256x32 dffram0 (
//     .CLK(clk),
//     .WE0(we0),
//     .EN0(en),
//     .Di0(wb0_data_i),
//     .Do0(d_out0),
//     .A0(wb0_addr)
// );

// DFFRAM256x32 dffram1 (
//     .CLK(clk),
//     .WE0(we1),
//     .EN0(en),
//     .Di0(wb1_data_i),
//     .Do0(d_out1),
//     .A0(wb1_addr)
// );


// always_ff @(posedge clk or posedge reset) begin
//     if (reset)
//         who <= 1'b0;
//     else
//     begin
//         if (wb0_stb && !wb1_stb) who <= 1'b0;
//         else if (!wb0_stb && wb1_stb) who <= 1'b1;
//         else if (wb0_stb && wb1_stb)  who <= ~who;
//         hi = clk;
//     end
// end

// assign en = (who == 0 && wb0_stb) || (who == 1 && wb1_stb);
// assign we0 = (wb0_we ? wb0_sel : 4'b0000); //if who decides port 0, and wb0_we is high, decide bytes with wb_sel
// assign we1 = (wb1_we ? wb1_sel : 4'b0000); 
// assign addr = (who == 0) ? wb0_addr : wb1_addr;    //depending on who, will choose which address to output
// assign di = (who == 0) ? wb0_data_i : wb1_data_i;  //depening on who, will choose which port to write data from

// always_ff @(posedge clk or posedge reset) begin
//     if (reset) begin
//         wb0_ack     <= 0;
//         wb1_ack     <= 0;
//         wb0_data_o  <= 32'b0;
//         wb1_data_o  <= 32'b0;
//         busy0       <= 0;
//         busy1       <= 0;
//     end else begin
//         wb0_ack <= 0;
//         wb1_ack <= 0;

//         // Accept new transaction
//         if (en) begin
//             if (who == 0) busy0 <= 1;
//             else          busy1 <= 1;
//         end 
//         // Complete Port 0 transaction
//         if (busy0) begin
//             wb0_ack    <= 1;
//             wb0_data_o <= d_out0;
//             busy0      <= 0;
//         end 
//         // Complete Port 1 transaction
//         if (busy1) begin
//             wb1_ack    <= 1;
//             wb1_data_o <= d_out1;
//             busy1      <= 0;
//         end
//     end
// end


// assign wb0_stall = (who != 0) || busy0;
// assign wb1_stall = (who != 1) || busy1;

// endmodule
`timescale 1ns/1ps
module ramram (
    input  logic        clk,
    input  logic        reset,
    input  logic        wb0_stb,
    input  logic        wb0_we,
    input  logic [3:0]  wb0_sel,
    input  logic [7:0]  wb0_addr,
    input  logic [31:0] wb0_data_i,
    output logic        wb0_ack,
    output logic [31:0] wb0_data_o,
    output logic        wb0_stall,
    
    input  logic        wb1_stb,
    input  logic        wb1_we,
    input  logic [3:0]  wb1_sel,
    input  logic [7:0]  wb1_addr,
    input  logic [31:0] wb1_data_i,
    output logic        wb1_ack,
    output logic [31:0] wb1_data_o,
    output logic        wb1_stall
);

    logic [7:0]  sel_addr;
    logic [31:0] sel_data;
    logic [3:0]  sel_we;
    logic        access0, access1;
    logic        who;

    // Arbitration toggle logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            who <= 0;
        else if (wb0_stb && !wb1_stb)
            who <= 0;
        else if (!wb0_stb && wb1_stb)
            who <= 1;
        else if (wb0_stb && wb1_stb)
            who <= ~who;
    end

    // Muxed write signals
    assign sel_addr = (who == 0) ? wb0_addr    : wb1_addr;
    assign sel_data = (who == 0) ? wb0_data_i  : wb1_data_i;
    assign sel_we   = (who == 0 && wb0_we) ? wb0_sel :
                      (who == 1 && wb1_we) ? wb1_sel : 4'b0000;

    // RAM instances
    logic [31:0] d_out0, d_out1;

    DFFRAM256x32 dffram0 (
        .CLK(clk),
        .WE0((who == 0) ? sel_we : 4'b0000),
        .EN0(1'b1),
        .Di0(sel_data),
        .Do0(d_out0),
        .A0((who == 0) ? sel_addr : wb0_addr)
    );

    DFFRAM256x32 dffram1 (
        .CLK(clk),
        .WE0((who == 1) ? sel_we : 4'b0000),
        .EN0(1'b1),
        .Di0(sel_data),
        .Do0(d_out1),
        .A0((who == 1) ? sel_addr : wb1_addr)
    );

    // Pipeline stage for ack and output
    logic last_access0, last_access1;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            last_access0 <= 0;
            last_access1 <= 0;
        end else begin
            last_access0 <= (who == 0 && wb0_stb && !wb0_stall);
            last_access1 <= (who == 1 && wb1_stb && !wb1_stall);
        end
    end

    always_comb begin
        // Stall if it’s not your turn or arbitration chose the other
        wb0_stall = (who != 0) && wb1_stb;
        wb1_stall = (who != 1) && wb0_stb;

        // ACK generation (pipelined one cycle after access)
        wb0_ack = last_access0;
        wb1_ack = last_access1;

        // Data output from corresponding RAM
        wb0_data_o = d_out0;
        wb1_data_o = d_out1;
    end

endmodule