function [sig_bb] = down_convertion(sig,Fs,fc,os)
%�±�Ƶ������
%��������Ҫ���ڽ������ź��±�Ƶ��������ȥ�ز���
%���������sig --�����ź� Fs--Ƶ�������� fc--�����ź���Ƶ
%���������sig_bb --�����ź�

if ~exist('os','var')|| isempty(os)
  os = 4;                       %������������
end
Rb = 9600;                    %������
sig= resample(sig, Rb*os, Fs);
Fs = Rb*os;                   %����������
% Fl = 12.5*10^3;
%�ز�
l = length(sig);            
t = (0:l-1).'/Fs;
carrier_I = cos(2*pi*fc*t);
carrier_Q = sin(2*pi*fc*t);

%��ͨ�˲�
N = 96;                
Freq = [0,fc-1000,fc+1000,Fs/2]*2/Fs;
% Freq = [0,Fl-100,Fl+100,Fs/2]*2/Fs;
Amp = [1,1,0,0];
lpf = firls(N,Freq,Amp);

%�������źţ�Ƶ���źţ�ת������
BB_I = 2*conv(real(sig).*carrier_I, lpf);
BB_I = BB_I(N/2+1:N/2+l);
BB_Q = 2*conv(real(sig).*carrier_Q, lpf);
BB_Q = -BB_Q(N/2+1:N/2+l);
%��������ź�
sig_bb = BB_I+1j*BB_Q;

end
