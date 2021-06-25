module fifo_tb;

//reg and wire definition of fifo
    //for write task
    reg iWRST;
    wire oFULL;
    reg[7:0] iWDAT;
    reg iWINC;
    reg iWCLK;
//for read Task
    reg iRRST;
    wire oEMPT;
    wire[7:0] oRDAT;
    reg iRINC;
    reg iRCLK;    

//inst for this module
fifo_top fifo_top_inst(
    .iWRST(iWRST), 
    .oFULL(oFULL),
    .iWDAT(iWDAT),
    .iWINC(iWINC),
    .iWCLK(iWCLK),

    .iRRST(iRRST),
    .oEMPT(oEMPT),
    .oRDAT(oRDAT),
    .iRINC(iRINC),
    .iRCLK(iRCLK)
);

/**********************************************
*    real signal & test begin
***********************************************/
//time generate
//case 1: write faster
always #10 iWCLK = ~iWCLK;
always #25 iRCLK = ~iRCLK;
//case 2: read faster
//always #25 iWCLK = ~iWCLK;
//always #10 iRCLK = ~iRCLK;

//clk & rst
initial begin
    iWCLK = 0;
    iRCLK = 0;
    iWRST = 1;
    iRRST = 1;
    #100
    iWRST = 0;
    iRRST = 0;
end

//test write
initial begin
    iWINC = 0;
    iWDAT = 0;
    #200
        write_data();
end

//test read
/*initial begin
    iRINC = 0;
    #200
    @(posedge oFULL)
        read_data();
end*/
assign iRINC = ~oEMPT;

//task definition
task write_data();
    integer i;
    begin
        for (i = 0;i < 16;i = i+1) begin
            @(posedge iWCLK)
                iWINC = 1;
                iWDAT = i;
        end
        @(posedge iWCLK)
            iWINC = 0;
            iWDAT = 0;
    end
endtask

/*task read_data();
    integer i;
    begin
        begin
            for (i = 0;i < 16;i = i + 1) begin
                @(posedge iRCLK)
                    iRINC = 1;    
            end
            @(posedge iRCLK)
                    iRINC = 0;
        end    
    end
endtask*/
endmodule
