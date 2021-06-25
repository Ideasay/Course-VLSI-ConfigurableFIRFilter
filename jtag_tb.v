module jtag_tb;
//reg definition 
    reg iTms;
    reg iTck;
    reg iTdi;
    reg iTrst;
    wire oTdo;

    //for CONFIG CHAIN
    wire oWrEn;
    reg iDesync;

//inst for this module
jtag_top jtag_top_inst(
    .iTms(iTms),
    .iTck(iTck),
    .iTdi(iTdi),
    .iTrst(iTrst),
    .oTdo(oTdo),
    .oTdoEnable(oTdoEnable),
    .oWrEn(oWrEn),
    .iDesync(iDesync)
);

/**********************************************
*    real signal & test begin
***********************************************/
//time generate
always #50 iTck = ~iTck; 

//clk & rst
initial begin
    iTck = 0;
    iTrst = 0;
    #200
    iTrst = 1;
end

initial begin
    iTms = 1;
    iTdi = 0;
    #200
        test_instr_chain(4'b0001);
        iTdi = 0;
        test_bypass(8'b00111100);
    #200
        iTdi = 0; 
        test_instr_chain(4'b0010);
        iTdi = 0;
        test_idcode();
    #200
        iTdi = 0;
        test_instr_chain(4'b0100);
        test_config_comb(8'd255);
        /*iTdi = 0;
        test_config_sync(8'b11110000);
        iTdi = 0;
        test_config(8'b10100100);//test once*/
    #200
        test_instr_chain(4'b0001);

end

//reg[3:0] instruction;//idcode
//reg[3:0] instruction = 4'b0001;//bypass
//reg[3:0] instruction = 4'b0100;//config
task test_instr_chain(input[3:0] ins);
    //instruction = ins;
    begin
        #100 iTms = 0;
        #100 iTms = 1;
        #200 iTms = 0;
        #500 iTms = 1;
        #100 iTms = 0;
        #400 iTms = 1;
        #100 iTms = 0;
        //input ir 1101 config
	    #100 iTdi = ins[0];
	    #100 iTdi = ins[1];
	    #100 iTdi = ins[2];
	    #100 iTdi = ins[3];
	    #0   iTms = 1;
        #200 iTms = 0;
    end
endtask

task test_bypass(input[7:0] data);
    begin
        #100 iTms = 1;
        #100 iTms = 0;
        #900 iTms = 1;
        #100 iTms = 0;
        #400 iTms = 1;
        #100 iTms = 0;
	    #100 iTdi = data[0];
	    #100 iTdi = data[1];
	    #100 iTdi = data[2];
	    #100 iTdi = data[3];
        #100 iTdi = data[4];
	    #100 iTdi = data[5];
	    #100 iTdi = data[6];
	    #100 iTdi = data[7];
	    #0   iTms = 1;
        #200 iTms = 0;
    end
endtask

task test_idcode();
    begin
        #100 iTms = 1;
        #100 iTms = 0;
        #3300 iTms = 1;
        #100 iTms = 0;
        #400 iTms = 1;
        #100 iTms = 0;
	    #3200 iTdi = 0;
	    #0   iTms = 1;
        #200 iTms = 0;
    end
endtask

task test_config_sync(input[7:0] syncword);
    begin
        #100 iTms = 1;
        #100 iTms = 0;
        #900 iTms = 1;
        #100 iTms = 0;
        #400 iTms = 1;
        #100 iTms = 0;
	    #100 iTdi = syncword[0];
	    #100 iTdi = syncword[1];
	    #100 iTdi = syncword[2];
	    #100 iTdi = syncword[3];
        #100 iTdi = syncword[4];
	    #100 iTdi = syncword[5];
	    #100 iTdi = syncword[6];
	    #100 iTdi = syncword[7];
	    #0   iTms = 1;
        #200 iTms = 0;
    end
endtask

task test_config(input[7:0] data);
    begin
        #100 iTms = 1;
        #100 iTms = 0;
        #200 iTdi = data[0];
	    #100 iTdi = data[1];
	    #100 iTdi = data[2];
	    #100 iTdi = data[3];
        #100 iTdi = data[4];
	    #100 iTdi = data[5];
	    #100 iTdi = data[6];
	    #100 iTdi = data[7];
         iTms = 1;
        #100 iTms = 0;
        #400 iTms = 1;
        #100 iTms = 0;
	    
        iTdi = 0;
	    #800   iTms = 1;
        #200 iTms = 0;
        //Desync operation
        iDesync = 1;
        #100 iDesync = 0;
    end
endtask

task test_config_comb(input[7:0] testcount);
    integer i;
    begin
        for (i = 1;i < testcount + 1;i = i + 1) begin
            iTdi = 0;
            test_config_sync(8'b11110000);
            iTdi = 0;
            test_config(i);//test once
        end
    end      
endtask
endmodule