module async_fifo_axi #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
)(
    input  wire                 wr_clk,
    input  wire                 rd_clk,
    input  wire                 rst,

    // AXI-Stream Slave Interface (Input Side)
    input  wire [WIDTH-1:0]     s_axis_tdata,
    input  wire                 s_axis_tvalid,
    output wire                 s_axis_tready,

    // AXI-Stream Master Interface (Output Side)
    output reg  [WIDTH-1:0]     m_axis_tdata,
    output wire                 m_axis_tvalid,
    input  wire                 m_axis_tready
);

localparam PTR_WIDTH = $clog2(DEPTH);

reg [WIDTH-1:0] mem [0:DEPTH-1];

// Binary pointers
reg [PTR_WIDTH:0] wr_ptr_bin;
reg [PTR_WIDTH:0] rd_ptr_bin;

// Gray pointers
reg [PTR_WIDTH:0] wr_ptr_gray;
reg [PTR_WIDTH:0] rd_ptr_gray;

// Synchronizer registers
reg [PTR_WIDTH:0] rd_ptr_gray_sync1;
reg [PTR_WIDTH:0] rd_ptr_gray_sync2;

reg [PTR_WIDTH:0] wr_ptr_gray_sync1;
reg [PTR_WIDTH:0] wr_ptr_gray_sync2;

wire full;
wire empty;

// Internal enables generated from AXI handshake
wire wr_en;
wire rd_en;

// --------------------------------------------------
// AXI Handshake Logic
// --------------------------------------------------

assign s_axis_tready = !full;

assign wr_en =
       s_axis_tvalid &&
       s_axis_tready;

assign m_axis_tvalid = !empty;

assign rd_en =
       m_axis_tvalid &&
       m_axis_tready;

// --------------------------------------------------
// Binary to Gray Conversion
// --------------------------------------------------

function [PTR_WIDTH:0] bin2gray;
    input [PTR_WIDTH:0] bin;
    begin
        bin2gray = (bin >> 1) ^ bin;
    end
endfunction

// --------------------------------------------------
// WRITE DOMAIN
// --------------------------------------------------

always @(posedge wr_clk or posedge rst)
begin
    if (rst)
    begin
        wr_ptr_bin  <= 0;
        wr_ptr_gray <= 0;
    end
    else if (wr_en && !full)
    begin
        mem[wr_ptr_bin[PTR_WIDTH-1:0]]
            <= s_axis_tdata;

        wr_ptr_bin  <= wr_ptr_bin + 1;
        wr_ptr_gray <= bin2gray(wr_ptr_bin + 1);
    end
end

// --------------------------------------------------
// READ DOMAIN
// --------------------------------------------------

always @(posedge rd_clk or posedge rst)
begin
    if (rst)
    begin
        rd_ptr_bin   <= 0;
        rd_ptr_gray  <= 0;
        m_axis_tdata <= 0;
    end
    else if (rd_en && !empty)
    begin
        m_axis_tdata
            <= mem[rd_ptr_bin[PTR_WIDTH-1:0]];

        rd_ptr_bin  <= rd_ptr_bin + 1;
        rd_ptr_gray <= bin2gray(rd_ptr_bin + 1);
    end
end

// --------------------------------------------------
// Synchronize Read Pointer into Write Domain
// --------------------------------------------------

always @(posedge wr_clk or posedge rst)
begin
    if (rst)
    begin
        rd_ptr_gray_sync1 <= 0;
        rd_ptr_gray_sync2 <= 0;
    end
    else
    begin
        rd_ptr_gray_sync1 <= rd_ptr_gray;
        rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
end

// --------------------------------------------------
// Synchronize Write Pointer into Read Domain
// --------------------------------------------------

always @(posedge rd_clk or posedge rst)
begin
    if (rst)
    begin
        wr_ptr_gray_sync1 <= 0;
        wr_ptr_gray_sync2 <= 0;
    end
    else
    begin
        wr_ptr_gray_sync1 <= wr_ptr_gray;
        wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
end

// --------------------------------------------------
// EMPTY FLAG
// --------------------------------------------------

assign empty =
       (rd_ptr_gray == wr_ptr_gray_sync2);

// --------------------------------------------------
// FULL FLAG
// --------------------------------------------------

wire [PTR_WIDTH:0] wr_ptr_gray_next;

assign wr_ptr_gray_next =
       bin2gray(wr_ptr_bin + 1);

assign full =
       (wr_ptr_gray_next ==
       {~rd_ptr_gray_sync2[PTR_WIDTH:PTR_WIDTH-1],
         rd_ptr_gray_sync2[PTR_WIDTH-2:0]});

endmodule