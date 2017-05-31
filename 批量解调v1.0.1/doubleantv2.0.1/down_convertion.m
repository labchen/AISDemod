function [sig_bb] = down_convertion(sig,Fs,fc,os)
%下变频函数：
%本函数主要用于将接收信号下变频到基带（去载波）
%输入参数：sig --接收信号 Fs--频带采样率 fc--接收信号载频
%输出参数：sig_bb --基带信号

if ~exist('os','var')|| isempty(os)
  os = 4;                       %基带采样倍数
end
Rb = 9600;                    %比特率
sig= resample(sig, Rb*os, Fs);
Fs = Rb*os;                   %基带采样率
% Fl = 12.5*10^3;
%载波
l = length(sig);            
t = (0:l-1).'/Fs;
carrier_I = cos(2*pi*fc*t);
carrier_Q = sin(2*pi*fc*t);

%低通滤波
N = 96;                
Freq = [0,fc-1000,fc+1000,Fs/2]*2/Fs;
% Freq = [0,Fl-100,Fl+100,Fs/2]*2/Fs;
Amp = [1,1,0,0];
lpf = firls(N,Freq,Amp);

%将接收信号（频带信号）转到基带
BB_I = 2*conv(real(sig).*carrier_I, lpf);
BB_I = BB_I(N/2+1:N/2+l);
BB_Q = 2*conv(real(sig).*carrier_Q, lpf);
BB_Q = -BB_Q(N/2+1:N/2+l);
%输出基带信号
sig_bb = BB_I+1j*BB_Q;

end
