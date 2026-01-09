
`timescale 1ns/1ps

module sync_fifo(
    input logic clk,rst,
    input logic [7:0] data_in,
    input logic write_en, read_en,
    output logic [7:0] data_out,
    output logic full,empty
);

  logic [3:0] write_ptr, read_ptr;
  logic [7:0] mem [15:0] ;
  logic [4:0] counter;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        data_out <= 8'd0;
        counter <= 5'd0;
        write_ptr <= 4'd0;
        read_ptr <= 4'd0;

    end
  
  else begin 
    if ((write_en && !full) && (read_en && !empty)) 
      begin
        counter <= counter;
        read_ptr <= read_ptr + 1;
        write_ptr <= write_ptr + 1;
        data_out <= mem[read_ptr];
        mem[write_ptr] <= data_in;
        
  end
    else if(read_en && !empty)
     begin
        data_out <= mem[read_ptr];
        counter <= counter -1;
        read_ptr <= read_ptr + 1;
    end
    else if (write_en && !full) begin     
        mem[write_ptr] <= data_in;
        counter <= counter + 1;
        write_ptr <= write_ptr + 1;
    end
  end

end
  
  assign full = (counter == 5'd16 ) ? 1'b1 : 1'b0;
  assign empty = (counter == 5'd0 ) ? 1'b1 : 1'b0;

endmodule


// Define an interface for the FIFO
interface fifo_if;
  logic clk, rst, write_en, read_en;         // Clock, read, and write signals
  logic full, empty;           // Flags indicating FIFO status
  logic [7:0] data_in;         // Data input
  logic [7:0] data_out;        // Data output

  modport drv_mp (
        input clock,
        output rst, wr, rd, data_in,
        input data_out, full, empty
    );

    modport mon_mp (
        input clock, rst, wr, rd, data_in,
        output data_out, full, empty
    );
  
endinterface
