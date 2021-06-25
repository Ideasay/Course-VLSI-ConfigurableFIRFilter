module jtag_top(
    //typical jtag port begin
    iTms,
    iTck,
    iTdi,
    iTrst,
    oTdo,
    oTdoEnable,
    //typical jtag port end

    //for CONFIG CHAIN
    oWrEn,
    iDesync
);
/********************************************
*Parameter definition begin
*
********************************************/
parameter stateLen = 4;
parameter pTestLogicReset = 4'hF;
parameter pRunTestIdle = 4'hC;
parameter pSelectDRScan = 4'h7;
parameter pCaptureDR = 4'h6;
parameter pShiftDR = 4'h2;
parameter pExit1DR = 4'h1;
parameter pPauseDR = 4'h3;
parameter pExit2DR = 4'h0;
parameter pUpdateDR = 4'h5;
parameter pSelectIRScan = 4'h4;
parameter pCaptureIR = 4'hE;
parameter pShiftIR = 4'hA;
parameter pExit1IR = 4'h9;
parameter pPauseIR = 4'hB;
parameter pExit2IR = 4'h8;
parameter pUpdateIR = 4'hD;

parameter instrLen = 4;
parameter BYPASS = 4'b0001;
parameter IDCODE = 4'b0010;
parameter CONFIG = 4'b0100;

parameter IDCODEVALUE = 32'h149511c3;

parameter SYNCWORD = 8'b11110000;
/********************************************
*IO definition begin
*
********************************************/
input iTms;
input iTck;
input iTdi;
input iTrst;
output oTdo;
output oTdoEnable;

output oWrEn;
input iDesync;
/********************************************
*Register/wire definition begin
*
********************************************/
//state reg
reg[stateLen - 1:0] currentState;

//command reg
reg idcodeSelect;
reg bypassSelect;
reg configSelect;
//output reg
reg oTdo;
reg oTdoEnable;
reg oWrEn;
//reset better
wire tmsReset;
reg tmsQ1;
reg tmsQ2;
reg tmsQ3;
reg tmsQ4;

//for Instruction Chain
reg[instrLen - 1:0] SIR;
reg[instrLen - 1:0] IR;

//for Bypass Chain
reg bypassReg;

//for IDCODE Chain
reg[31:0] IDC;

//for CONFIG Chain
reg[7:0] SCF;
reg sync;
reg[3:0] sftCnt;
/********************************************
*tms reset logic
*tms 1 1 1 1 1->reset to pTestLogicReset
********************************************/
always @(posedge iTck) begin
    tmsQ1 <= iTms;
    tmsQ2 <= tmsQ1;
    tmsQ3 <= tmsQ2;
    tmsQ4 <= tmsQ3;
end

assign tmsReset = iTms & tmsQ1 & tmsQ2 & tmsQ3 & tmsQ4;

/********************************************
*Jtag State Machine
*
********************************************/
always @(posedge iTck or negedge iTrst) begin
    if (iTrst == 0) begin
        currentState <= pTestLogicReset;
    end
    /*else if(tmsReset == 1)begin
	    currentState <= pTestLogicReset;
    end*/
    else begin
        case (currentState)
            pTestLogicReset:
                if(iTms)
                    currentState <= pTestLogicReset;
                else
                    currentState <= pRunTestIdle;
            pRunTestIdle:
                if(iTms)
                    currentState <= pSelectDRScan;
                else
                    currentState <= pRunTestIdle;
            pSelectDRScan:
                if(iTms)
                    currentState <= pSelectIRScan;
                else
                    currentState <= pCaptureDR;
            pCaptureDR:
                if(iTms)
                    currentState <= pExit1DR;
                else
                    currentState <= pShiftDR;
            pShiftDR:
                if(iTms)
                    currentState <= pExit1DR;
                else
                    currentState <= pShiftDR;
            pExit1DR:
                if(iTms)
                    currentState <= pUpdateDR;
                else
                    currentState <= pPauseDR;
            pPauseDR:
                if(iTms)
                    currentState <= pExit2DR;
                else
                    currentState <= pPauseDR;
            pExit2DR:
                if(iTms)
                    currentState <= pUpdateDR;
                else
                    currentState <= pShiftDR;
            pUpdateDR:
                if(iTms)
                    currentState <= pSelectDRScan;
                else
                    currentState <= pRunTestIdle;
            pSelectIRScan:
                if(iTms)
                    currentState <= pTestLogicReset;
                else
                    currentState <= pCaptureIR;
            pCaptureIR:
                if(iTms)
                    currentState <= pExit1IR;
                else
                    currentState <= pShiftIR;
            pShiftIR:
                if(iTms)
                    currentState <= pExit1IR;
                else
                    currentState <= pShiftIR;
            pExit1IR:
                if(iTms)
                    currentState <= pUpdateIR;
                else
                    currentState <= pPauseIR;
            pPauseIR:
                if(iTms)
                    currentState <= pExit2IR;
                else
                    currentState <= pPauseIR;
            pExit2IR:
                if(iTms)
                    currentState <= pUpdateIR;
                else
                    currentState <= pShiftIR;
            pUpdateIR:
                if(iTms)
                    currentState <= pSelectDRScan;
                else
                    currentState <= pRunTestIdle;
        endcase
    end
