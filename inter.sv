module inter(
  // Input signals
  clk,
  rst_n,
  in_valid_1,
  in_valid_2,
  data_in_1,
  data_in_2,
  ready_slave1,
  ready_slave2,
  // Output signals
  valid_slave1,
  valid_slave2,
  addr_out,
  value_out,
  handshake_slave1,
  handshake_slave2
);

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
input clk, rst_n, in_valid_1, in_valid_2;
input [6:0] data_in_1, data_in_2; 
input ready_slave1, ready_slave2;

output logic valid_slave1, valid_slave2;
output logic [2:0] addr_out, value_out;
output logic handshake_slave1, handshake_slave2;

parameter [1:0] IDLE = 2'b000,
                MASTER1 = 2'b001,
                MASTER2 = 2'b010,
                HANDSHAKE = 2'b011;

logic in1, in2, in1_next, in2_next, vs1, vs1_next, vs2, vs2_next, rd1, rd2;
logic [1:0] state, next;
logic [6:0] store1, store1_next, store2, store2_next;

//state reg
always_ff @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
        in1 <= 0;
        in2 <= 0;
        vs1 <= 0;
        vs2 <= 0;
        state <= IDLE;
        store1 <= 0;
        store2 <= 0;
    end
    else begin
        in1 <= in1_next;
        in2 <= in2_next;
        vs1 <= vs1_next;
        vs2 <= vs2_next;
        state <= next;
        store1 <= store1_next;
        store2 <= store2_next;
        rd1 <= ready_slave1;
        rd2 <= ready_slave2;
    end
end

//next state logic
always_comb begin : nextstate
    case(state)
    IDLE : begin
        if(in1) begin
            next = MASTER1;
        end
        else if(in2) begin
            next = MASTER2;
        end
        else begin
            next = IDLE;
        end
    end

    MASTER1 : begin
        if(store1[6] == 0 && vs1 && rd1) begin
            next = HANDSHAKE;
        end
        else if (store1[6] == 1 && vs2 && rd2) begin
            next = HANDSHAKE;
        end
        else begin
            next = MASTER1;
        end
    end
    MASTER2 : begin
        if(store2[6] == 0 && vs1 && rd1) begin
            next = HANDSHAKE;
        end
        else if (store2[6] == 1 && vs2 && rd2) begin
            next = HANDSHAKE;
        end
        else begin
            next = MASTER2;
        end
    end
    HANDSHAKE : begin
        if(in1) begin
            next = MASTER1;
        end
        else if(in2) begin
            next = MASTER2;
        end
        else begin
            next = IDLE;
        end
    end
    default : begin
        next = IDLE;
    end
    endcase
end : nextstate

always_comb begin : in1in2
    case(state)
    IDLE : begin
		if(in_valid_1 || in_valid_2) begin
			in1_next = in_valid_1;
        	in2_next = in_valid_2;
		end
		else begin
			in1_next = in1;
			in2_next = in2;
		end
        
    end
    MASTER1 : begin
		in2_next = in2;
        if(store1[6] == 0 && vs1 && rd1) begin
            in1_next = 0;
        end
        else if (store1[6] == 1 && vs2 && rd2) begin
            in1_next = 0;
        end
        else begin
            in1_next = in1;
        end
    end
    MASTER2 : begin
		in1_next = in1;
        if(store2[6] == 0 && vs1 && rd1) begin
            in2_next = 0;
        end
        else if (store2[6] == 1 && vs2 && rd2) begin
            in2_next = 0;
        end
        else begin
            in2_next = in2;
        end
    end
    HANDSHAKE : begin
        in1_next = in1;
        in2_next = in2;
    end
    default : begin
        in1_next = 0;
        in2_next = 0;
    end
    endcase
end : in1in2

always_comb begin : vsnext
    case(state)
    IDLE : begin
        if(in1) begin
            if(!store1[6]) begin
                vs1_next = 1;
                vs2_next = 0;
            end
            else begin
                vs1_next = 0;
                vs2_next = 1;
            end
        end
        else if(in2) begin
            if(!store2[6]) begin
                vs1_next = 1;
                vs2_next = 0;
            end
            else begin
                vs1_next = 0;
                vs2_next = 1;
            end
        end
        else begin
            vs1_next = 0;
            vs2_next = 0;
        end
    end
    MASTER1 : begin
        vs1_next = vs1;
        vs2_next = vs2;
    end
    MASTER2 : begin
        vs1_next = vs1;
        vs2_next = vs2;
    end
    HANDSHAKE : begin
        if(in1) begin
            if(!store1[6]) begin
                vs1_next = 1;
                vs2_next = 0;
            end
            else begin
                vs1_next = 0;
                vs2_next = 1;
            end
        end
        else if(in2) begin
            if(!store2[6]) begin
                vs1_next = 1;
                vs2_next = 0;
            end
            else begin
                vs1_next = 0;
                vs2_next = 1;
            end
        end
        else begin
            vs1_next = 0;
            vs2_next = 0;
        end
    end
    default : begin
        vs1_next = 0;
        vs2_next = 0;
    end
    endcase
end : vsnext

always_comb begin : storage
    case(state)
    IDLE : begin
		if(in_valid_1 || in_valid_2) begin
			store1_next = data_in_1;
			store2_next = data_in_2;
		end
		else begin
			store1_next = store1;
			store2_next = store2;
		end
    end
    MASTER1 : begin
        store1_next = store1;
        store2_next = store2;
    end
    MASTER2 : begin
        store1_next = store1;
        store2_next = store2;
    end
    HANDSHAKE : begin
        store1_next = store1;
        store2_next = store2;
    end
    default : begin
        store1_next = 0;
        store2_next = 0;
    end
    endcase
end : storage

//output logic
assign valid_slave1 = vs1;
assign valid_slave2 = vs2;
always_comb begin : hs
    if(state == HANDSHAKE) begin
        if(vs1) begin
            handshake_slave1 = 1;
            handshake_slave2 = 0;
        end
        else if(vs2) begin
            handshake_slave1 = 0;
            handshake_slave2 = 1;
        end
        else begin
            handshake_slave1 = 0;
            handshake_slave2 = 0;
        end
    end
    else begin
        handshake_slave1 = 0;
        handshake_slave2 = 0;
    end
end : hs
always_comb begin 
    case(state)
	IDLE : begin
		addr_out = 0;
        value_out = 0;
	end
	MASTER1 : begin
		addr_out = store1[5:3];
        value_out = store1[2:0];
	end
	MASTER2 : begin
		addr_out = store2[5:3];
        value_out = store2[2:0];
	end
	HANDSHAKE : begin
		if(vs1) begin
			addr_out = store1[5:3];
        	value_out = store1[2:0];
		end
		else if (vs2) begin
			addr_out = store2[5:3];
        	value_out = store2[2:0];
		end
		else begin
			addr_out = 0;
        	value_out = 0;
		end
	end
	default : begin
		addr_out = 0;
        value_out = 0;
	end
    endcase
end 

endmodule
