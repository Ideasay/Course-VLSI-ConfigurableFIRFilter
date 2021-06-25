module top(
    iTms,
    iTck,
    iTrst,
    iDesync,
    iTdi,

    oRINC,
    WrEn,
    regAddr,
    D7_D0,
    setDataReg_Latch
);
/********************************************
*Parameter definition begin
*
********************************************/
/********************************************
*IO definition begin
*
********************************************/
input iTms;
input iTck;
input iTrst;
input iDesync;
input iTdi;

output oRINC;
output WrEn;
output[2:0] regAddr;
output[7:0] D7_D0;
output[7:0] setDataReg_Latch;
/********************************************
*Register/wire definition begin
*
********************************************/
wire iTms;
wire iTck;
wire iTdi;
wire iTrst;
wire oTdo;
wire oTdoEnable;
wire oWrEn;
wire iDesync;

wire oFULL;
reg[7:0] setDataReg;
reg[7:0] setDataReg_Latch;
wire oEMPT;
wire[7:0] oRDAT;
wire iWINC;
wire iRINC;


wire[7:0] D7_D0;
wire WrEn;//for config_passer
wire[2:0] regAddr;
wire oRINC;
/********************************************
*sub module inst
*
********************************************/
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

fifo_top fifo_top_inst(
    .iWRST(~iTrst), 
    .oFULL(oFULL),
    .iWDAT(setDataReg_Latch),
    .iWINC(1),
    .iWCLK(iTck),

    .iRRST(~iTrst),
    .oEMPT(oEMPT),
    .oRDAT(oRDAT),
    .iRINC(iRINC),
    .iRCLK(iTck)
);

config_passer config_passer_inst(
    .CLK(iTck),
    .RSTn(iTrst),
    .Empty(oEMPT),
    .Data(oRDAT),
    .D7_D0(D7_D0),
    .RINC(oRINC),
    .WrEn(WrEn),
    .RegAddr(RegAddr)
);
/********************************************
*transfer oTdo to setDataReg
*
********************************************/
always @(posedge iTck) begin
    if(~oTdoEnable) begin
        setDataReg <= {oTdo,setDataReg[7:1]};
    end  
end

always @(negedge oWrEn)begin
    setDataReg_Latch <= setDataReg;
end
assign iRINC = ~oEMPT;

endmodule