end
/********************************************
*IR Chain Instruction
*
********************************************/
//shift SIR
always @(posedge iTck) begin
    if(currentState == pTestLogicReset)
        SIR <= BYPASS;
    else if(currentState == pShiftIR)
        SIR <= {iTdi,SIR[instrLen - 1:1]};
end
//update IR when state updateIR
always @(negedge iTck) begin
    if(currentState == pTestLogicReset)
        IR <= BYPASS;
    else if(currentState == pUpdateIR)
        IR <= SIR;
end
/********************************************
*Bypass Chain 
*
********************************************/
always @(posedge iTck) begin
    if(currentState == pCaptureDR && IR == BYPASS)
        bypassReg <= 1'b0;
    else if(currentState == pShiftDR && IR == BYPASS)
        bypassReg <= iTdi;
end
/********************************************
*IDCODE Chain 
*
********************************************/
always @(posedge iTck) begin
    if(currentState == pCaptureDR && IR == IDCODE)
        IDC <= IDCODEVALUE;
    else if(currentState == pShiftDR && IR ==IDCODE)
        IDC <= {iTdi,IDC[31:1]};
end
/********************************************
*CONFIG Chain 
*
********************************************/
//shift config reg
always @(posedge iTck) begin
    if(currentState == pTestLogicReset)
        SCF <= 8'b0;
    else if(currentState == pShiftDR && IR == CONFIG)
        SCF <= {iTdi,SCF[7:1]};
end
//sync logic
always @(posedge iTck) begin
    if(currentState == pTestLogicReset)
        sync <= 1'b0;
    else if(SCF == SYNCWORD)
        sync <= 1'b1;
    else if(iDesync == 1'b1)
        sync <= 1'b0;
end
//scf count logic
always @(posedge iTck) begin
    if(currentState == pTestLogicReset)
        sftCnt <= 0;
    else if(~sync)
        sftCnt <= 0;
    else if (currentState == pShiftDR && IR == CONFIG && sync) begin
            sftCnt <= sftCnt + 1;
    end
end
//write enable logic
always @(*) begin
    if(currentState == pShiftDR && IR == CONFIG && sync && sftCnt == 15)
        oWrEn = 1'b1;
    else
        oWrEn = 1'b0;
end
/********************************************
*OUTPUT Multiplex Chain 
*
********************************************/
always @(negedge iTck) begin
    if(currentState == pShiftIR)
        oTdo <= SIR[0];
    else if(currentState == pShiftDR)
        case (IR)
            BYPASS:oTdo <= bypassReg;
            IDCODE:oTdo <= IDC[0];
            CONFIG:oTdo <= SCF[0];
            //for config chain
        endcase
end

always @(negedge iTck) begin
    if(currentState == pShiftIR)
        oTdoEnable <= 1'b0;
    else if(currentState == pShiftDR)
        oTdoEnable <= 1'b0;
    else
        oTdoEnable <= 1'b1;
    //better
    //oTdoEnable <= (currentState == pShiftIR) || (currentState == pShiftDR);
end

//select signal
always @(IR) begin
    idcodeSelect = 1'b0;
    bypassSelect = 1'b0;
    configSelect = 1'b0;

    case (IR)
        IDCODE:idcodeSelect = 1'b1;
        BYPASS:bypassSelect = 1'b1;
        CONFIG:configSelect = 1'b1;
        default:bypassSelect = 1'b1;
    endcase
    
end

endmodule
