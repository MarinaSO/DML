clc;
clear;
run('toolbox/init.m');
figure

%% Set up database
DataBase = 'ethz.mat'
load(DataBase);

%% Set up Metric Learning parameters
paramsM.numCoeffs = size(FeatureSetC,1); %dimensionality of
paramsM.numFolds = 10; %number of random train/test splits
paramsM.initPersonToLearn = 4 ;

PCADim = 40;
InitialGNGTrainTime = 100;
lambda = 100;
c = 0.5;
agemax = 30;

%% Load Features
data = FeatureSetC(1:paramsM.numCoeffs,:);
SCEP = SampleCountEachPerson;

%% PCA��ά
options=[];
options.ReducedDim=PCADim;
[eigvector,eigvalue] = PCA(data',options);
data = (data'*eigvector)';
paramsM.numCoeffs = PCADim;

%% Initial temp var
RMSE = [];
NumOfEpochs = 500;
Epoch = [];
Cur_NumOfNodes = [];
Cur_AUC = zeros(1,NumOfEpochs);
AUC = [];

%% �㷨ѡ��
pair_metric_learn_algs = {...
    LearnAlgoKISSME(), ...
%             LearnAlgoMahal(), ...
%         LearnAlgoMLEuclidean() ...
%          LearnAlgoITML(), ...
%         LearnAlgoLDML(), ...
% %             LearnAlgoLMNN() ...
% %               LearnAlgoSVM()
    };

%% �����ʼѵ����
InitialLabeledSapleCount = SCEP(1:paramsM.initPersonToLearn);
sampleToLearn = sum( InitialLabeledSapleCount);
InitialLabeledData = data(:,1:sampleToLearn);

[idxa, idxb] = createPairs(InitialLabeledData, InitialLabeledSapleCount);

dataForMerticTrain.data = InitialLabeledData;
dataForMerticTrain.idxa = idxa;
dataForMerticTrain.idxb = idxb;

%% ������Լ�
TestSamplePerPerson = 2;
NumOfPerson =  size(SCEP,2);
sampleToTest = TestSamplePerPerson*NumOfPerson;
dataForMetricTest.data = zeros(PCADim, sampleToTest)
testSampleCount = ones(1, NumOfPerson)*TestSamplePerPerson;
p =0;
count = 0;
for i=1:NumOfPerson
    if(SCEP(i) >= TestSamplePerPerson)
        idx = (randperm(SCEP(i))+p);
        dataForMetricTest.data(:,(i-1)*TestSamplePerPerson+1 : i*TestSamplePerPerson) = data(:,idx(1:TestSamplePerPerson));
        count = count+1;
    end
    p = p+SCEP(i);
end
testSampleCount = testSampleCount(1:count);
dataForMetricTest.data = dataForMetricTest.data(:, 1:count*TestSamplePerPerson);
[idxa, idxb] = createTestPairs(dataForMetricTest.data, testSampleCount );
dataForMetricTest.idxa = idxa;
dataForMetricTest.idxb = idxb;

%% ѵ���õ���ʼ��metric matrix
[ ds ] = CrossValidateViperNew(struct(), pair_metric_learn_algs, dataForMerticTrain, dataForMetricTest, paramsM);

names = fieldnames(ds(1));
Metric = ds(1).(names{1}).M;
plotcmc(ds,sampleToTest);
      t_cmc = median(ds(1).(names{1}).cmc,1);
       t_AUC = sum(t_cmc)/sampleToTest
drawnow;
 
 
%% ��ʼѵ��SOINN,���ʹ���ظ�����ʹ��ѵ���õ��ȶ�״̬
% Step.0 Start with two neural units (nodes) selected from input data:
nodes=[data(:,1) data(:,2)];

%Initial M
M = [1,1];

%Initial T1 T2
tem = (data(:,1)-data(:,2))'*Metric*(data(:,1)-data(:,2));
threshold=[tem,tem];

% Initial connections (edges) matrix.
connection=[0,0;0,0];

% Initial ages matrix.
age=[0,0;0,0];

% In = InitialLabeledData;
for time = 1:InitialGNGTrainTime
    fprintf('SOINN init run %d of %d\n', time, InitialGNGTrainTime);
    D = InitialLabeledData;
    for i=3:size(D,2)
        [value index dis] = findTwoNearest(D(:,i), nodes, Metric);
        %prototype, connection and age update
        if value(1)>threshold(index(1))||value(2)>threshold(index(2))
            nodes=[nodes D(:,i)];
            threshold=[threshold,1000000];
            M=[M,1];
            s=size(nodes,2);
            connection(:,s)=0;
            connection(s,:)=0;
            age(:,s)=0;
            age(s,:)=0;
        else
            if connection(index(1),index(2))==0
                connection(index(1),index(2))=1;
                connection(index(2),index(1))=1;
                age(index(1),index(2))=1;
                age(index(2),index(1))=1;
            else
                age(index(1),index(2))=1;
                age(index(2),index(1))=1;
            end
            [row,col]=find(connection(index(1),:)~=0);
            age(index(1),col)=age(index(1),col)+1;
            age(col,index(1))=age(col,index(1))+1;
            locate=find(age(index(1),:)>agemax);
            connection(index(1),locate)=0;
            connection(locate,index(1))=0;
            age(index(1),locate)=0;
            age(locate,index(1))=0;
            M(index(1))=M(index(1))+1;
            nodes(:,index(1))=nodes(:,index(1))+(1/M(index(1)))*(D(:,i)-nodes(:,index(1)));
        end
        
        % threshold update
        if nnz(connection(index(1),:))==0
            t_ = (nodes(:,index(1))-nodes(:,index(2)));
            threshold(index(1))=t_'*Metric*t_;
        else
            v=find(connection(index(1),:)~=0);
            t_ = repmat(nodes(:,index(1)),1,size(v,2))-nodes(:,v);
            distance=  t_'*Metric*t_;
            threshold(index(1))=max(sqrt(sum(distance.^2')));
        end
        
        if nnz(connection(index(2),:))==0
            t_ = nodes(:,index(1))-nodes(:,index(2));
            threshold(index(2)) = t_'*Metric*t_;
        else
            v=find(connection(index(2),:)~=0);
            t_ = repmat(nodes(:,index(2)),1,size(v,2))-nodes(:,v);
            distance=  t_'*Metric*t_;
            threshold(index(2))=max(sqrt(sum(distance.^2')));
        end
        
        % denosing
        if mod(i,lambda)==0
            meanM=sum(M)/size(M,2);
            neighbor=sum(connection);
            setu=union(intersect(find(M<c*meanM),find(neighbor==1)),intersect(find(M<meanM),find(neighbor==0)));
            nodes(:,setu)=[];
            threshold(setu)=[];
            M(setu)=[];
            connection(setu,:)=[];
            connection(:,setu)=[];
            age(setu,:)=[];
            age(:,setu)=[];
        end
    end
end

kk=1;
%% ��ʼ����

D = data;
% for iii=1:50
for i=sampleToLearn:size(D,2)
     fprintf('learning %dth data, nodes:%d\n', i, size(nodes,2));
    [value index dis] = findTwoNearest(D(:,i), nodes, Metric);
    %prototype, connection and age update
    if value(1)>threshold(index(1))||value(2)>threshold(index(2))
        nodes=[nodes D(:,i)];
        threshold=[threshold,1000000];
        M=[M,1];
        s=size(nodes,2);
        connection(:,s)=0;
        connection(s,:)=0;
        age(:,s)=0;
        age(s,:)=0;
    else
        if connection(index(1),index(2))==0
            connection(index(1),index(2))=1;
            connection(index(2),index(1))=1;
            age(index(1),index(2))=1;
            age(index(2),index(1))=1;
        else
            age(index(1),index(2))=1;
            age(index(2),index(1))=1;
        end
        [row,col]=find(connection(index(1),:)~=0);
        age(index(1),col)=age(index(1),col)+1;
        age(col,index(1))=age(col,index(1))+1;
        locate=find(age(index(1),:)>agemax);
        connection(index(1),locate)=0;
        connection(locate,index(1))=0;
        age(index(1),locate)=0;
        age(locate,index(1))=0;
        M(index(1))=M(index(1))+1;
        nodes(:,index(1))=nodes(:,index(1))+(1/M(index(1)))*(D(:,i)-nodes(:,index(1)));
    end
    
    % threshold update
    if nnz(connection(index(1),:))==0
        t_ = (nodes(:,index(1))-nodes(:,index(2)));
        threshold(index(1))=t_'*Metric*t_;
    else
        v=find(connection(index(1),:)~=0);
        t_ = repmat(nodes(:,index(1)),1,size(v,2))-nodes(:,v);
        distance=  t_'*Metric*t_;
        threshold(index(1))=max(sqrt(sum(distance.^2')));
    end
    
    if nnz(connection(index(2),:))==0
        t_ = nodes(:,index(1))-nodes(:,index(2));
        threshold(index(2)) = t_'*Metric*t_;
    else
        v=find(connection(index(2),:)~=0);
        t_ = repmat(nodes(:,index(2)),1,size(v,2))-nodes(:,v);
        distance=  t_'*Metric*t_;
        threshold(index(2))=max(sqrt(sum(distance.^2')));
    end
    
    % denosing
    if mod(i,lambda)==0
        meanM=sum(M)/size(M,2);
        neighbor=sum(connection);
        setu=union(intersect(find(M<c*meanM),find(neighbor==1)),intersect(find(M<meanM),find(neighbor==0)));
        nodes(:,setu)=[];
        threshold(setu)=[];
        M(setu)=[];
        connection(setu,:)=[];
        connection(:,setu)=[];
        age(setu,:)=[];
        age(:,setu)=[];
        
        %����Metric
        NumOfNearest = 5; %ÿ��������ȡ�������������������
        dataForMerticTrain.data = zeros(size(nodes,1), size(nodes,2)*NumOfNearest + size(InitialLabeledData,2));
        dataForMerticTrain.idxa = zeros(1, size(nodes,2));
        dataForMerticTrain.idxb = zeros(1, size(nodes,2));
        sampleCount = zeros(1,size(nodes, 2));
        for ii=1:size(nodes,2)
%             if(circle == 1)
                points = findNearestPoint(data(:, 1:i), nodes(:,ii), NumOfNearest, Metric);
%             else
%                 points = findNearestPoint(data, nodes(:,ii), NumOfNearest, Metric);
%             end
            dataForMerticTrain.data(:, NumOfNearest*(ii-1)+ 1:NumOfNearest*ii ) = points;
            sampleCount(ii) = NumOfNearest;
        end
        
        %���ϳ�ʼѵ��������
        dataForMerticTrain.data(:,size(nodes,2)*NumOfNearest+1:end) = InitialLabeledData;
        sampleCount = [sampleCount InitialLabeledSapleCount];
        yy = dataForMerticTrain.data;
        
        %����ѵ����
        [idxa, idxb] = createPairs(dataForMerticTrain.data, sampleCount);
        dataForMerticTrain.idxa = idxa;
        dataForMerticTrain.idxb = idxb;
        
        [ ds ] = CrossValidateViperNew(struct(), pair_metric_learn_algs, dataForMerticTrain, dataForMetricTest, paramsM);
        
        names = fieldnames(ds(1));
        Metric = ds(1).(names{1}).M;
        
        %%��ͼ
        plotcmc(ds,sampleToTest);
        drawnow;
        
        subplot(1,2,2);
        names = fieldnames(ds);
        for nameCounter=1:length(names)
            s = [ds.(names{nameCounter})];
            ms.(names{nameCounter}).cmc = cat(1,s.cmc)./sampleToTest;
            ms.(names{nameCounter}).roccolor = s(1).roccolor;
        end
        
        t_cmc = median(ms.(names{nameCounter}).cmc,1);
        
        Cur_AUC(kk) = sum(t_cmc)/sampleToTest;
        AUC = [AUC Cur_AUC(kk)];
        if length(AUC)>500
            AUC = AUC(end-500:end);
        end
        Epoch = [Epoch kk];
        if length(Epoch)>500
            Epoch = Epoch(end-500:end);
        end
        
        plot(Epoch,AUC,'b.');
        
        title('AUC');
        if kk>500
            xlim([Epoch(1) Epoch(end)]);
        end
        xlabel('Training Epoch Number');
        grid on;
        kk = kk+1;
    end
end
% end


