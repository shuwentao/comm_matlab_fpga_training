library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity PCM_Encode is
    port(
        clk:        in  std_logic;          -- 时钟信号
        aclr:       in  std_logic;          -- 异步复位信号（高有效）
        Sig_In:     in  std_logic_vector(10 downto 0);  -- 11位输入信号
        iNd:        in  std_logic;          -- 输入数据有效信号（高有效）
        Enc_Out:    out std_logic_vector(7 downto 0);  -- 8位PCM编码输出
        Rdy:        out std_logic           -- 输出数据就绪信号（高有效）
    );
end PCM_Encode;

architecture Behavioral of PCM_Encode is

-- 内部信号声明
signal State        : integer range 0 to 7;  -- 状态机状态（0-7共8个状态）
signal iNd_dly      : std_logic_vector(1 downto 0);  -- 输入有效信号延迟同步
signal Enc_Out_reg  : std_logic_vector(7 downto 0);  -- 编码输出寄存器
signal Sig_Buf      : std_logic_vector(10 downto 0);  -- 输入信号缓冲
signal Sig_Buf_abs  : integer range 0 to 1023;  -- 输入信号绝对值（11位最大1023）
signal step         : integer range 0 to 64;  -- 量化步长
signal thresh       : integer range 0 to 512;  -- 量化阈值
signal diff         : integer range 0 to 512;  -- 信号绝对值与阈值的差值
signal diff_vec     : std_logic_vector(8 downto 0);  -- 差值的std_logic_vector形式（9位）

begin
    process(clk, aclr)  -- 敏感列表优化：仅保留时钟和复位（组合逻辑在时钟沿内处理）
    begin
        if aclr = '1' then
            -- 异步复位：所有信号置初始值
            State       <= 0;
            iNd_dly     <= (others => '0');
            Enc_Out_reg <= (others => '0');
            Enc_Out     <= (others => '0');
            Rdy         <= '0';
            Sig_Buf     <= (others => '0');
            Sig_Buf_abs <= 0;
            step        <= 0;
            thresh      <= 0;
            diff        <= 0;
            diff_vec    <= (others => '0');
        elsif clk'event and clk = '1' then
            -- 时钟上升沿：处理时序逻辑
            iNd_dly <= iNd_dly(0) & iNd;  -- 延迟同步iNd信号（消抖+同步）
            Rdy <= '0';  -- 默认置输出未就绪
            
            -- 状态机逻辑（移除原错误的State <= 0;）
            case State is
                when 0 =>  -- 空闲状态：等待输入数据有效
                    if iNd_dly = "01" then  -- 检测iNd上升沿（新数据到来）
                        State <= 1;  -- 进入下一状态
                        -- 处理输入信号符号：最高位为1表示负数，取反；0表示正数，直接存储
                        if Sig_In(10) = '0' then
                            Enc_Out_reg(7) <= '0';  -- 符号位：0=正数
                            Sig_Buf <= Sig_In;
                        else
                            Enc_Out_reg(7) <= '1';  -- 符号位：1=负数
                            Sig_Buf <= not(Sig_In);  -- 负数取反（后续+1得到绝对值）
                        end if;
                    end if;

                when 1 =>  -- 计算输入信号绝对值
                    if Sig_In(10) = '0' then
                        Sig_Buf_abs <= conv_integer(Sig_Buf);  -- 正数直接转整数
                    else
                        Sig_Buf_abs <= conv_integer(Sig_Buf) + 1;  -- 负数取反后+1得绝对值
                    end if;
                    State <= 2;  -- 进入量化区间判断状态

                when 2 =>  -- 量化区间判断：确定3位区间码、步长和阈值
                    if ((Sig_Buf_abs >= 0) and (Sig_Buf_abs < 16)) then
                        Enc_Out_reg(6 downto 4) <= "000";  -- 区间码0
                        step <= 1;  -- 量化步长1
                        thresh <= 0;  -- 区间阈值0
                    elsif ((Sig_Buf_abs >= 16) and (Sig_Buf_abs < 32)) then
                        Enc_Out_reg(6 downto 4) <= "001";  -- 区间码1
                        step <= 1;
                        thresh <= 16;
                    elsif ((Sig_Buf_abs >= 32) and (Sig_Buf_abs < 64)) then
                        Enc_Out_reg(6 downto 4) <= "010";  -- 区间码2
                        step <= 2;
                        thresh <= 32;
                    elsif ((Sig_Buf_abs >= 64) and (Sig_Buf_abs < 128)) then
                        Enc_Out_reg(6 downto 4) <= "011";  -- 区间码3
                        step <= 4;
                        thresh <= 64;
                    elsif ((Sig_Buf_abs >= 128) and (Sig_Buf_abs < 256)) then
                        Enc_Out_reg(6 downto 4) <= "100";  -- 区间码4
                        step <= 8;
                        thresh <= 128;
                    elsif ((Sig_Buf_abs >= 256) and (Sig_Buf_abs < 512)) then
                        Enc_Out_reg(6 downto 4) <= "101";  -- 区间码5
                        step <= 16;
                        thresh <= 256;
                    else  -- Sig_Buf_abs >= 512（最大1023）
                        Enc_Out_reg(6 downto 4) <= "110";  -- 区间码6
                        step <= 32;
                        thresh <= 512;
                    end if;
                    State <= 3;  -- 进入差值计算状态

                when 3 =>  -- 计算信号绝对值与阈值的差值
                    diff <= Sig_Buf_abs - thresh;
                    State <= 4;

                when 4 =>  -- 差值转换为std_logic_vector（9位）
                    diff_vec <= conv_std_logic_vector(diff, 9);
                    State <= 5;

                when 5 =>  -- 量化编码：根据步长提取4位量化码
                    if (step = 2) then
                        Enc_Out_reg(3 downto 0) <= diff_vec(4 downto 1);  -- 右移1位（除以2）
                    elsif (step = 4) then
                        Enc_Out_reg(3 downto 0) <= diff_vec(5 downto 2);  -- 右移2位（除以4）
                    elsif (step = 8) then
                        Enc_Out_reg(3 downto 0) <= diff_vec(6 downto 3);  -- 右移3位（除以8）
                    elsif (step = 16) then
                        Enc_Out_reg(3 downto 0) <= diff_vec(7 downto 4);  -- 右移4位（除以16）
                    elsif (step = 32) then
                        Enc_Out_reg(3 downto 0) <= diff_vec(8 downto 5);  -- 右移5位（除以32）
                    else  -- step=1（无需移位）
                        Enc_Out_reg(3 downto 0) <= diff_vec(3 downto 0);
                    end if;
                    State <= 6;

                when 6 =>  -- 输出编码结果并置就绪信号
                    Enc_Out <= Enc_Out_reg;  -- 8位编码输出（符号位+3位区间码+4位量化码）
                    Rdy <= '1';  -- 置输出就绪
                    State <= 0;  -- 回到空闲状态

                when others =>  -- 其他状态：复位到空闲状态
                    State <= 0;
            end case;
        end if;
    end process;
end Behavioral; 
  
  
  
  
  
  
  
  
  
  
  
