
`include "intr_ctlr.v"
module tb;
parameter NUM_INTR=16;
reg pclk_i, prst_i, pwrite_i, penable_i;
reg [3:0] paddr_i;
reg [3:0] pwdata_i;
wire [3:0] prdata_o;
wire pready_o;
wire pslverr_o;
wire [3:0] intr_to_service_o;
wire intr_valid_o;
reg intr_serviced_i;
reg [NUM_INTR-1:0] intr_active_i;
integer i;

intr_ctlr dut (
//processor
pclk_i, prst_i, paddr_i, pwdata_i, prdata_o, pwrite_i, penable_i, pready_o, pslverr_o,
intr_to_service_o, intr_valid_o, intr_serviced_i,
//Peripheral controllers
intr_active_i
);

initial begin
	pclk_i = 0;
	forever #5 pclk_i =  ~pclk_i;
end

initial begin
	prst_i = 1;
	intr_active_i = 0;
	paddr_i = 0;
	pwdata_i = 0;
	pwrite_i = 0;
	penable_i = 0;
	repeat(2) @(posedge pclk_i);
	prst_i  = 0;
	//program the regsiters for priority values
	for (i = 0; i < NUM_INTR; i=i+1) begin
		reg_write(i, NUM_INTR-1-i);
	end
	//raise interrupts
	intr_active_i = $random;
	//Dropping hand: make corrersponding bit in intr_active_i to 0
	#500;
	intr_active_i = $random;
	#500;
	$finish;
end

always begin
	@(posedge pclk_i);
	if (intr_valid_o == 1) begin //Processor logic
		#30; //to process the question or interrupt
		intr_active_i[intr_to_service_o] = 0; //dropping the interrupt  ===> peripheral logic
		intr_serviced_i = 1; //processor logic
		@(posedge pclk_i);
		intr_serviced_i = 0;
	end
end

task reg_write(input [3:0] addr, input [3:0] data);
begin
	@(posedge pclk_i);
	paddr_i = addr;  //0->1->2...
	pwdata_i = data;  //(i : giving lowest priority, 15-i : giving highest priority)
	pwrite_i = 1;
	penable_i = 1;
	wait (pready_o == 1);
	@(posedge pclk_i);
	pwrite_i = 0;
	penable_i = 0;
	paddr_i = 0;
	pwdata_i = 0;
end
endtask
endmodule
