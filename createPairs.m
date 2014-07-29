function [idxa, idxb] = createPairs(sampleData, SampleCountEachPerson)
%idxa: ����sampleData��ǰһ��������ͼƬ�Եĵ�һ��ͼƬ�� ��һ���ǲ�����ͼƬ�Եĵ�һ��ͼƬ
%idxb: ����sampleData��ǰһ��������ͼƬ�Եĵڶ���ͼƬ�� ��һ���ǲ�����ͼƬ�Եĵڶ���ͼƬ

idxa = repmat(1:size(sampleData,2), 1, 2);

%��������ͼƬ�Եĵڶ���ͼƬ������
idxb1 = zeros(1, size(idxa,2)/2);
t=0;
for i=1:length(SampleCountEachPerson)
    NumOfPerson = SampleCountEachPerson(i);
    
    idxb1(t+1: t+NumOfPerson) = randperm(NumOfPerson)+t;
    while(sum(idxb1(t+1: t+NumOfPerson) == idxa(t+1: t+NumOfPerson)) ~= 0)
        idxb1(t+1: t+NumOfPerson) = randperm(NumOfPerson)+t;
    end
    t = t+NumOfPerson;
end

%����������ͼƬ�Եĵڶ���ͼƬ������
idxb2 = zeros(1, size(idxa,2)/2);
t=0;
SumOfSample = sum(SampleCountEachPerson);
for i=1:length(SampleCountEachPerson)
    NumOfPerson = SampleCountEachPerson(i);
    if(i==1)
        temp = NumOfPerson+1:SumOfSample;
    elseif(i==length(SampleCountEachPerson))
        temp = 1:SumOfSample-NumOfPerson;
    else
        p = sum(SampleCountEachPerson(1:i-1));
        temp = [1:p p+NumOfPerson+1:SumOfSample ];
    end
    temp = temp( randperm(length(temp)) );
    if(length(temp) < NumOfPerson)
        temp = repmat(temp, 1, NumOfPerson/length(temp)+1)
    end

    idxb2(t+1: t+NumOfPerson) = temp(1:NumOfPerson);
    t = t+NumOfPerson;
end

idxb = [idxb1 idxb2];

end