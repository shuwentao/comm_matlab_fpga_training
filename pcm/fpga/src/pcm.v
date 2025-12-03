module PCM_Encode (
    input               clk,        // 时钟信号
    input               aclr,       // 异步复位信号（高有效）
    input  [10:0]       Sig_In,     // 11位输入信号
    input               iNd,        // 输入数据有效信号（高有效）
    output reg [7:0]    Enc_Out,    // 8位PCM编码输出
    output reg          Rdy         // 输出数据就绪信号（高有效）
);

// 内部信号声明
reg [2:0]             State;          // 状态机状态（0-7共8个状态，用3位表示）
reg [1:0]             iNd_dly;        // 输入有效信号延迟同步
reg [7:0]             Enc_Out_reg;    // 编码输出寄存器
reg [10:0]            Sig_Buf;        // 输入信号缓冲
reg [9:0]             Sig_Buf_abs;    // 输入信号绝对值（11位最大1023，用10位表示）
reg [5:0]             step;           // 量化步长（0-64，用6位表示）
reg [8:0]             thresh;         // 量化阈值（0-512，用9位表示）
reg [8:0]             diff;           // 信号绝对值与阈值的差值（0-512，用9位表示）
reg [8:0]             diff_vec;       // 差值的寄存器形式（9位）

always @(posedge clk or posedge aclr) begin  // 异步复位，时钟上升沿触发
    if (aclr == 1'b1) begin
        // 异步复位：所有信号置初始值
        State       <= 3'd0;
        iNd_dly     <= 2'b00;
        Enc_Out_reg <= 8'd0;
        Enc_Out     <= 8'd0;
        Rdy         <= 1'b0;
        Sig_Buf     <= 11'd0;
        Sig_Buf_abs <= 10'd0;
        step        <= 6'd0;
        thresh      <= 9'd0;
        diff        <= 9'd0;
        diff_vec    <= 9'd0;
    end else begin
        // 时钟上升沿：处理时序逻辑
        iNd_dly <= {iNd_dly[0], iNd};  // 延迟同步iNd信号（消抖+同步）
        Rdy <= 1'b0;  // 默认置输出未就绪
        
        // 状态机逻辑
        case (State)
            3'd0: begin  // 空闲状态：等待输入数据有效
                if (iNd_dly == 2'b01) begin  // 检测iNd上升沿（新数据到来）
                    State <= 3'd1;  // 进入下一状态
                    // 处理输入信号符号：最高位为1表示负数，取反；0表示正数，直接存储
                    if (Sig_In[10] == 1'b0) begin
                        Enc_Out_reg[7] <= 1'b0;  // 符号位：0=正数
                        Sig_Buf <= Sig_In;
                    end else begin
                        Enc_Out_reg[7] <= 1'b1;  // 符号位：1=负数
                        Sig_Buf <= ~Sig_In;  // 负数取反（后续+1得到绝对值）
                    end
                end
            end
            
            3'd1: begin  // 计算输入信号绝对值
                if (Sig_In[10] == 1'b0) begin
                    Sig_Buf_abs <= Sig_Buf;  // 正数直接赋值（Verilog支持向量到整数转换）
                end else begin
                    Sig_Buf_abs <= Sig_Buf + 11'd1;  // 负数取反后+1得绝对值
                end
                State <= 3'd2;  // 进入量化区间判断状态
            end
            
            3'd2: begin  // 量化区间判断：确定3位区间码、步长和阈值
                if (Sig_Buf_abs >= 10'd0 && Sig_Buf_abs < 10'd16) begin
                    Enc_Out_reg[6:4] <= 3'b000;  // 区间码0
                    step <= 6'd1;  // 量化步长1
                    thresh <= 9'd0;  // 区间阈值0
                end else if (Sig_Buf_abs >= 10'd16 && Sig_Buf_abs < 10'd32) begin
                    Enc_Out_reg[6:4] <= 3'b001;  // 区间码1
                    step <= 6'd1;
                    thresh <= 9'd16;
                end else if (Sig_Buf_abs >= 10'd32 && Sig_Buf_abs < 10'd64) begin
                    Enc_Out_reg[6:4] <= 3'b010;  // 区间码2
                    step <= 6'd2;
                    thresh <= 9'd32;
                end else if (Sig_Buf_abs >= 10'd64 && Sig_Buf_abs < 10'd128) begin
                    Enc_Out_reg[6:4] <= 3'b011;  // 区间码3
                    step <= 6'd4;
                    thresh <= 9'd64;
                end else if (Sig_Buf_abs >= 10'd128 && Sig_Buf_abs < 10'd256) begin
                    Enc_Out_reg[6:4] <= 3'b100;  // 区间码4
                    step <= 6'd8;
                    thresh <= 9'd128;
                end else if (Sig_Buf_abs >= 10'd256 && Sig_Buf_abs < 10'd512) begin
                    Enc_Out_reg[6:4] <= 3'b101;  // 区间码5
                    step <= 6'd16;
                    thresh <= 9'd256;
                end else begin  // Sig_Buf_abs >= 512（最大1023）
                    Enc_Out_reg[6:4] <= 3'b110;  // 区间码6
                    step <= 6'd32;
                    thresh <= 9'd512;
                end
                State <= 3'd3;  // 进入差值计算状态
            end
            
            3'd3: begin  // 计算信号绝对值与阈值的差值
                diff <= Sig_Buf_abs - thresh;
                State <= 3'd4;
            end
            
            3'd4: begin  // 差值赋值（Verilog无需显式类型转换，直接赋值）
                diff_vec <= diff;
                State <= 3'd5;
            end
            
            3'd5: begin  // 量化编码：根据步长提取4位量化码（右移等效除法）
                case (step)
                    6'd2:  Enc_Out_reg[3:0] <= diff_vec[4:1];  // 右移1位（除以2）
                    6'd4:  Enc_Out_reg[3:0] <= diff_vec[5:2];  // 右移2位（除以4）
                    6'd8:  Enc_Out_reg[3:0] <= diff_vec[6:3];  // 右移3位（除以8）
                    6'd16: Enc_Out_reg[3:0] <= diff_vec[7:4];  // 右移4位（除以16）
                    6'd32: Enc_Out_reg[3:0] <= diff_vec[8:5];  // 右移5位（除以32）
                    default: Enc_Out_reg[3:0] <= diff_vec[3:0];  // step=1（无需移位）
                endcase
                State <= 3'd6;
            end
            
            3'd6: begin  // 输出编码结果并置就绪信号
                Enc_Out <= Enc_Out_reg;  // 8位编码输出（符号位+3位区间码+4位量化码）
                Rdy <= 1'b1;  // 置输出就绪
                State <= 3'd0;  // 回到空闲状态
            end
            
            default: begin  // 其他状态：复位到空闲状态
                State <= 3'd0;
            end
        endcase
    end
end

endmodule
