`timescale 1ns/1ps

module async_fifo_axi_tb;

parameter DEPTH = 8;
parameter WIDTH = 8;

reg wr_clk;
reg rd_clk;
reg rst;

// AXI Slave Interface
reg  [WIDTH-1:0] s_axis_tdata;
reg              s_axis_tvalid;
wire             s_axis_tready;

// AXI Master Interface
wire [WIDTH-1:0] m_axis_tdata;
wire             m_axis_tvalid;
reg              m_axis_tready;

// DUT
async_fifo_axi #(DEPTH, WIDTH) dut (
    .wr_clk(wr_clk),
    .rd_clk(rd_clk),
    .rst(rst),

    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),

    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready)
);

// Write Clock = 100 MHz
always #5 wr_clk = ~wr_clk;

// Read Clock = 62.5 MHz
always #8 rd_clk = ~rd_clk;

integer i;

initial begin

    wr_clk = 0;
    rd_clk = 0;
    rst = 1;

    s_axis_tdata  = 0;
    s_axis_tvalid = 0;

    m_axis_tready = 0;

    // Reset
    #30;
    rst = 0;

    // ------------------------------------------------
    // WRITE 5 VALUES
    // ------------------------------------------------

    for(i=1; i<=5; i=i+1)
    begin
        @(posedge wr_clk);

        s_axis_tdata  <= i;
        s_axis_tvalid <= 1;

        wait(s_axis_tready);

        @(posedge wr_clk);
    end

    @(posedge wr_clk);
    s_axis_tvalid <= 0;

    // ------------------------------------------------
    // READ 5 VALUES
    // ------------------------------------------------

    repeat(2) @(posedge rd_clk);

    m_axis_tready <= 1;

    repeat(5)
        @(posedge rd_clk);

    m_axis_tready <= 0;

    // ------------------------------------------------
    // FILL FIFO
    // ------------------------------------------------

    for(i=10; i<20; i=i+1)
    begin
        @(posedge wr_clk);

        if(s_axis_tready)
        begin
            s_axis_tdata  <= i;
            s_axis_tvalid <= 1;
        end
    end

    @(posedge wr_clk);
    s_axis_tvalid <= 0;

    // ------------------------------------------------
    // EMPTY FIFO
    // ------------------------------------------------

    repeat(3) @(posedge rd_clk);

    m_axis_tready <= 1;

    repeat(15)
        @(posedge rd_clk);

    m_axis_tready <= 0;

    // ------------------------------------------------
    // RANDOM TRAFFIC
    // ------------------------------------------------

    repeat(20)
    begin
        @(posedge wr_clk);

        s_axis_tvalid <= $random;
        s_axis_tdata  <= $random;
    end

    repeat(20)
    begin
        @(posedge rd_clk);

        m_axis_tready <= $random;
    end

    #100;

    $finish;

end

initial begin

    $monitor(
        "TIME=%0t | TVALID_IN=%b TREADY_IN=%b DATA_IN=%h | TVALID_OUT=%b TREADY_OUT=%b DATA_OUT=%h",
        $time,
        s_axis_tvalid,
        s_axis_tready,
        s_axis_tdata,
        m_axis_tvalid,
        m_axis_tready,
        m_axis_tdata
    );

end

endmodule