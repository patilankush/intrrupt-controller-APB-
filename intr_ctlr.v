
module intr_ctlr(
//processor
pclk_i, prst_i, paddr_i, pwdata_i, prdata_o, pwrite_i, penable_i, pready_o, pslverr_o,
intr_to_service_o, intr_valid_o, intr_serviced_i,
//Peripheral controllers
intr_active_i  //interrupts coming from peripherals to INTC
);
parameter NUM_INTR=16;
parameter S_NO_INTR=2'b00;
parameter S_INTR_ACTIVE=2'b01;
parameter S_WAIT_INTR_SERVICE=2'b10;
//parameter S_ERROR=2'b11;

input pclk_i, prst_i, pwrite_i, penable_i;
input [3:0] paddr_i;
input [3:0] pwdata_i;
output reg [3:0] prdata_o;
output reg pready_o;
output reg pslverr_o;
output reg [3:0] intr_to_service_o;
output reg intr_valid_o;
input intr_serviced_i;
input [NUM_INTR-1:0] intr_active_i;

//array of registers
reg [3:0] priority_regA[NUM_INTR-1:0]; //it must be array //register declaration 
reg [1:0] state, next_state;
integer i;  //integer is same as reg [31:0]
reg first_match_f;
reg [3:0] highest_priority;
reg [3:0] intr_with_highest_prio;


always @(next_state) begin
	state = next_state; //state must be a reg variable
end

//two processes
//programming the registers : line number 57-85 is called procedural block. Code inside procedural block is called procedural statements.
always @(posedge pclk_i) begin
	if (prst_i == 1) begin
		//reset all the reg variables
		prdata_o = 0;
		pready_o = 0; //it is inside always block => hence it is a procedural statement => hence pready_o must be a reg
		pslverr_o = 0;
		intr_to_service_o = 0;
		intr_valid_o = 0;
		first_match_f = 0;
		highest_priority = 0; //this line is an example of statement
		intr_with_highest_prio = 0;
		for (i = 0; i < NUM_INTR; i=i+1) begin
			priority_regA[i] = 0;
		end
		state = S_NO_INTR;
		next_state = S_NO_INTR;
	end
	else begin
		if (penable_i == 1) begin //penable_i is given by Processor/same like valid in memory
			pready_o = 1;  //INTR_CTRL
			if (pwrite_i == 1) begin //like wr_en==1 in memory
				priority_regA[paddr_i] = pwdata_i; //write data
			end
			else begin
				prdata_o = priority_regA[paddr_i];  //read data
			end
		end
	end
end

//2nd process
always @(posedge pclk_i) begin
if (prst_i != 1) begin
case (state)
	S_NO_INTR: begin
		if (intr_active_i != 0) begin //it means intrept it happend
			next_state = S_INTR_ACTIVE;
			first_match_f = 1;
		end
	end
	S_INTR_ACTIVE: begin
		//figure out highest priority among all the active interrupts
		for (i = 0; i < NUM_INTR; i=i+1) begin  //entering all priority reg
			if (intr_active_i[i]) begin   //how many intrs are active
				if (first_match_f == 1) begin  //take one inr and compre this intr with all
					intr_with_highest_prio = i; //passing all active intr to this veriable
					highest_priority = priority_regA[i];   //passing all actve intr
					first_match_f = 0;    //
				end
				else begin
					if (priority_regA[i] > highest_priority) begin  //priority_regA[i]  is greater than highest priority
						intr_with_highest_prio = priority_regA[i]; // highest priority intr is giving to intr_with_highest_prio
						highest_priority=i;
					end
				end
			end
		end
		//By the time, we reach here(end of for loop), we know which is the highest priority interrupt and what is the highest priority
		intr_to_service_o = intr_with_highest_prio; //giving highest priority intr to processer
		intr_valid_o = 1;
		next_state = S_WAIT_INTR_SERVICE; // moving to next state
	end
	S_WAIT_INTR_SERVICE: begin
		if (intr_serviced_i == 1) begin //if intr is serviced
			first_match_f = 1; 
			intr_valid_o = 0;
			intr_to_service_o = 0;
			highest_priority = 0;
			intr_with_highest_prio = 0;
			if (intr_active_i != 0) next_state = S_INTR_ACTIVE;  //moving to remaining intrs
			else next_state = S_NO_INTR;
		end
	end
endcase
end
end
endmodule
