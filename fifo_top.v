module fifo_top(
    //for write task
    iWRST,
    oFULL,
    iWDAT,
    iWINC,
    iWCLK,
    //for read Task
    iRRST,
    oEMPT,
    oRDAT,
    iRINC,
    iRCLK
);
/********************************************
*Parameter definition begin
*
********************************************/
parameter DATAWIDTH = 8;
/********************************************
*IO definition begin
*
********************************************/
//for write task
input iWRST;
output oFULL;
input[DATAWIDTH - 1:0] iWDAT;
input iWINC;
input iWCLK;
//for read Task
input iRRST;
output oEMPT;
output[DATAWIDTH - 1:0] oRDAT;
input iRINC;
input iRCLK;


/********************************************
*Register/wire definition begin
*
********************************************/
//for output
reg oFULL;
reg oEMPT;
reg[DATAWIDTH -1:0] oRDAT;
//for fifo storage
reg[DATAWIDTH - 1:0] fifoRegs[15:0];
reg C;
reg E;
reg[3:0] rAddr;//check already
reg[3:0] wAddr;//check already
//for sync read/write ptr
//read and write pointer buffer
reg[4:0] wrPtr;//checked
reg[4:0] wrPtr1;

reg[4:0] rwPtr;//checked
reg[4:0] rwPtr1;

reg[4:0] rPtr;//real read ptr checked grey
reg[4:0] wPtr;//real write ptr checked grey
//for wr 
reg[4:0] wbin;//checked binary
reg[4:0] wbnext;//checked binary
reg[4:0] wgnext;//checked grey

//FOR WR ADDR
reg wAddrMsb;

//for rd
reg[4:0] rbin;//binary
reg[4:0] rbnext;//binary
reg[4:0] rgnext;//grey

//for rd addr
reg rAddrMsb;


/********************************************
*fifo buffer
*
********************************************/
assign C = iWCLK;
assign E = (~oFULL) & iWINC;
assign oRDAT = fifoRegs[rAddr];
always @(posedge C) begin
    if(E)
        fifoRegs[wAddr] <= iWDAT; 
end

/************************************************************
*main logic write
*
************************************************************/
/********************************************
*sync read ptr for compare the pointer to indicate whether the fifo is full or empty
*
********************************************/
/*
always@(posedge wr_clk )
   begin
      rd_addr_gray_d1 <= rd_addr_gray;
      rd_addr_gray_d2 <= rd_addr_gray_d1;
   end
*/
always @(posedge iWCLK or posedge iWRST) begin
    if(iWRST)
        {wrPtr,wrPtr1} <= 0;
    else
        {wrPtr,wrPtr1} <= {wrPtr1,rPtr};
end
/********************************************
*write grey to binary
*
********************************************/
integer i;
always @(*) begin
    for(i = 0;i <= 4;i=i+1)
        wbin[i]=^(wPtr>>i);
end
// calc next index
always @(*) begin
    if(~oFULL)
        wbnext = wbin + iWINC;
    else
        wbnext = wbin;
end
//write bin to gray
always @(*) begin
    wgnext = (wbnext>>1)^wbnext;
end

/********************************************
*write addr
*
********************************************/
always @(posedge iWCLK or posedge iWRST) begin
    if(iWRST)
        wAddrMsb <= 0;
    else
        wAddrMsb <= wgnext[4]^wgnext[3];
end
assign wAddr = {wAddrMsb,wPtr[2:0]};
/********************************************
*full signal
*
********************************************/
always @(posedge iWCLK or posedge iWRST) begin
    if(iWRST)
        oFULL <= 0;
    else
        oFULL <= (wgnext == {~wrPtr[4:3],wrPtr[2:0]});
end
/********************************************
*write ptr
*
********************************************/
always @(posedge iWCLK or posedge iWRST) begin
    if(iWRST)
        wPtr <= 0;
    else
        wPtr <= wgnext;
end
/************************************************************
*main logic read
*
************************************************************/
/********************************************
*sync read ptr
*
********************************************/
always @(posedge iRCLK or posedge iRRST) begin
    if(iRRST)
        {rwPtr,rwPtr1} <= 0;
    else
        {rwPtr,rwPtr1} <= {rwPtr1,wPtr};
end
/********************************************
*read grey to binary
*
********************************************/
integer j;
always @(*) begin
    for(j = 0;j <= 4;j=j+1)
        rbin[j]=^(rPtr>>j);
end
// calc next index
always @(*) begin
    if(~oEMPT)
        rbnext = rbin + iRINC;
    else
        rbnext = rbin;
end
//read bin to gray
always @(*) begin
    rgnext = (rbnext>>1)^rbnext;
end

/********************************************
*read addr
*
********************************************/
always @(posedge iRCLK or posedge iRRST) begin
    if(iRRST)
        rAddrMsb <= 0;
    else
        rAddrMsb <= rgnext[4]^rgnext[3];
end
assign rAddr = {rAddrMsb,rPtr[2:0]};
/********************************************
*empty signal
*
********************************************/
always @(posedge iRCLK or posedge iRRST) begin
    if(iRRST)
        oEMPT <= 0;
    else
        oEMPT <= (rgnext == rwPtr);
end
/********************************************
*READ ptr
*
********************************************/
always @(posedge iRCLK or posedge iRRST) begin
    if(iRRST)
        rPtr <= 0;
    else
        rPtr <= rgnext;
end


















endmodule
