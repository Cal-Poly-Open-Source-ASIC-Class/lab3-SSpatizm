`timescale 1ns/1ps
module ramramtb;
    `ifdef USE_POWER_PINS
        wire VPWR;
        wire VGND;
        assign VPWR=1;
        assign VGND=0;
    `endif
    logic clk;
    logic rst;
    logic wb0_stb;
    logic wb0_we;
    logic [3:0] wb0_sel;
    logic [7:0] wb0_addr;
    logic [31:0] wb0_data_i;
    logic wb0_ack;
    logic [31:0] wb0_data_o;
    logic wb0_stall;
    logic wb1_stb;
    logic wb1_we;
    logic [3:0] wb1_sel;
    logic [7:0] wb1_addr;
    logic [31:0] wb1_data_i;
    logic wb1_ack;
    logic [31:0] wb1_data_o;
    logic wb1_stall;
    int cycle_count;
    initial clk = 0;

    always #5 clk = ~clk;

    ramram dualport (
        .clk(clk),
        .reset(rst),
        .wb0_stb(wb0_stb),
        .wb0_we(wb0_we),
        .wb0_sel(wb0_sel),
        .wb0_addr(wb0_addr),
        .wb0_data_i(wb0_data_i),
        .wb0_ack(wb0_ack),
        .wb0_data_o(wb0_data_o),
        .wb0_stall(wb0_stall),
        .wb1_stb(wb1_stb),
        .wb1_we(wb1_we),
        .wb1_sel(wb1_sel),
        .wb1_addr(wb1_addr),
        .wb1_data_i(wb1_data_i),
        .wb1_ack(wb1_ack),
        .wb1_data_o(wb1_data_o),
        .wb1_stall(wb1_stall),
        .*
    );
    initial begin
        // Name as needed
        $dumpfile("ramram_tb.vcd");
        $dumpvars(2, ramramtb);
    end
    
    initial #100000 $error("Timeout");

    initial begin //init values
        rst = 0;
        #20
        rst = 1;
        wb0_stb = 0; wb0_we = 0; wb0_sel = 4'b1111; wb0_addr = 8'h00; wb0_data_i = 32'hDEADBEEF;
        wb1_stb = 0; wb1_we = 0; wb1_sel = 4'b1111; wb1_addr = 8'h00; wb1_data_i = 32'h0;
        #20;
        rst = 0; 
        //TEST 1: WRITE AND READ FROM PORT ZERO
        @(posedge clk); //WRITE TO PORT ZERO
        wb0_addr = 8'h42;
        wb0_data_i = 32'hFEEDBEEF;
        wb0_we = 1;
        wb0_stb = 1;
        @(posedge clk);
        while(!wb0_ack) @(posedge clk);
        wb0_stb = 0;
        wb0_we = 0;
        @(posedge clk);
        //READ FROM PORT ZERO
        wb0_addr = 8'h42;
        wb0_stb = 1;
        @(posedge clk);
        while(!wb0_ack) @(posedge clk);
        wb0_stb = 0;
        @(posedge clk);
        $display("READ BACK @42: %h", wb0_data_o);
        if (wb0_data_o !== 32'hFEEDBEEF) $error("etst 1 failedg");
        //TEST 2: WRITE AND READ FROM PORT ONE
        @(posedge clk);
        wb1_addr = 8'h24;
        wb1_data_i = 32'hDEEDBEEF;
        wb1_we = 1;
        wb1_stb = 1;
        @(posedge clk);
        while(!wb1_ack) @(posedge clk);
        wb1_stb = 0;
        wb1_we = 0;
        @(posedge clk);
        //READ FROM PORT 1
        wb1_stb = 1;
        while(!wb1_ack) @(posedge clk);
        wb1_stb = 0;
        @(posedge clk);
        $display("READ BACK @24: %h", wb1_data_o);
        if (wb1_data_o !== 32'hDEEDBEEF) $error("ftest 2 failedg");
        //TEST 3: WRITE CONTENTION
        @(posedge clk);
         // Simultaneous write requests to different addresses
        wb0_addr = 8'h10;
        wb0_data_i = 32'hAAAA5555;
        wb0_sel = 4'b1111;
        wb0_we = 1;
        wb0_stb = 1;
        wb1_addr = 8'h20;
        wb1_data_i = 32'h5555AAAA;
        wb1_sel = 4'b1111;
        wb1_we = 1;
        wb1_stb = 1;
        //wait for two acks
        begin
            while (!wb0_ack) @(posedge clk);
            wb0_stb = 0;
            wb0_we = 0;
        end
        begin
            while (!wb1_ack) @(posedge clk);
            wb1_stb = 0;
            wb1_we = 0;
        end
        @(posedge clk);
        // Read Port 0
        wb0_addr = 8'h10;
        wb0_stb = 1;
        @(posedge clk);
        while (!wb0_ack) @(posedge clk);
        wb0_stb = 0;
        @(posedge clk);
        $display("READ BACK @10 (port 0): %h", wb0_data_o);
        if (wb0_data_o !== 32'hAAAA5555) $error("Test 3 failed: Port 0 read wrong data");
         // Read Port 1
        wb1_addr = 8'h20;
        wb1_stb = 1;
        @(posedge clk);
        while (!wb1_ack) @(posedge clk);
        wb1_stb = 0;
        @(posedge clk);
        $display("READ BACK @20 (port 1): %h", wb1_data_o);
        if (wb1_data_o !== 32'h5555AAAA) $error("Test 3 failed: Port 1 read wrong data");
        //TEST 4: READ CONTENTION
        // Port 0 writes to address 0x00
        wb0_addr = 8'h00;
        wb0_data_i = 32'h11112222;
        wb0_sel = 4'b1111;
        wb0_we = 1;
        wb0_stb = 1;
        @(posedge clk);
        while (!wb0_ack) @(posedge clk);
        wb0_stb = 0;
        wb0_we = 0;
        @(posedge clk);

        // Port 0 writes to address 0x01
        wb0_addr = 8'h01;
        wb0_data_i = 32'h33334444;
        wb0_sel = 4'b1111;
        wb0_we = 1;
        wb0_stb = 1;
        @(posedge clk);
        while (!wb0_ack) @(posedge clk);
        wb0_stb = 0;
        wb0_we = 0;
        @(posedge clk);
        //begin simultaneous reads
        wb0_stb = 1; // Always on
        wb1_stb = 1; 
        wb0_we = 0;
        wb1_we = 0;
        cycle_count = 0;
        repeat (8) begin
            // Change address every 2 cycles for each port if not stalled
            if (cycle_count % 2 == 0) begin
                
                wb0_addr = (cycle_count % 4 == 0) ? 8'h00 : 8'h01;
                
            end
            if (cycle_count % 2 == 1) begin
                
                wb1_addr = (cycle_count % 4 == 1) ? 8'h01 : 8'h00;
                
            end
            cycle_count++;
            @(posedge clk);
        end
        wb0_stb = 0;
        wb1_stb = 0;
        @(posedge clk);


        $finish;
    end
endmodule