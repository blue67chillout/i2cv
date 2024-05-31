module test #(
    parameter N=7,Div = 2
) (
   sda,scl,ack_a,clk,rst,addr,rw,en,din,dout
);
    output sda; //serial data
    output scl; //serial clk
    input ack_a;
    input clk;
    input rst;
    input en;
    input [N-1:0]addr;
    input rw;       // write || rw=0 ; read || rw = 1
    input [7:0]din;
    
    output reg [7:0]dout ;// for read mode

localparam IDLE = 4'd1;
localparam START = 4'd2;
localparam ADDR = 4'd3;
localparam ACK0 = 4'd4; //ack for addr verification and rw
localparam W_DATA = 4'd5;
localparam ACK1 = 4'd6; //ack for successful write
localparam R_DATA = 4'd7;
localparam ACK2 = 4'd8; //ack for successfull read
localparam STOP = 4'd9;

reg [3:0]state;
reg [N:0] addrw; // temp for addr and rw desn't affect that much just saves a state
reg [7:0] saved_data; //temp for din
reg sda_out;  //temp for sda
reg clk_temp = 0;
reg [2:0]count;
reg [2:0]counter = 0;
assign scl = (en == 1)?clk_temp:1'b1;
assign sda = (en == 1)?sda_out:1'b1;


//the implementation is a moore machine which changes states a/c to the i2c protocol


always@(posedge clk) begin
    if(counter == Div-1) begin
        clk_temp <= ~clk_temp;    // clk divider to set relation between
        counter <= 0;           //   sytem clk and scl 
    end
    else counter <= counter + 1;
end

always@(posedge clk_temp or posedge rst or en) begin
    if(rst || !en) begin
        state <= IDLE;
    end
    else begin
        case(state)
            IDLE:  begin
                state <= START;
                addrw <= {addr,rw}; 
            end 

            START: begin
                state <= ADDR;
                count <=3'd7;
                saved_data <= din;
            end

            ADDR: begin
                if (count == 0 && addrw[0] == 0) state <= ACK0;
                else count<= count - 1; 
            end

            ACK0: begin
                if(ack_a == 0 && addrw[0] == 0) begin
                    state <= W_DATA;
                    count <= 3'd7;
                end
                else if(ack_a == 0 && addrw[0] == 1) begin
                    state <= R_DATA;
                    count <= 3'd7;
                end
                else state <= STOP;
            end

            W_DATA: begin
                if(count == 0 )begin
                    state <= ACK1;
                end
                else count <= count - 1;
            end

            R_DATA: begin
                if(count == 0 )begin
                    state <= ACK2;
                end
                else count <= count - 1;
            end

            ACK1: begin
                if(ack_a == 0) begin
                    state <= W_DATA;
                    count <= 3'd7;
                end
                else state <= STOP;
            end

            ACK2: begin
                if(ack_a == 0) begin
                    state <= R_DATA;
                    count <= 3'd7;
                end
                else state <= STOP;
            end

            STOP: begin
                state <= IDLE;
            end
            default:state <= IDLE;

        endcase
    end
    
end

always@(negedge clk_temp or posedge rst or en) begin
    if(rst || !en) begin
        sda_out <= 1'b1;
    end
    else begin
        case (state)
            IDLE:sda_out <= 1;
            ADDR:sda_out <= addrw[count];
            W_DATA: sda_out <= saved_data[count];
            R_DATA:dout[count] <= sda_out;
            ACK2:sda_out <= 0;
            default:sda_out <= 1; 
        endcase
    end
end

always@(posedge clk_temp or posedge rst or en) begin
    if(rst || !en) begin
        sda_out <= 1'b1;
    end
    else begin
        case (state)
            START: sda_out <=0;   //still have doubt  about the triggering at this point
            STOP : sda_out <=1;

        endcase
    end
end
endmodule





