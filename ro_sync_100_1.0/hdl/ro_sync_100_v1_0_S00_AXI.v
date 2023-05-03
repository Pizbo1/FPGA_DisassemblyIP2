
`timescale 1 ns / 1 ps

	module ro_sync_100_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
        input wire gated_clock,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 2;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 5
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

    wire [32:0] out1;
    wire [32:0] out2;
    wire [32:0] out3;
    wire [32:0] out4;
    wire [32:0] out5;

	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	        else if (S_AXI_BREADY && axi_bvalid)
	            begin
	              aw_en <= 1'b1;
	              axi_awready <= 1'b0;
	            end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg2 <= 0;
	      slv_reg3 <= 0;
	      slv_reg4 <= 0;
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	          3'h0:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 0
	                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h1:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h2:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 2
	                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h3:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 3
	                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          3'h4:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 4
	                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  
	          default : begin
	                      slv_reg0 <= slv_reg0;
	                      slv_reg1 <= slv_reg1;
	                      slv_reg2 <= slv_reg2;
	                      slv_reg3 <= slv_reg3;
	                      slv_reg4 <= slv_reg4;
	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        3'h0   : reg_data_out <= slv_reg0;
	        3'h1   : reg_data_out <= out1;
	        3'h2   : reg_data_out <= out2;
	        3'h3   : reg_data_out <= out3;
	        3'h4   : reg_data_out <= out4;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;     // register read data
	        end   
	    end
	end    

	// Add user logic here
    (* dont_touch = "true" *) FD FF0(.D(slv_reg0[0]), .C(gated_clock), .Q(out1[0]));
    (* dont_touch = "true" *) FD FF1(.D(out1[0]), .C(gated_clock), .Q(out1[1]));
    (* dont_touch = "true" *) FD FF2(.D(out1[1]), .C(gated_clock), .Q(out1[2]));
    (* dont_touch = "true" *) FD FF3(.D(out1[2]), .C(gated_clock), .Q(out1[3]));
    (* dont_touch = "true" *) FD FF4(.D(out1[3]), .C(gated_clock), .Q(out1[4]));
    (* dont_touch = "true" *) FD FF5(.D(out1[4]), .C(gated_clock), .Q(out1[5]));
    (* dont_touch = "true" *) FD FF6(.D(out1[5]), .C(gated_clock), .Q(out1[6]));
    (* dont_touch = "true" *) FD FF7(.D(out1[6]), .C(gated_clock), .Q(out1[7]));
    (* dont_touch = "true" *) FD FF8(.D(out1[7]), .C(gated_clock), .Q(out1[8]));
    (* dont_touch = "true" *) FD FF9(.D(out1[8]), .C(gated_clock), .Q(out1[9]));
    (* dont_touch = "true" *) FD FF10(.D(out1[9]), .C(gated_clock), .Q(out1[10]));
    (* dont_touch = "true" *) FD FF11(.D(out1[10]), .C(gated_clock), .Q(out1[11]));
    (* dont_touch = "true" *) FD FF12(.D(out1[11]), .C(gated_clock), .Q(out1[12]));
    (* dont_touch = "true" *) FD FF13(.D(out1[12]), .C(gated_clock), .Q(out1[13]));
    (* dont_touch = "true" *) FD FF14(.D(out1[13]), .C(gated_clock), .Q(out1[14]));
    (* dont_touch = "true" *) FD FF15(.D(out1[14]), .C(gated_clock), .Q(out1[15]));
    (* dont_touch = "true" *) FD FF16(.D(out1[15]), .C(gated_clock), .Q(out1[16]));
    (* dont_touch = "true" *) FD FF17(.D(out1[16]), .C(gated_clock), .Q(out1[17]));
    (* dont_touch = "true" *) FD FF18(.D(out1[17]), .C(gated_clock), .Q(out1[18]));
    (* dont_touch = "true" *) FD FF19(.D(out1[18]), .C(gated_clock), .Q(out1[19]));
    (* dont_touch = "true" *) FD FF20(.D(out1[19]), .C(gated_clock), .Q(out1[20]));
    (* dont_touch = "true" *) FD FF21(.D(out1[20]), .C(gated_clock), .Q(out1[21]));
    (* dont_touch = "true" *) FD FF22(.D(out1[21]), .C(gated_clock), .Q(out1[22]));
    (* dont_touch = "true" *) FD FF23(.D(out1[22]), .C(gated_clock), .Q(out1[23]));
    (* dont_touch = "true" *) FD FF24(.D(out1[23]), .C(gated_clock), .Q(out1[24]));
    (* dont_touch = "true" *) FD FF25(.D(out1[24]), .C(gated_clock), .Q(out1[25]));
    (* dont_touch = "true" *) FD FF26(.D(out1[25]), .C(gated_clock), .Q(out1[26]));
    (* dont_touch = "true" *) FD FF27(.D(out1[26]), .C(gated_clock), .Q(out1[27]));
    (* dont_touch = "true" *) FD FF28(.D(out1[27]), .C(gated_clock), .Q(out1[28]));
    (* dont_touch = "true" *) FD FF29(.D(out1[28]), .C(gated_clock), .Q(out1[29]));
    (* dont_touch = "true" *) FD FF30(.D(out1[29]), .C(gated_clock), .Q(out1[30]));
    (* dont_touch = "true" *) FD FF31(.D(out1[30]), .C(gated_clock), .Q(out1[31]));
    (* dont_touch = "true" *) FD FF32(.D(out1[31]), .C(gated_clock), .Q(out2[0]));
    (* dont_touch = "true" *) FD FF33(.D(out2[0]), .C(gated_clock), .Q(out2[1]));
    (* dont_touch = "true" *) FD FF34(.D(out2[1]), .C(gated_clock), .Q(out2[2]));
    (* dont_touch = "true" *) FD FF35(.D(out2[2]), .C(gated_clock), .Q(out2[3]));
    (* dont_touch = "true" *) FD FF36(.D(out2[3]), .C(gated_clock), .Q(out2[4]));
    (* dont_touch = "true" *) FD FF37(.D(out2[4]), .C(gated_clock), .Q(out2[5]));
    (* dont_touch = "true" *) FD FF38(.D(out2[5]), .C(gated_clock), .Q(out2[6]));
    (* dont_touch = "true" *) FD FF39(.D(out2[6]), .C(gated_clock), .Q(out2[7]));
    (* dont_touch = "true" *) FD FF40(.D(out2[7]), .C(gated_clock), .Q(out2[8]));
    (* dont_touch = "true" *) FD FF41(.D(out2[8]), .C(gated_clock), .Q(out2[9]));
    (* dont_touch = "true" *) FD FF42(.D(out2[9]), .C(gated_clock), .Q(out2[10]));
    (* dont_touch = "true" *) FD FF43(.D(out2[10]), .C(gated_clock), .Q(out2[11]));
    (* dont_touch = "true" *) FD FF44(.D(out2[11]), .C(gated_clock), .Q(out2[12]));
    (* dont_touch = "true" *) FD FF45(.D(out2[12]), .C(gated_clock), .Q(out2[13]));
    (* dont_touch = "true" *) FD FF46(.D(out2[13]), .C(gated_clock), .Q(out2[14]));
    (* dont_touch = "true" *) FD FF47(.D(out2[14]), .C(gated_clock), .Q(out2[15]));
    (* dont_touch = "true" *) FD FF48(.D(out2[15]), .C(gated_clock), .Q(out2[16]));
    (* dont_touch = "true" *) FD FF49(.D(out2[16]), .C(gated_clock), .Q(out2[17]));
    (* dont_touch = "true" *) FD FF50(.D(out2[17]), .C(gated_clock), .Q(out2[18]));
    (* dont_touch = "true" *) FD FF51(.D(out2[18]), .C(gated_clock), .Q(out2[19]));
    (* dont_touch = "true" *) FD FF52(.D(out2[19]), .C(gated_clock), .Q(out2[20]));
    (* dont_touch = "true" *) FD FF53(.D(out2[20]), .C(gated_clock), .Q(out2[21]));
    (* dont_touch = "true" *) FD FF54(.D(out2[21]), .C(gated_clock), .Q(out2[22]));
    (* dont_touch = "true" *) FD FF55(.D(out2[22]), .C(gated_clock), .Q(out2[23]));
    (* dont_touch = "true" *) FD FF56(.D(out2[23]), .C(gated_clock), .Q(out2[24]));
    (* dont_touch = "true" *) FD FF57(.D(out2[24]), .C(gated_clock), .Q(out2[25]));
    (* dont_touch = "true" *) FD FF58(.D(out2[25]), .C(gated_clock), .Q(out2[26]));
    (* dont_touch = "true" *) FD FF59(.D(out2[26]), .C(gated_clock), .Q(out2[27]));
    (* dont_touch = "true" *) FD FF60(.D(out2[27]), .C(gated_clock), .Q(out2[28]));
    (* dont_touch = "true" *) FD FF61(.D(out2[28]), .C(gated_clock), .Q(out2[29]));
    (* dont_touch = "true" *) FD FF62(.D(out2[29]), .C(gated_clock), .Q(out2[30]));
    (* dont_touch = "true" *) FD FF63(.D(out2[30]), .C(gated_clock), .Q(out2[31]));
    (* dont_touch = "true" *) FD FF64(.D(out2[31]), .C(gated_clock), .Q(out3[0]));
    (* dont_touch = "true" *) FD FF65(.D(out3[0]), .C(gated_clock), .Q(out3[1]));
    (* dont_touch = "true" *) FD FF66(.D(out3[1]), .C(gated_clock), .Q(out3[2]));
    (* dont_touch = "true" *) FD FF67(.D(out3[2]), .C(gated_clock), .Q(out3[3]));
    (* dont_touch = "true" *) FD FF68(.D(out3[3]), .C(gated_clock), .Q(out3[4]));
    (* dont_touch = "true" *) FD FF69(.D(out3[4]), .C(gated_clock), .Q(out3[5]));
    (* dont_touch = "true" *) FD FF70(.D(out3[5]), .C(gated_clock), .Q(out3[6]));
    (* dont_touch = "true" *) FD FF71(.D(out3[6]), .C(gated_clock), .Q(out3[7]));
    (* dont_touch = "true" *) FD FF72(.D(out3[7]), .C(gated_clock), .Q(out3[8]));
    (* dont_touch = "true" *) FD FF73(.D(out3[8]), .C(gated_clock), .Q(out3[9]));
    (* dont_touch = "true" *) FD FF74(.D(out3[9]), .C(gated_clock), .Q(out3[10]));
    (* dont_touch = "true" *) FD FF75(.D(out3[10]), .C(gated_clock), .Q(out3[11]));
    (* dont_touch = "true" *) FD FF76(.D(out3[11]), .C(gated_clock), .Q(out3[12]));
    (* dont_touch = "true" *) FD FF77(.D(out3[12]), .C(gated_clock), .Q(out3[13]));
    (* dont_touch = "true" *) FD FF78(.D(out3[13]), .C(gated_clock), .Q(out3[14]));
    (* dont_touch = "true" *) FD FF79(.D(out3[14]), .C(gated_clock), .Q(out3[15]));
    (* dont_touch = "true" *) FD FF80(.D(out3[15]), .C(gated_clock), .Q(out3[16]));
    (* dont_touch = "true" *) FD FF81(.D(out3[16]), .C(gated_clock), .Q(out3[17]));
    (* dont_touch = "true" *) FD FF82(.D(out3[17]), .C(gated_clock), .Q(out3[18]));
    (* dont_touch = "true" *) FD FF83(.D(out3[18]), .C(gated_clock), .Q(out3[19]));
    (* dont_touch = "true" *) FD FF84(.D(out3[19]), .C(gated_clock), .Q(out3[20]));
    (* dont_touch = "true" *) FD FF85(.D(out3[20]), .C(gated_clock), .Q(out3[21]));
    (* dont_touch = "true" *) FD FF86(.D(out3[21]), .C(gated_clock), .Q(out3[22]));
    (* dont_touch = "true" *) FD FF87(.D(out3[22]), .C(gated_clock), .Q(out3[23]));
    (* dont_touch = "true" *) FD FF88(.D(out3[23]), .C(gated_clock), .Q(out3[24]));
    (* dont_touch = "true" *) FD FF89(.D(out3[24]), .C(gated_clock), .Q(out3[25]));
    (* dont_touch = "true" *) FD FF90(.D(out3[25]), .C(gated_clock), .Q(out3[26]));
    (* dont_touch = "true" *) FD FF91(.D(out3[26]), .C(gated_clock), .Q(out3[27]));
    (* dont_touch = "true" *) FD FF92(.D(out3[27]), .C(gated_clock), .Q(out3[28]));
    (* dont_touch = "true" *) FD FF93(.D(out3[28]), .C(gated_clock), .Q(out3[29]));
    (* dont_touch = "true" *) FD FF94(.D(out3[29]), .C(gated_clock), .Q(out3[30]));
    (* dont_touch = "true" *) FD FF95(.D(out3[30]), .C(gated_clock), .Q(out3[31]));
    (* dont_touch = "true" *) FD FF96(.D(out3[31]), .C(gated_clock), .Q(out4[0]));
    (* dont_touch = "true" *) FD FF97(.D(out4[0]), .C(gated_clock), .Q(out4[1]));
    (* dont_touch = "true" *) FD FF98(.D(out4[1]), .C(gated_clock), .Q(out4[2]));
    (* dont_touch = "true" *) FD FF99(.D(out4[2]), .C(gated_clock), .Q(out4[3]));

    
    
	// User logic ends

	endmodule
