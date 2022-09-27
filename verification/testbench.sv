`timescale 1ns/1ns
module testbench(
                output logic [7:0] for_up_down_counter,
                output logic [1:0]s_in,
                input bit reset_in,
                input bit clk_in,
                input logic [7:0] data_output_from_counter
                );
    typedef enum {HOLD,INCREMENT,DECREMENT,LOAD} Mode;
    Mode mode;
    parameter int TIMEOUT = 1000000;
	const string time_out_message = "Time out!";
    bit [3:0][7:0] datas;
    logic [7:0] previous_data ; 
    logic [7:0]data_hold;
    always @(posedge clk_in)
        previous_data <= data_output_from_counter;
    initial
    begin
    datas = '{8'd200,8'd245,8'd0,8'd255};
    
    end
    initial begin
        s_in =2'b11;
        #TIMEOUT $finish;
    end
    /*
    Load task: initialize, load data from test bench into DUT
    */
    task load_task(logic [7:0] number);
            s_in = 2'b11;
            for_up_down_counter = number;
    endtask

/*
    test load data task using random data from list and test if data going to DUT is equal to data going to test bench
*/
    task test_load_data(input bit [3:0][7:0]data);
        $display("\t**********Start testing load data. Mode: s_in = 2'b11********");
        foreach (data[i])
        begin
            @(posedge clk_in);           // load data every clk cycle
            load_task(data[i]);            
            repeat(2)@(posedge clk_in);      // check if 2nd clk cycle the data coming in or not
            assert (s_in ==2'b11 && data_output_from_counter == data[i]) 
            else   $error("Error in Load mode Clk_in:%b,s_in:%d,input data from DUT:%d,output data to DUT:%d",clk_in,s_in,data_output_from_counter,data[i]);
        end

        $display("\t**********FINISH LOAD MODE TEST**********\n");
    endtask

/*
    Test increment mode to check data coming from DUT to test bench is increase by 1
*/
    task test_increment_mode();
        $display("\t**********Start testing increment mode. Mode: s_in = 2'b01********");
        previous_data =data_output_from_counter;
        s_in = 2'b01;
        @(posedge clk_in); // wait for 1 clk cycle
        repeat (300) @(posedge clk_in) 
            begin
            if ((previous_data !=255) && (reset_in != 1))
                assert (data_output_from_counter == previous_data+1)
                else $error("Error in Increment Mode:\t Clk_in:%b,s_in:%d,data from DUT:%d,data to DUT:%d",clk_in,s_in,data_output_from_counter,previous_data);
            end 
        $display("\t**********FINISH INCREMENT MODE TEST**********\n");
    endtask

/*
    Test increment mode to check data coming from DUT to test bench is equal to 0 if input to DUT is 255
*/
    task test_increment_mode_with_roll_over;
        $display("\t**********Start testing increment mode. Mode: s_in = 2'b01********");
        previous_data =data_output_from_counter;
        s_in = 2'b01;
        @(posedge clk_in); // wait for 1 clk cycle
        repeat (300) @(posedge clk_in) 
            begin
            if ((previous_data ==255) && (reset_in != 1))
                assert (data_output_from_counter == 0)
                else $error("Error in Increment Mode with roll over:\t Clk_in:%b,s_in:%d,data from DUT:%d,data to DUT:%d",clk_in,s_in,data_output_from_counter,previous_data);
            end 
        $display("\t**********FINISH INCREMENT MODE WITH ROLL OVER TEST**********\n");
          
    endtask


    /*
    Test decrement mode to check data coming from DUT to test bench is decrese by 1
*/
    task test_decrement_mode();
        $display("\t**********Start testing decrement mode. Mode: s_in = 2'b10********");
        previous_data =data_output_from_counter;
        @(posedge clk_in);
        
        s_in = 2'b10;
        @(posedge clk_in);
        repeat (300) @(posedge clk_in)
        begin
            if ((previous_data !=0) && (reset_in != 1))
                assert (data_output_from_counter == previous_data-1)
                else $error("Error in Decrement Mode :\t Clk_in:%b,s_in:%d,data from DUT:%d,data to DUT:%d",clk_in,s_in,data_output_from_counter,previous_data);
            end 
        $display("\t**********FINISH DECREMENT MODE  TEST**********\n");
    endtask


/*
    Test decrement mode with roll under to check data coming from DUT to test bench is equal to 255 if input to DUT is 0
*/
    task test_decrement_mode_with_roll_under;
        $display("\t**********Start testing decrement mode with roll under. Mode: s_in = 2'b10********");
        previous_data =data_output_from_counter;
        s_in = 2'b10;
        @(posedge clk_in); // wait for 1 clk cycle
        repeat (300) @(posedge clk_in) 
            begin
            if ((previous_data ==0) && (reset_in != 1))
                assert (data_output_from_counter == 255)
                else $error("Error in Decrement Mode with roll under:\t Clk_in:%b,s_in:%d,data from DUT:%d,data to DUT:%d",clk_in,s_in,data_output_from_counter,previous_data);
            end 
        $display("\t**********FINISH DECREMENT MODE WITH ROLL UNDER TEST**********\n");
    endtask



/*
    Test hold mode: change to increment mode, wait for data to change random number, change to hold mode then test if the data change after 1 cycle
*/
    task test_hold_mode();
        $display("\t**********Start testing hold mode . Mode: s_in = 2'b00********");
        // test hold in decrement mode
        load_task (80); // load random number
        s_in = 2'b10;
        repeat (7) @(posedge clk_in); // running decrement mode for 7 cycles
        s_in = 2'b00;   // change mode to hold
        
        @(posedge clk_in);
        data_hold = data_output_from_counter;
        // $display("data decrement mode before hold: %d",data_hold);
            // check if next cycle whether data ouput from counter is changing or not 
        repeat (50) @(posedge clk_in)
            assert (data_output_from_counter == data_hold) 
            else   $error("Error in hold mode:\t Clk_in:%b,s_in:%d,input data from DUT:%d",clk_in,s_in,data_output_from_counter);
           
        // test hold in increment mode
        @(posedge clk_in)
        s_in = 2'b01; // change to increment mode
        repeat (7) @(posedge clk_in); // running increment mode for 7 cycles
        s_in = 2'b00;   // change mode to hold
        // $display("data increment before hold: %d",data_hold);
        @(posedge clk_in);
        data_hold = data_output_from_counter;
            // check if next cycle whether data ouput from counter is changing or not 
        repeat (50) @(posedge clk_in)
            assert (data_output_from_counter == data_hold) 
            else   $error("Error in hold mode:\t Clk_in:%b,s_in:%d,input data from DUT:%d",clk_in,s_in,data_output_from_counter);
        
        $display("\t**********FINISH HOLD MODE TEST**********\n");
    endtask

    /*
        sanity check task to display output of the DUT to make sure I/O connect properly
    */
    task sanity_check();
        $display("\t**********Start Sanity check task******");
        load_task(33);
        repeat(2)@(posedge clk_in);
        $display("At:%d,clk_in:%d,s_in:%d,input data:%d, output:%d",$time,clk_in,s_in,for_up_down_counter,data_output_from_counter);
        $display("\t**********FINISH SANITY CHECK TEST**********\n");
    endtask;




    task reset_test;
        $display("\t**********Start reset test task******");
        load_task(30);

        repeat (30) @(posedge clk_in); // wait for 1 clk cycle then change reset
        $display ("%d",data_output_from_counter);
        $root.tbench_top.reset_in = 1'b1;
        
        repeat (10) @(posedge clk_in);
        $root.tbench_top.reset_in = 1'b0;
        $display("\t**********FINISH RESET TEST**********\n");
    endtask


    initial
    begin
        $display("\t**********Beginning test!**********\n");
        // start test after 2 clock cycles
        repeat(2)@(posedge clk_in);
        reset_test();
        sanity_check();
        test_load_data(datas);
        test_hold_mode();
        test_increment_mode();
        test_increment_mode_with_roll_over();
        test_decrement_mode();
        test_decrement_mode_with_roll_under();
        test_hold_mode();
        $display("%s",time_out_message);
    end

    initial begin
        
    end   
endmodule