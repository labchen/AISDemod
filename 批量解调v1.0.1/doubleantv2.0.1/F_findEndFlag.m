function [dec_end, endFlag] = F_findEndFlag(seqIn, dec_start)
% ----
% �˺����������������еĽ�����־λ��
% ����:
%	seqIn:����������
%	dec_start:���ݿ�ʼλ��
% ���:
%	dec_end:�źŵĽ�����־λ��
%	endFlag:�Ƿ��ҵ�������־
% ----
	global DataLength EndFlag
	
	endFlag = 1;
	dec_end = dec_start+DataLength-1;
	for ii=dec_start+DataLength : 1 : dec_start+DataLength+10
		% �ӿ�ʼλ���184λ��194λ֮����ҽ�����־
		if ii+6<=length(seqIn)
			% ������־Ӧ��VA��������Ϣ��
			if sum(seqIn(ii:ii+6) == EndFlag(1:7)) == 7
				% �ҵ�������־
				dec_end = ii-1;
				if dec_end > dec_start+DataLength+4-1
					% ������־���ֳ���������Χ, ��δ�ҵ�������־
					dec_end = dec_start+DataLength-1;
					endFlag = 0;
				end
				break;
			end
		end
	end
end