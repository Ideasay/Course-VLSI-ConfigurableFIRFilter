module config_tb;

//reg and wire definition 
reg Empty;
reg iRCLK;
reg RSTn;
reg[7:0] Data;
wire[7:0] D7_D0;
wire RINC;
wire WrEn;
wire[2:0] RegAddr;  

//inst for this module
config_passer config_passer_inst(
    .CLK(iRCLK),
    .RSTn(RSTn),
    .Empty(Empty),
    .Data(Data),
    .D7_D0(D7_D0),
    .RINC(RINC),
    .WrEn(WrEn),
    .RegAddr(RegAddr)
);

/**********************************************
*    real signal & test begin
***********************************************/
always #10 iRCLK = ~iRCLK;

initial begin
    iRCLK = 0;
    RSTn = 0;
    Empty = 1;
    #100
    RSTn = 1;
    Empty = 0;
end

initial begin
#200
    transfer_data();
end

task transfer_data();
    integer i;
    begin
        for (i = 0;i < 256;i = i + 1) begin
            @(posedge iRCLK)
                Data = i;
        end
        @(posedge iRCLK)
            Empty = 1; 
    end
endtask

endmodule