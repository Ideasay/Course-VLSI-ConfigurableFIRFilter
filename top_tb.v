module top_tb;

//reg & wire definition for test
reg iTms;
reg iTck;
reg iTrst;
reg iDesync;
reg iTdi;

wire oRINC;
wire WrEn;
wire[2:0] regAddr;
wire[7:0] D7_D0;
wire[7:0] setDataReg_Latch;

//inst for this module
top top_inst(
    .iTms(iTms),
    .iTck(iTck),
    .iTrst(iTrst),
    .iDesync(iDesync),
    .iTdi(iTdi),

    .oRINC(oRINC),
    .WrEn(WrEn),
    .regAddr(regAddr),
    .D7_D0(D7_D0),
    .setDataReg_Latch(setDataReg_Latch)
);

/**********************************************
*    real signal & test begin
***********************************************/
//generate clk
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
        iTdi = 0;
        test_instr_chain(4'b0100);
        test_config_comb(8'd255);
        /*iTdi = 0;
        test_config_sync(8'b11110000);
        iTdi = 0;
        test_config(8'b10100100);//test once*/
end

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