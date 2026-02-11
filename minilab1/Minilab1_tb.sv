`timescale 1ns/1ps
module Minilab1_tb;

    localparam CLK_PERIOD = 20;  // 50 MHz clock
    localparam DATA_WIDTH = 8;
    localparam NUM_MACS = 8;

    reg         CLOCK_50;
    reg         CLOCK2_50, CLOCK3_50, CLOCK4_50;
    wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire [9:0]  LEDR;
    reg  [3:0]  KEY;
    reg  [9:0]  SW;
    

    integer test_pass_count;
    integer test_fail_count;
    integer cycle_count;

    
    reg [23:0] expected_results [0:7];
    
    Minilab1 dut (
        .CLOCK_50(CLOCK_50),
        .CLOCK2_50(CLOCK2_50),
        .CLOCK3_50(CLOCK3_50),
        .CLOCK4_50(CLOCK4_50),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5),
        .LEDR(LEDR),
        .KEY(KEY),
        .SW(SW)
    );

    initial begin
        CLOCK_50 = 0;
        CLOCK2_50 = 0;
        CLOCK3_50 = 0;
        CLOCK4_50 = 0;
        forever #(CLK_PERIOD/2) begin
            CLOCK_50 = ~CLOCK_50;
            CLOCK2_50 = ~CLOCK2_50;
            CLOCK3_50 = ~CLOCK3_50;
            CLOCK4_50 = ~CLOCK4_50;
        end
    end
    

    always @(posedge CLOCK_50) begin
        cycle_count <= cycle_count + 1;
    end
    

    task calculate_expected_results;
        integer i, j;
        reg [7:0] A [0:7][0:7];
        reg [7:0] B [0:7];
        reg [31:0] temp_sum;
        begin
            // Initialize A matrix from MIF data
            // Row 0: 01 02 03 04 05 06 07 08
            A[0][0] = 8'h01; A[0][1] = 8'h02; A[0][2] = 8'h03; A[0][3] = 8'h04;
            A[0][4] = 8'h05; A[0][5] = 8'h06; A[0][6] = 8'h07; A[0][7] = 8'h08;
            
            // Row 1: 11 12 13 14 15 16 17 18
            A[1][0] = 8'h11; A[1][1] = 8'h12; A[1][2] = 8'h13; A[1][3] = 8'h14;
            A[1][4] = 8'h15; A[1][5] = 8'h16; A[1][6] = 8'h17; A[1][7] = 8'h18;
            
            // Row 2: 21 22 23 24 25 26 27 28
            A[2][0] = 8'h21; A[2][1] = 8'h22; A[2][2] = 8'h23; A[2][3] = 8'h24;
            A[2][4] = 8'h25; A[2][5] = 8'h26; A[2][6] = 8'h27; A[2][7] = 8'h28;
            
            // Row 3: 31 32 33 34 35 36 37 38
            A[3][0] = 8'h31; A[3][1] = 8'h32; A[3][2] = 8'h33; A[3][3] = 8'h34;
            A[3][4] = 8'h35; A[3][5] = 8'h36; A[3][6] = 8'h37; A[3][7] = 8'h38;
            
            // Row 4: 41 42 43 44 45 46 47 48
            A[4][0] = 8'h41; A[4][1] = 8'h42; A[4][2] = 8'h43; A[4][3] = 8'h44;
            A[4][4] = 8'h45; A[4][5] = 8'h46; A[4][6] = 8'h47; A[4][7] = 8'h48;
            
            // Row 5: 51 52 53 54 55 56 57 58
            A[5][0] = 8'h51; A[5][1] = 8'h52; A[5][2] = 8'h53; A[5][3] = 8'h54;
            A[5][4] = 8'h55; A[5][5] = 8'h56; A[5][6] = 8'h57; A[5][7] = 8'h58;
            
            // Row 6: 61 62 63 64 65 66 67 68
            A[6][0] = 8'h61; A[6][1] = 8'h62; A[6][2] = 8'h63; A[6][3] = 8'h64;
            A[6][4] = 8'h65; A[6][5] = 8'h66; A[6][6] = 8'h67; A[6][7] = 8'h68;
            
            // Row 7: 71 72 73 74 75 76 77 78
            A[7][0] = 8'h71; A[7][1] = 8'h72; A[7][2] = 8'h73; A[7][3] = 8'h74;
            A[7][4] = 8'h75; A[7][5] = 8'h76; A[7][6] = 8'h77; A[7][7] = 8'h78;
            
            // B vector: 81 82 83 84 85 86 87 88
            B[0] = 8'h81; B[1] = 8'h82; B[2] = 8'h83; B[3] = 8'h84;
            B[4] = 8'h85; B[5] = 8'h86; B[6] = 8'h87; B[7] = 8'h88;
            
            // Calculate C = A * B
            for (i = 0; i < 8; i = i + 1) begin
                temp_sum = 0;
                for (j = 0; j < 8; j = j + 1) begin
                    temp_sum = temp_sum + (A[i][j] * B[j]);
                end
                expected_results[i] = temp_sum[23:0];
                $display("[CALC] Expected C[%0d] = %h (decimal: %0d)", i, expected_results[i], expected_results[i]);
            end
        end
    endtask
    

    task print_status;
        begin
            $display("================================================================================");
            $display("[CYCLE %0d] Time: %0t", cycle_count, $time);
            $display("--------------------------------------------------------------------------------");
            $display("  TOP-LEVEL STATE: %0d (%s)", dut.state,
                     dut.state == 0 ? "IDLE" :
                     dut.state == 1 ? "FETCH" :
                     dut.state == 2 ? "COMPUTE" :
                     dut.state == 3 ? "DONE" : "UNKNOWN");
            $display("  MEM_CTRL STATE:  %0d (%s)", dut.mem_ctrl_state,
                     dut.mem_ctrl_state == 0 ? "IDLE" :
                     dut.mem_ctrl_state == 1 ? "FETCH_A" :
                     dut.mem_ctrl_state == 2 ? "WAIT_A" :
                     dut.mem_ctrl_state == 3 ? "WRITE_A" :
                     dut.mem_ctrl_state == 4 ? "FETCH_B" :
                     dut.mem_ctrl_state == 5 ? "WAIT_B" :
                     dut.mem_ctrl_state == 6 ? "WRITE_B" :
                     dut.mem_ctrl_state == 7 ? "DONE" : "UNKNOWN");
            $display("--------------------------------------------------------------------------------");
            $display("  AVALON MM INTERFACE:");
            $display("    Address:        0x%08h", dut.avm_address);
            $display("    Read:           %b", dut.avm_read);
            $display("    ReadData:       0x%016h", dut.avm_readdata);
            $display("    ReadDataValid:  %b", dut.avm_readdatavalid);
            $display("    WaitRequest:    %b", dut.avm_waitrequest);
            $display("--------------------------------------------------------------------------------");
            $display("  FIFO STATUS:");
            $display("    A FIFOs Full:   %08b", dut.fifo_a_full);
            $display("    B FIFO Full:    %b", dut.fifo_b_full);
            $display("    All FIFOs Full: %b", dut.all_fifos_full);
            $display("--------------------------------------------------------------------------------");
            $display("  CONTROL SIGNALS:");
            $display("    mem_ctrl_start: %b", dut.mem_ctrl_start);
            $display("    mem_ctrl_done:  %b", dut.mem_ctrl_done);
            $display("    start_compute:  %b", dut.start_compute);
            $display("    compute_done:   %b", dut.compute_done);
            $display("--------------------------------------------------------------------------------");
            $display("  LED OUTPUTS: %010b", LEDR);
            $display("================================================================================");
        end
    endtask
    

    task print_mac_outputs;
        integer i;
        begin
            $display("\n========== MAC OUTPUT RESULTS ==========");
            for (i = 0; i < NUM_MACS; i = i + 1) begin
                $display("  MAC[%0d] Output (C[%0d]): 0x%06h (decimal: %0d)", 
                         i, i, dut.mac_out[i], dut.mac_out[i]);
            end
            $display("==========================================\n");
        end
    endtask
    

    task verify_results;
        integer i;
        reg all_pass;
        begin
            all_pass = 1;
            $display("\n========== VERIFICATION RESULTS ==========");
            for (i = 0; i < NUM_MACS; i = i + 1) begin
                if (dut.mac_out[i] == expected_results[i]) begin
                    $display("  [PASS] MAC[%0d]: Got 0x%06h, Expected 0x%06h", 
                             i, dut.mac_out[i], expected_results[i]);
                    test_pass_count = test_pass_count + 1;
                end else begin
                    $display("  [FAIL] MAC[%0d]: Got 0x%06h, Expected 0x%06h", 
                             i, dut.mac_out[i], expected_results[i]);
                    test_fail_count = test_fail_count + 1;
                    all_pass = 0;
                end
            end
            $display("============================================");
            
            if (all_pass) begin
                $display("\n*** ALL TESTS PASSED! ***\n");
            end else begin
                $display("\n*** SOME TESTS FAILED! ***");
                $display("*** Check memory layout and FIFO ordering ***\n");
            end
        end
    endtask
    

    initial begin
        // Initialize
        test_pass_count = 0;
        test_fail_count = 0;
        cycle_count = 0;
        KEY = 4'b1111;  // All buttons released (active low)
        SW = 10'b0;
        
        $display("\n");
        $display("==============================================================");
        $display("  ECE 554 Minilab 1 - Matrix-Vector Multiplication Testbench");
        $display("==============================================================");
        $display("  Clock Period: %0d ns (50 MHz)", CLK_PERIOD);
        $display("  Data Width:   %0d bits", DATA_WIDTH);
        $display("  Number MACs:  %0d", NUM_MACS);
        $display("==============================================================\n");
        
        // Calculate expected results
        calculate_expected_results();
        
        // Apply reset
        $display("\n[TEST] Applying reset...");
        KEY[0] = 0;  // Assert reset (active low)
        repeat(5) @(posedge CLOCK_50);
        KEY[0] = 1;  // Deassert reset
        repeat(2) @(posedge CLOCK_50);
        
        $display("[TEST] Reset complete. System in IDLE state.");
        print_status();
        
        // Start operation by pressing KEY[1]
        $display("\n[TEST] Starting operation (pressing KEY[1])...");
        KEY[1] = 0;  // Press button
        @(posedge CLOCK_50);
        KEY[1] = 1;  // Release button
        
        // Wait for FETCH state
        $display("[TEST] Waiting for FETCH state...");
        wait(dut.state == 1);
        print_status();
        
        // Monitor memory fetch operation
        $display("\n[TEST] Monitoring memory fetch operation...");
        while (dut.state == 1) begin
            if (dut.avm_readdatavalid) begin
                $display("[FETCH] Address: %0d, Data: 0x%016h", 
                         dut.avm_address, dut.avm_readdata);
            end
            @(posedge CLOCK_50);
        end
        
        // Wait for COMPUTE state
        $display("\n[TEST] Waiting for COMPUTE state...");
        wait(dut.state == 2);
        print_status();
        
        // Wait for computation to complete
        $display("[TEST] Computing matrix-vector product...");
        while (dut.state == 2) begin
            @(posedge CLOCK_50);
        end
        
        // Wait for DONE state
        $display("\n[TEST] Waiting for DONE state...");
        wait(dut.state == 3);
        
        // Allow pipeline to flush
        repeat(20) @(posedge CLOCK_50);
        
        print_status();
        print_mac_outputs();
        
        // Verify results
        verify_results();
        
        // Test display functionality
        $display("\n[TEST] Testing 7-segment display functionality...");
        SW[9] = 1;  // Enable display
        
        for (int i = 0; i < 8; i++) begin
            SW[2:0] = i;
            repeat(2) @(posedge CLOCK_50);
            $display("  SW[2:0] = %0d: Displaying MAC[%0d] = 0x%06h", i, i, dut.mac_out[i]);
            $display("    HEX5-HEX0: %07b %07b %07b %07b %07b %07b", 
                     HEX5, HEX4, HEX3, HEX2, HEX1, HEX0);
        end
        
        // Print final summary
        $display("\n==============================================================");
        $display("  TEST SUMMARY");
        $display("==============================================================");
        $display("  Total Cycles:  %0d", cycle_count);
        $display("  Tests Passed:  %0d", test_pass_count);
        $display("  Tests Failed:  %0d", test_fail_count);
        $display("==============================================================\n");
        
        if (test_fail_count == 0) begin
            $display("*** SIMULATION PASSED ***\n");
        end else begin
            $display("*** SIMULATION FAILED ***\n");
        end
        
        $finish;
    end
    

    initial begin
        #100000000;  // 100ms timeout
        $display("\n[ERROR] Simulation timeout! Test did not complete in time.");
        $display("[ERROR] Current state: %0d", dut.state);
        print_status();
        $finish;
    end
endmodule
