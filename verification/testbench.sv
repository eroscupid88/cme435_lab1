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
    logic [7:0] previous_data; 
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
        $display("**********Start testing load data. Mode: s_in = 2'b11********");
        foreach (data[i])
            #400            // load data every 2 clk cycle
            begin
                load_task(data[i]);    // 1 clk cycle
                @(data_output_from_counter)
                begin
                    if ((s_in ==2'b11)&&(data_output_from_counter != data[i]))                   
                        $display("Error in Load mode Clk_in:%b,s_in:%d,input data from DUT:%d,output data to DUT:%d",clk_in,s_in,data_output_from_counter,for_up_down_counter);
                end
            end
    endtask

/*
    Test increment mode to check data coming from DUT to test bench is increase by 1
*/
    task test_increment_mode();
        $display("**********Start testing increment mode. Mode: s_in = 2'b01********");
        previous_data =data_output_from_counter;
        @(posedge clk_in)
        s_in = 2'b01;
        repeat (300) @(data_output_from_counter)
            begin
            // $monitor("Increment Mode:\t Clk_in:%b,s_in:%d,input data from DUT:%d,output data to DUT:%d",clk_in,s_in,data_output_from_counter,previous_data);
            if ((reset_in != 1) && (data_output_from_counter != previous_data+1) && (previous_data !=255))
                begin
                $display("Error in Increment Mode:\t Clk_in:%b,s_in:%d,input data from DUT:%d,output data to DUT:%d",clk_in,s_in,data_output_from_counter,previous_data);
                end
            previous_data = data_output_from_counter;   
            end
    endtask

/*
    Test increment mode to check data coming from DUT to test bench is equal to 0 if input to DUT is 255
*/
    task test_increment_mode_with_roll_over;
        $display("**********Start testing increment mode with roll over. Mode: s_in = 2'b01********");
        // load data input = 255
        load_task(255);
        $display("%d",for_up_down_counter);
        // wait for 1 cycle
        @(posedge clk_in)
        s_in = 2'b01;
        // wait for 1 clk cycle 
        #200
        @(data_output_from_counter)
            if ((reset_in != 1) && (data_output_from_counter !=0))
                begin
                $display("Error in Increment Mode with roll over:\t Clk_in:%b,s_in:%d,input data from DUT:%d,output data to DUT:%d",clk_in,s_in,data_output_from_counter,previous_data);
                end
          
    endtask


    /*
    Test decrement mode to check data coming from DUT to test bench is decrese by 1
*/
    task test_decrement_mode();
        $display("**********Start testing decrement mode. Mode: s_in = 2'b10********");
        previous_data =data_output_from_counter;
        @(posedge clk_in)
        s_in = 2'b10;
        repeat (300) @(data_output_from_counter)
            begin
            // $monitor("Increment Mode:\t Clk_in:%b,s_in:%d,input data from DUT:%d,output data to DUT:%d",clk_in,s_in,data_output_from_counter,previous_data);
            if ((reset_in != 1) && ( data_output_from_counter != previous_data-1) && (previous_data !=0))
                begin
                $display("Error in decrement Mode:\t Clk_in:%b,s_in:%d,input data from DUT:%d,output data to DUT:%d",clk_in,s_in,data_output_from_counter,previous_data);
                end
            previous_data = data_output_from_counter;   
            end
    endtask


/*
    Test decrement mode with roll under to check data coming from DUT to test bench is equal to 255 if input to DUT is 0
*/
    task test_decrement_mode_with_roll_under;
        $display("**********Start testing decrement mode with roll under. Mode: s_in = 2'b10********");
        // load data input = 0
        load_task(0);
        $display("%d",for_up_down_counter);
        // wait for 1 cycle
        @(posedge clk_in)
        s_in = 2'b10;
        // wait for 1 clk cycle 
        #200
        @(data_output_from_counter)
            if ((reset_in != 1) && (data_output_from_counter !=255))
                begin
                $display("Error in Decrement Mode with roll under:\t Clk_in:%b,s_in:%d,input data from DUT:%d,output data to DUT:%d",clk_in,s_in,data_output_from_counter,previous_data);
                end
          
    endtask



/*
    Test hold mode: change to increment mode, wait for data to change random number, change to hold mode then test if the data change after 1 cycle
*/
    task test_hold_mode();
        $display("**********Start testing hold mode . Mode: s_in = 2'b00********");
        // change to increment mode
        @(posedge clk_in)
            s_in = 2'b01;
        @(data_output_from_counter == 45) // pick data =45
            s_in = 2'b00;
            // check if next cycle whether data ouput from counter is changing or not 
        #100
        @(posedge clk_in)
            if (data_output_from_counter != 45)
                $display("Error in hold mode:\t Clk_in:%b,s_in:%d,input data from DUT:%d",clk_in,s_in,data_output_from_counter);   
        // change to decrement mode
        #100
        @(posedge clk_in)
            s_in = 2'b10;
        @(data_output_from_counter == 200) // data = 200
            s_in = 2'b00;
            // check if next cycle whether data ouput from counter is changing or not 
        #100
        @(posedge clk_in)
            if (data_output_from_counter != 200)
                $display("Error in hold mode:\t Clk_in:%b,s_in:%d,input data from DUT:%d",clk_in,s_in,data_output_from_counter);

    endtask

    /*
        sanity check task to display output of the DUT to make sure I/O connect properly
    */
    task sanity_check();
        $display("**********Start Sanity check task******");
        @(posedge clk_in)
            load_task(45);
        // s_in = 2'b11;
        // for_up_down_counter = 45;
        #200
        @(posedge clk_in)
            $display("At:%d,clk_in:%d,s_in:%d,input data:%d, output:%d",$time,clk_in,s_in,for_up_down_counter,data_output_from_counter);
        $display("**********FINISH SANITY CHECK TEST**********");
    endtask;


    initial
    begin
        $display("**********Beginning test!**********");
        sanity_check();
        test_load_data(datas);
        test_increment_mode();
        test_increment_mode_with_roll_over();
        test_hold_mode();
        test_decrement_mode();
        test_decrement_mode_with_roll_under();
        $display("%s",time_out_message);
    end
    // initial begin
        
    // end

    // initial begin
        
    // end



    
endmodule