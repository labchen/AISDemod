function [dec_end, endFlag] = F_findEndFlag(seqIn, dec_start)
% ----
% 此函数查找输入序列中的结束标志位置
% 输入:
%	seqIn:二进制序列
%	dec_start:数据开始位置
% 输出:
%	dec_end:信号的结束标志位置
%	endFlag:是否找到结束标志
% ----
	global DataLength EndFlag
	
	endFlag = 1;
	dec_end = dec_start+DataLength-1;
	for ii=dec_start+DataLength : 1 : dec_start+DataLength+10
		% 从开始位向后184位到194位之间查找结束标志
		if ii+6<=length(seqIn)
			% 结束标志应在VA解调结果信息中
			if sum(seqIn(ii:ii+6) == EndFlag(1:7)) == 7
				% 找到结束标志
				dec_end = ii-1;
				if dec_end > dec_start+DataLength+4-1
					% 结束标志部分超出搜索范围, 即未找到结束标志
					dec_end = dec_start+DataLength-1;
					endFlag = 0;
				end
				break;
			end
		end
	end
end