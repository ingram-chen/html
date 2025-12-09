//==============================================================================
// I2C Slave Implementation with Clock Stretching Support
// Target: Fast Mode (400kHz)
// Addressing: 7-bit slave addressing
// Features: Complete Clock Stretching, Open-drain I/O
//==============================================================================

module i2c_slave_CTO (
    // System signals
    input  wire        clk,           // System clock
    input  wire        reset_n,       // Active low reset
    
    // I2C bus signals (open-drain)
    input  wire        scl_in,        // SCL input from bus
    input  wire        sda_in,        // SDA input from bus
    output wire        scl_out,       // SCL output to bus (open-drain)
    output wire        sda_out,       // SDA output to bus (open-drain)
    
    // Slave configuration
    input  wire [6:0]  slave_addr,    // 7-bit slave address
    
    // Data interface
    input  wire [7:0]  data_in,       // Data to transmit (read operation)
    output reg  [7:0]  data_out,      // Received data (write operation)
    
    // Control signals
    output reg         read_req,      // Read operation request
    output reg         write_req,     // Write operation request
    input  wire        ack_bit,       // Acknowledge bit from user logic
    output reg         transfer_done, // Transfer completion flag
    
    // Status signals
    output reg         bus_busy,      // Bus busy indicator
    output reg         addr_match     // Address match indicator
);

//==============================================================================
// Internal Parameters and States
//==============================================================================
parameter IDLE          = 4'b0000;  // Idle state, waiting for START
parameter START         = 4'b0001;  // START condition detected
parameter ADDR_PHASE    = 4'b0010;  // Address reception phase
parameter ADDR_ACK      = 4'b0011;  // Address ACK phase
parameter READ_PHASE    = 4'b0100;  // Read data transmission
parameter READ_ACK      = 4'b0101;  // Read ACK phase
parameter WRITE_PHASE   = 4'b0110;  // Write data reception
parameter WRITE_ACK     = 4'b0111;  // Write ACK phase
parameter STOP          = 4'b1000;  // STOP condition detected

//==============================================================================
// Internal Signals
//==============================================================================
reg [3:0]  state, next_state;
reg [2:0]  bit_counter;          // 8-bit counter for data bits
reg [7:0]  shift_reg;            // Shift register for data/addr
reg [6:0]  received_addr;        // Received address
reg        rw_bit;               // Read/Write bit
reg        sda_out_reg;          // SDA output register
reg        scl_out_reg;          // SCL output register
reg        clock_stretch;        // Clock stretching enable

// SCL and SDA edge detection
reg        scl_prev;
reg        sda_prev;
wire       scl_rising  = scl_in & ~scl_prev;
wire       scl_falling = ~scl_in & scl_prev;
wire       sda_rising  = sda_in & ~sda_prev;
wire       sda_falling = ~sda_in & sda_prev;

// START/STOP condition detection
wire       start_condition = scl_in & sda_falling;
wire       stop_condition  = scl_in & sda_rising;

//==============================================================================
// Open-drain output drivers
//==============================================================================
assign scl_out = clock_stretch ? 1'b0 : 1'b1;  // Pull low during stretch
assign sda_out = sda_out_reg ? 1'b1 : 1'b0;   // Open-drain SDA

//==============================================================================
// SCL/SDA synchronization and edge detection
//==============================================================================
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        scl_prev <= 1'b1;
        sda_prev <= 1'b1;
    end else begin
        scl_prev <= scl_in;
        sda_prev <= sda_in;
    end
end

//==============================================================================
// Main state machine
//==============================================================================
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

