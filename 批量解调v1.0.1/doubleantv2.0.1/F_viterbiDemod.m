function VA_dec = F_viterbiDemod(sig, delayEst, dopplerEst)
% ----
% �˺���ʹ��viterbi�㷨���, ������ͬ��λ
% ����:
%	sig:�����GMSK�ź�
%	delayEst:�ź�ʱ�ӹ���
%	dopplerEst:�ź�Ƶƫ����
% ���:
%	VA_dec:VA�㷨��������
% ----
	global os Rb state_all state_in state_number decision_delay ...
		Kf L qt DecodLenth
	t = (delayEst+(0:DecodLenth*os-1))/os/Rb;     % ����ʱ�ӵ��ź�ʱ��
	CarrierOffset_est = exp(1j*2*pi*dopplerEst*t); % Ƶƫ�ָ��ز�
	sig_ch_est = F_cutSig(sig, delayEst, DecodLenth*os);
	sig_ch_eq = sig_ch_est ./ CarrierOffset_est;
	VA_dec = VA2_CorrDecay_mex(sig_ch_eq,...
		DecodLenth,os,Kf,L,qt,decision_delay, state_all.', state_in.', state_number,0.9);             % VA����
	
end