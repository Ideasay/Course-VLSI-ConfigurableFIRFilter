module config_passer (
    CLK,
    RSTn,
    Empty,
    Data,
    D7_D0,
    RINC,
    WrEn,
    RegAddr
);
/***************************************************************
*1.addr code empty
*7 6   5 4 3   2 1 0
*0 0|reg addr|op cnt|
*2.addr code write 
*7 6   5 4 3   2 1 0
*1 0|reg addr|op cnt|
****************************************************************/ 
/********************************************
*Parameter definition begin
*
********************************************/
parameter AnalyzeInstruction = 1'b0;
parameter ReceiveData = 1'b1;
/********************************************
*IO definition begin
*
********************************************/
input Empty;
input CLK;
input RSTn;
input[7:0] Data;
output[7:0] D7_D0;
output RINC;
output WrEn;
output[2:0] RegAddr;

/********************************************
*Register/wire definition begin
*
********************************************/ 
reg state;
reg NextState; 

reg[7:0] D7_D0;
reg WrReg;
reg[2:0] Count;
reg[2:0] RegAddr;
reg RINC;
reg WrEn;

/********************************************
*state machine design
*
********************************************/
always @(posedge CLK or negedge RSTn) begin
    if(~RSTn)
        state <= AnalyzeInstruction;
    else
        state <= NextState;
end

always @(*) begin
    case(state)
        AnalyzeInstruction:
            if((~Empty) && (Data[2:0] != 0))
                NextState = ReceiveData;
            else
                NextState = AnalyzeInstruction;
        default:
            if((~Empty) && (Count == 1))
                NextState = AnalyzeInstruction;
            else
                NextState = ReceiveData;
    endcase
end
/********************************************
*addr reg
*
********************************************/
always @(posedge CLK or negedge RSTn) begin
    if(~RSTn)
        RegAddr <= 3'b0;
    else if((~Empty) && (state == AnalyzeInstruction))
        RegAddr <= Data[5:3];
end
/********************************************
*write reg
*
********************************************/
always @(posedge CLK or negedge RSTn) begin
    if(~RSTn)
        WrReg <= 1'b0;
    else if((~Empty) && (state == AnalyzeInstruction))
        WrReg <= Data[7];
end
/********************************************
*count reg
*
********************************************/
always @(posedge CLK or negedge RSTn) begin
    if(~RSTn)
        Count <= 3'b0;
    else if(state == AnalyzeInstruction && (~Empty)) begin
        Count <= Data[2:0];
    end
    else if(state == ReceiveData && (~Empty)) begin
        Count <= Count -1;
    end
end
/********************************************
*output sig
*
********************************************/
always @(*) begin
    D7_D0 = Data;
    RINC = ~Empty;
    WrEn = (~Empty) & WrReg & state;
end

endmodule
