// Branch Target Buffer with a 2-bit saturating counter per entry (direct mapped).
//   index = PC[IDXW+1:2], tag = PC[31:IDXW+2]
//   counter: 11/10 predict taken, 01/00 predict not taken; a miss predicts not taken
// Two prediction ports (the fetched pair) and one update port (branch unit, Execute).
// The update reads the current counter: in a short loop the next instance of the
// branch is fetched before the previous one updates, so a copy made in Fetch is stale.
module btb #(parameter IDXW = 4)  // 2^IDXW entries
           (input         clk, reset,
            // prediction (Fetch)
            input  [31:0] pc_0, pc_1,
            output        predtaken_0, predtaken_1,
            output [31:0] target_0, target_1,
            // update (Execute)
            input         update,
            input  [31:0] upc,
            input         utaken, ujump,
            input  [31:0] utarget);

  localparam N    = 1 << IDXW;
  localparam TAGW = 30 - IDXW;

  reg            valid [N-1:0];
  reg [TAGW-1:0] tag   [N-1:0];
  reg [1:0]      ctr   [N-1:0];
  reg [31:0]     target[N-1:0];

  // ================= PREDICTION =================
  wire [IDXW-1:0] idx_0 = pc_0[IDXW+1:2];
  wire [IDXW-1:0] idx_1 = pc_1[IDXW+1:2];
  wire            hit_0 = valid[idx_0] & (tag[idx_0] == pc_0[31:IDXW+2]);
  wire            hit_1 = valid[idx_1] & (tag[idx_1] == pc_1[31:IDXW+2]);

  assign predtaken_0 = hit_0 & ctr[idx_0][1];
  assign predtaken_1 = hit_1 & ctr[idx_1][1];
  assign target_0    = target[idx_0];
  assign target_1    = target[idx_1];

  // ================= UPDATE =================
  wire [IDXW-1:0] uidx = upc[IDXW+1:2];
  wire            uhit = valid[uidx] & (tag[uidx] == upc[31:IDXW+2]);
  wire [1:0]      uctr = ctr[uidx];
  wire [1:0]      inc  = (uctr == 2'b11) ? 2'b11 : uctr + 2'b01;
  wire [1:0]      dec  = (uctr == 2'b00) ? 2'b00 : uctr - 2'b01;

  integer i;

  // taken: write the entry and count up (new entry -> 10, jal -> 11)
  // not taken: count down if the entry exists
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      for (i = 0; i < N; i = i + 1) begin
        valid[i]  <= 1'b0;
        tag[i]    <= 0;
        ctr[i]    <= 2'b00;
        target[i] <= 32'b0;
      end
    end else if (update & utaken) begin
      valid[uidx]  <= 1'b1;
      tag[uidx]    <= upc[31:IDXW+2];
      target[uidx] <= utarget;
      ctr[uidx]    <= ujump ? 2'b11 : uhit ? inc : 2'b10;
    end else if (update & uhit) begin
      ctr[uidx]    <= dec;
    end
  end

endmodule