//==============================================================================
// State transition logic
//==============================================================================
always @(*) begin
    next_state = state;
    
    case (state)
        IDLE: begin
            if (start_condition) begin
                next_state = ADDR_PHASE;
            end
        end
        
        ADDR_PHASE: begin
            if (bit_counter == 3'd7 && scl_falling) begin
                next_state = ADDR_ACK;
            end
        end
        
        ADDR_ACK: begin
            if (scl_rising) begin
                if (addr_match) begin
                    if (rw_bit) begin
                        next_state = READ_PHASE;
                    end else begin
                        next_state = WRITE_PHASE;
                    end
                end else begin
                    next_state = IDLE;
                end
            end
        end
        
        READ_PHASE: begin
            if (bit_counter == 3'd7 && scl_falling) begin
                next_state = READ_ACK;
            end
        end
        
        READ_ACK: begin
            if (scl_rising) begin
                if (ack_bit) begin
                    next_state = READ_PHASE;
                end else begin
                    next_state = IDLE;
                end
            end
        end
        
        WRITE_PHASE: begin
            if (bit_counter == 3'd7 && scl_falling) begin
                next_state = WRITE_ACK;
            end
        end
        
        WRITE_ACK: begin
            if (scl_rising) begin
                if (ack_bit) begin
                    next_state = WRITE_PHASE;
                end else begin
                    next_state = IDLE;
                end
            end
        end
        
        default: begin
            if (stop_condition) begin
                next_state = IDLE;
            end else if (start_condition) begin
                next_state = ADDR_PHASE;
            end
        end
    endcase
end

//==============================================================================
// Bit counter management
//==============================================================================
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        bit_counter <= 3'd0;
    end else begin
        case (state)
            ADDR_PHASE: begin
                if (scl_rising) begin
                    bit_counter <= bit_counter + 1'b1;
                end
            end
            READ_PHASE: begin
                if (scl_rising) begin
                    bit_counter <= bit_counter + 1'b1;
                end
            end
            WRITE_PHASE: begin
                if (scl_rising) begin
                    bit_counter <= bit_counter + 1'b1;
                end
            end
            IDLE: begin
                bit_counter <= 3'd0;
            end
            default: begin
                if (next_state == ADDR_PHASE || 
                    next_state == READ_PHASE || 
                    next_state == WRITE_PHASE) begin
                    bit_counter <= 3'd0;
                end
            end
        endcase
    end
end

//==============================================================================
// Shift register and data handling
//==============================================================================
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        shift_reg <= 8'd0;
        received_addr <= 7'd0;
        rw_bit <= 1'b0;
    end else begin
        case (state)
            ADDR_PHASE: begin
                if (scl_rising) begin
                    shift_reg <= {shift_reg[6:0], sda_in};
                end
            end
            ADDR_ACK: begin
                if (scl_falling) begin
                    received_addr <= shift_reg[6:0];
                    rw_bit <= shift_reg[0];
                end
            end
            WRITE_PHASE: begin
                if (scl_rising) begin
                    shift_reg <= {shift_reg[6:0], sda_in};
                end
            end
            WRITE_ACK: begin
                if (scl_falling) begin
                    data_out <= shift_reg;
                end
            end
        endcase
    end
end

//==============================================================================
// Address matching logic
//==============================================================================
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        addr_match <= 1'b0;
    end else begin
        if (state == ADDR_ACK && scl_falling) begin
            addr_match <= (received_addr == slave_addr);
        end else if (state == IDLE) begin
            addr_match <= 1'b0;
        end
    end
end

//==============================================================================
// Read data transmission
//==============================================================================
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        shift_reg <= 8'd0;
    end else begin
        if (state == READ_ACK && scl_falling) begin
            shift_reg <= data_in;  // Load new data for transmission
        end
    end
end

//==============================================================================
// SDA output control
//==============================================================================
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        sda_out_reg <= 1'b1;  // High impedance (release bus)
    end else begin
        case (state)
            ADDR_ACK: begin
                if (addr_match && scl_falling) begin
                    sda_out_reg <= 1'b0;  // Send ACK
                end else if (!addr_match && scl_falling) begin
                    sda_out_reg <= 1'b1;  // Send NACK
                end
            end
            READ_PHASE: begin
                if (scl_falling) begin
                    sda_out_reg <= shift_reg[7-bit_counter];
                end
            end
            READ_ACK: begin
                sda_out_reg <= 1'b1;  // Release for master ACK/NACK
            end
            WRITE_ACK: begin
                if (scl_falling) begin
                    sda_out_reg <= ack_bit ? 1'b0 : 1'b1;  // Send ACK/NACK
                end
            end
            default: begin
                sda_out_reg <= 1'b1;  // Release bus
            end
        endcase
    end
end

//==============================================================================
// Clock stretching control
//==============================================================================
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        clock_stretch <= 1'b0;
    end else begin
        // Enable clock stretching during processing
        if ((state == WRITE_ACK && scl_falling) ||
            (state == READ_ACK && scl_falling)) begin
            clock_stretch <= 1'b1;  // Stretch clock for processing
        end else if (clock_stretch && scl_in == 1'b0) begin
            clock_stretch <= 1'b0;  // Release clock when ready
        end
    end
end

//==============================================================================
// Control signal generation
//==============================================================================
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        read_req <= 1'b0;
        write_req <= 1'b0;
        transfer_done <= 1'b0;
        bus_busy <= 1'b0;
    end else begin
        // Read request
        if (state == ADDR_ACK && addr_match && rw_bit && scl_rising) begin
            read_req <= 1'b1;
        end else begin
            read_req <= 1'b0;
        end
        
        // Write request
        if (state == WRITE_ACK && scl_rising) begin
            write_req <= 1'b1;
        end else begin
            write_req <= 1'b0;
        end
        
        // Transfer completion
        if (state == IDLE && (next_state != IDLE)) begin
            transfer_done <= 1'b0;
        end else if ((state == READ_ACK && !ack_bit && scl_rising) ||
                    (state == WRITE_ACK && !ack_bit && scl_rising) ||
                    stop_condition) begin
            transfer_done <= 1'b1;
        end
        
        // Bus busy indicator
        if (start_condition) begin
            bus_busy <= 1'b1;
        end else if (stop_condition) begin
            bus_busy <= 1'b0;
        end
    end
end

endmodule