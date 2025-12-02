%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A律非均匀PCM编译码程序
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;

fs=32000;
LEN_SIG=1024;
t=1/fs*(0:LEN_SIG-1);

SCALE_SHIFT=10;
SCALE_PCM=2^SCALE_SHIFT-1;

LEN_VIEW=256;
View_X=[1:LEN_VIEW];

%---------------------------------------------------
%   Source Data
%---------------------------------------------------
SrcSignal=round(SCALE_PCM*sin(2*pi*800*t));  %  800Hz;
figure(1);
subplot(2,1,1);plot(View_X,SrcSignal(View_X));
axis([0 LEN_VIEW-1 -SCALE_PCM SCALE_PCM]);
title('输入信号波形');

%---------------------------------------------------
%   A律非均匀PCM编码
%---------------------------------------------------
for i = 1 : LEN_SIG
    if SrcSignal(i) >= 0
        out(i,1) = 0 ;
    else 
        out(i,1) = 1 ;
    end
        
    if abs(SrcSignal(i)) >= 0 & abs(SrcSignal(i)) < 16
        out(i,2) = 0;
        out(i,3) = 0;
        out(i,4) = 0;
        step = 1;
        st = 0;
    elseif 16 <= abs(SrcSignal(i)) & abs(SrcSignal(i)) < 32 
        out(i,2) = 0;
        out(i,3) = 0;
        out(i,4) = 1;
        step = 1;
        st = 16;
    elseif 32 <= abs(SrcSignal(i)) & abs(SrcSignal(i)) < 64 
        out(i,2) = 0;
        out(i,3) = 1;
        out(i,4) = 0;
        step = 2;
        st = 32;
    elseif 64 <= abs(SrcSignal(i)) & abs(SrcSignal(i)) < 128 
        out(i,2) = 0;
        out(i,3) = 1;
        out(i,4) = 1;
        step = 4;
        st = 64;
    elseif 128 <= abs(SrcSignal(i)) & abs(SrcSignal(i)) < 256 
        out(i,2) = 1;
        out(i,3) = 0;
        out(i,4) = 0;
        step = 8;
        st = 128;
    elseif 256 <= abs(SrcSignal(i)) & abs(SrcSignal(i)) < 512
        out(i,2) = 1;
        out(i,3) = 0;
        out(i,4) = 1;
        step = 16;
        st = 256;
    elseif 512 <= abs(SrcSignal(i)) & abs(SrcSignal(i)) < 1024
        out(i,2) = 1;
        out(i,3) = 1;
        out(i,4) = 0;
        step = 32;
        st = 512;
    elseif 1024 <= abs(SrcSignal(i)) & abs(SrcSignal(i)) < 2048
        out(i,2) = 1;
        out(i,3) = 1;
        out(i,4) = 1;
        step = 64;
        st = 1024;
    else
        out(i,2) = 1;
        out(i,3) = 1;
        out(i,4) = 1;
        step = 64;
        st = 1024;
    end

    if abs(SrcSignal(i)) > 2048
        out(i,2:8) = [1 1 1 1 1 1 1];
    else
        tmp = floor((abs(SrcSignal(i)) - st)/step);
        t = dec2bin(tmp,4) - 48;
        out(i,5:8) = t(1:4)
    end
end
EncOut = reshape(out',1,8*LEN_SIG);

% 打印编码数据
% fid_enc = fopen('PCM_enc.txt','W');
% 
% for j = 1 : LEN_SIG
%     x = out(j,1)*128 + out(j,2)*64 + out(j,3)*32 + out(j,4)*16 + out(j,5)*8 + out(j,6)*4 + out(j,7)*2 + out(j,8);
%     fprintf(fid_enc,"%d\n",x);
% end
% 
% fclose(fid_enc);

%---------------------------------------------------
%   A律非均匀PCM译码
%---------------------------------------------------
in = reshape(EncOut',8,LEN_SIG)';
slot(1) = 0;
slot(2) = 16;
slot(3) = 32;
slot(4) = 64;
slot(5) = 128;
slot(6) = 256;
slot(7) = 512;
slot(8) = 1024;

step(1) = 1;
step(2) = 1;
step(3) = 2;
step(4) = 4;
step(5) = 8;
step(6) = 16;
step(7) = 32;
step(8) = 64;

for i = 1 : LEN_SIG
    if in(i,1) == 0
        ss = 1;
    else
        ss = -1;
    end

    tmp = in(i,2) * 4 + in(i,3) * 2 + in(i,4) + 1;
    st = slot(tmp);
    dt = (in(i,5) * 8 + in(i,6) * 4 + in(i,7) * 2 + in(i,8)) * step(tmp);
    DecOut(i) = ss * (st + dt);
end

% 打印解码数据
% fid_dec = fopen('PCM_dec.txt','W');
% for j = 1 : LEN_SIG
%     fprintf(fid_dec,"%d\n",DecOut(j));
% end
% fclose(fid_dec);

subplot(2,1,2);plot(View_X,DecOut(View_X));
axis([0 LEN_VIEW-1 -SCALE_PCM SCALE_PCM]);
title('译码信号波形')

%---------------------------------------------------
%           CCS_DSP Export 
%---------------------------------------------------

fid1 = fopen('PCM_SigIn.txt','W');
fprintf(fid1,'PCM_SigIn[%d] = { \r',LEN_VIEW);

for j = 1 : LEN_VIEW
    x = floor(SrcSignal(j));
    if(x >= 32767.0)
        x = 32767 ;
    elseif(x < -32768.0)
        x = - 32768 ;
    end

    fprintf(fid1,"%6d,",x);
    if((mod(j,8) == 0) && (j > 1))
        fprintf(fid1,'\r');
    end
end

fclose(fid1);
