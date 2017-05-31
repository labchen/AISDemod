function sig = F_aisModul(data, buffer, delay, doppler, h)
% ----
% �˺����Զ�������Ϣ����AIS����, ��NRZI���롢GMSK���Ʋ������ź�Ƶƫ�ͷ�ֵ
% ����:
%	data:��������Ϣ����
%	delay:�ź�ʱ��
%	doppler:�ź�Ƶƫ
%	h:�ŵ���Ӧ��ֵ
%	buffer:����������
% ���:
%	sig:AIS�ź�
% ----
	if ~exist('delay', 'var')
		delay = 0;
	end
	if ~exist('doppler', 'var')
		doppler = 0;
	end
	if ~exist('h', 'var')
		h = 1;
	end
	global symbols next_out_diff next_state_diff m_diff terminate_diff ...
		RisingLength os Rb BT L Kf truncate
	% NRZI����
	data_r = 1 - data;
	% differential encoder
	data_diff_r = encode_trellis(data_r, next_out_diff, next_state_diff, ...
		m_diff, terminate_diff);
	% NRZI
	sym_nrzi_r = symbols(data_diff_r + 1);
	% GMSK����
	sig_gmsk_r = F_gmskMod(sym_nrzi_r, os, Rb, BT, L, Kf, truncate);
	sig_gmsk_ext_r = [zeros(1,RisingLength*os), sig_gmsk_r, zeros(1,buffer*os)];	% �����ź�������
	% ����Ƶƫ
	t = (delay + (0:length(sig_gmsk_ext_r)-1))/os/Rb;
	CarrierOffset_est_SIC = exp(1j*2*pi*doppler*t);
	PhaseShift_est = 1; % H_est adjusted
	sig = PhaseShift_est*h.*CarrierOffset_est_SIC.*sig_gmsk_ext_r;
end